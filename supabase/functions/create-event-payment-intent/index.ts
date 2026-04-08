  import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
  import Stripe from "npm:stripe@16.5.0";
  import { createClient } from "npm:@supabase/supabase-js@2.45.4";

  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };

  const SERVICE_FEE_RATE = 0.05;

  serve(async (req) => {
    if (req.method === "OPTIONS") {
      return new Response("ok", { headers: corsHeaders });
    }

    try {
      const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
      const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
      const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
      const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY") ?? "";
      const currency = (Deno.env.get("STRIPE_PAYMENT_CURRENCY") ?? "usd").toLowerCase();

      if (!supabaseUrl || !supabaseAnonKey || !serviceRoleKey || !stripeSecretKey) {
        return new Response(JSON.stringify({ error: "Missing server configuration." }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const stripe = new Stripe(stripeSecretKey, { apiVersion: "2024-04-10" });
      const userClient = createClient(supabaseUrl, supabaseAnonKey, {
        global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
      });
      const adminClient = createClient(supabaseUrl, serviceRoleKey);

      const { data: authData, error: authError } = await userClient.auth.getUser();
      if (authError || !authData.user) {
        return new Response(JSON.stringify({ error: "Unauthorized." }), {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const body = await req.json();
      const orderId = String(body?.order_id ?? "");
      if (!orderId) {
        return new Response(JSON.stringify({ error: "order_id is required." }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const userId = authData.user.id;
      const { data: order, error: orderError } = await adminClient
        .from("orders")
        .select("id, user_id, event_id, status, stripe_payment_intent_id, stripe_customer_id")
        .eq("id", orderId)
        .maybeSingle();

      if (orderError || !order || order.user_id !== userId) {
        return new Response(JSON.stringify({ error: "Order not found." }), {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      if (order.status === "completed") {
        return new Response(JSON.stringify({ error: "Order already completed." }), {
          status: 409,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const { data: tickets, error: ticketError } = await adminClient
        .from("tickets")
        .select("quantity, event_ticket_id, event_tickets!inner(price)")
        .eq("order_id", orderId);

      if (ticketError || !tickets || tickets.length === 0) {
        return new Response(JSON.stringify({ error: "Order has no tickets." }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      let subtotal = 0;
      for (const t of tickets) {
        const quantity = Number((t as any).quantity ?? 1);
        const price = Number((t as any).event_tickets?.price ?? 0);
        subtotal += price * quantity;
      }
      const serviceFee = subtotal * SERVICE_FEE_RATE;
      const total = subtotal + serviceFee;
      const amount = Math.max(0, Math.round(total * 100));

      let customerId = order.stripe_customer_id as string | null;
      if (!customerId) {
        const customer = await stripe.customers.create({
          metadata: { supabase_user_id: userId },
        });
        customerId = customer.id;
      }

      let paymentIntentId = order.stripe_payment_intent_id as string | null;
      let clientSecret: string | null = null;

      if (paymentIntentId) {
        const existingIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
        clientSecret = existingIntent.client_secret;
        if (existingIntent.status === "canceled") {
          paymentIntentId = null;
        }
      }

      if (!paymentIntentId || !clientSecret) {
        const intent = await stripe.paymentIntents.create(
          {
            amount,
            currency,
            customer: customerId,
            automatic_payment_methods: { enabled: true },
            metadata: {
              order_id: orderId,
              user_id: userId,
              event_id: String(order.event_id ?? ""),
            },
          },
          { idempotencyKey: `event_order_${orderId}` },
        );
        paymentIntentId = intent.id;
        clientSecret = intent.client_secret;
      }

      const ephemeralKey = await stripe.ephemeralKeys.create(
        { customer: customerId },
        { apiVersion: "2024-04-10" },
      );

      await adminClient
        .from("orders")
        .update({
          subtotal_amount: subtotal,
          service_fee_amount: serviceFee,
          total_amount: total,
          stripe_customer_id: customerId,
          stripe_payment_intent_id: paymentIntentId,
          payment_provider: "stripe",
          updated_at: new Date().toISOString(),
        })
        .eq("id", orderId);

      return new Response(
        JSON.stringify({
          clientSecret,
          paymentIntentId,
          customerId,
          customerEphemeralKeySecret: ephemeralKey.secret,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    } catch (error) {
      return new Response(JSON.stringify({ error: (error as Error).message }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
  });
