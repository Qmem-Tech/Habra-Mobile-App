/**
 * Creates (or retrieves) a Stripe PaymentIntent for an event ticket order.
 *
 * Payout math (destination charge):
 *   Customer pays:          face value (no visible service fee)
 *   application_fee_amount: 13.5 % of subtotal  (covers Stripe's ~2.9 %+$0.30 + Habra's exact 10 %)
 *   → Habra nets:           ~10 % of subtotal
 *   → Business owner gets:  ~86.5 % of subtotal  (after Stripe fee & Habra fee)
 *
 * Example on $50 ticket:
 *   amount              = 5000 ¢  ($50.00 – face value)
 *   application_fee     =  675 ¢  ($6.75  – Habra keeps $5, Stripe takes $1.75)
 *   transfer_to_owner   = 4325 ¢  ($43.25)
 *
 * If the business owner has NOT completed Stripe Connect onboarding the charge
 * still succeeds but ALL funds stay with Habra (no destination transfer).
 * This allows testing before onboarding is complete.
 */
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import Stripe from "npm:stripe@16.5.0";
import { createClient } from "npm:@supabase/supabase-js@2.45.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Habra's gross take-rate.
// Stripe fee (~2.9 %+$0.30) is absorbed inside this rate so Habra still nets exactly 10 %.
// 13.5 % keeps Habra net at 10 % on the average $50 ticket; adjust if your average differs.
const PLATFORM_RATE = 0.135; // 13.5 %

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
      return json({ error: "Missing server configuration." }, 500);
    }

    const stripe = new Stripe(stripeSecretKey, { apiVersion: "2024-04-10" });
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
    });
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const { data: authData, error: authError } = await userClient.auth.getUser();
    if (authError || !authData.user) {
      return json({ error: "Unauthorized." }, 401);
    }

    const body = await req.json();
    const orderId = String(body?.order_id ?? "");
    if (!orderId) {
      return json({ error: "order_id is required." }, 400);
    }

    const userId = authData.user.id;

    // ── Load order ────────────────────────────────────────────────────────────
    const { data: order, error: orderError } = await adminClient
      .from("orders")
      .select("id, user_id, event_id, status, stripe_payment_intent_id, stripe_customer_id")
      .eq("id", orderId)
      .maybeSingle();

    if (orderError || !order || order.user_id !== userId) {
      return json({ error: "Order not found." }, 404);
    }
    if (order.status === "completed") {
      return json({ error: "Order already completed." }, 409);
    }

    // ── Load tickets & compute subtotal ───────────────────────────────────────
    const { data: tickets, error: ticketError } = await adminClient
      .from("tickets")
      .select("quantity, event_ticket_id, event_tickets!inner(price)")
      .eq("order_id", orderId);

    if (ticketError || !tickets || tickets.length === 0) {
      return json({ error: "Order has no tickets." }, 400);
    }

    let subtotal = 0;
    for (const t of tickets) {
      const quantity = Number((t as any).quantity ?? 1);
      const price = Number((t as any).event_tickets?.price ?? 0);
      subtotal += price * quantity;
    }

    // Customer pays face value only — no visible service fee.
    const total = subtotal;
    const totalCents = Math.max(50, Math.round(total * 100)); // Stripe minimum 50¢

    // Habra's application fee covers both its 10 % and Stripe's processing cost.
    const applicationFeeCents = Math.round(subtotal * PLATFORM_RATE * 100);
    // Net Habra keeps: applicationFee − Stripe fee ≈ subtotal × 10 %
    const platformFeeDollars = (applicationFeeCents / 100) * (1 / PLATFORM_RATE) * 0.10;

    // ── Look up the event's business owner Stripe account ─────────────────────
    const { data: event } = await adminClient
      .from("events")
      .select("id, business_id")
      .eq("id", String(order.event_id ?? ""))
      .maybeSingle();

    let connectedAccountId: string | null = null;
    if (event?.business_id) {
      const { data: biz } = await adminClient
        .from("businesses")
        .select("stripe_account_id, stripe_connect_status")
        .eq("id", event.business_id)
        .maybeSingle();

      if (biz?.stripe_connect_status === "complete" && biz?.stripe_account_id) {
        connectedAccountId = biz.stripe_account_id as string;
      } else {
        console.log(
          `[create-event-payment-intent] Business ${event.business_id} has no complete connect account. ` +
          `Funds will stay with Habra until onboarding is complete.`,
        );
      }
    }

    // ── Stripe customer ───────────────────────────────────────────────────────
    let customerId = order.stripe_customer_id as string | null;
    if (!customerId) {
      const customer = await stripe.customers.create({
        metadata: { supabase_user_id: userId },
      });
      customerId = customer.id;
    }

    // ── PaymentIntent (create or retrieve) ────────────────────────────────────
    let paymentIntentId = order.stripe_payment_intent_id as string | null;
    let clientSecret: string | null = null;

    if (paymentIntentId) {
      const existingIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
      if (existingIntent.status === "canceled") {
        paymentIntentId = null;
        clientSecret = null;
      } else {
        clientSecret = existingIntent.client_secret;
      }
    }

    if (!paymentIntentId || !clientSecret) {
      // Build the intent params — add destination split only when the connected account is ready.
      const intentParams: Stripe.PaymentIntentCreateParams = {
        amount: totalCents,
        currency,
        customer: customerId,
        automatic_payment_methods: { enabled: true },
        metadata: {
          order_id: orderId,
          user_id: userId,
          event_id: String(order.event_id ?? ""),
          platform_rate: String(PLATFORM_RATE),
          application_fee_cents: String(applicationFeeCents),
          connected_account: connectedAccountId ?? "none",
        },
      };

      if (connectedAccountId) {
        intentParams.application_fee_amount = applicationFeeCents;
        intentParams.transfer_data = { destination: connectedAccountId };
      }

      const intent = await stripe.paymentIntents.create(intentParams, {
        idempotencyKey: `event_order_${orderId}`,
      });
      paymentIntentId = intent.id;
      clientSecret = intent.client_secret;
    }

    const ephemeralKey = await stripe.ephemeralKeys.create(
      { customer: customerId },
      { apiVersion: "2024-04-10" },
    );

    // ── Persist order totals ──────────────────────────────────────────────────
    await adminClient
      .from("orders")
      .update({
        subtotal_amount: subtotal,
        service_fee_amount: 0,               // no visible fee shown to customer
        total_amount: total,
        stripe_customer_id: customerId,
        stripe_payment_intent_id: paymentIntentId,
        payment_provider: "stripe",
        updated_at: new Date().toISOString(),
      })
      .eq("id", orderId);

    return json({
      clientSecret,
      paymentIntentId,
      customerId,
      customerEphemeralKeySecret: ephemeralKey.secret,
      // Informational — useful for UI receipts.
      breakdown: {
        subtotal,
        total,
        platformFeeRate: PLATFORM_RATE,
        applicationFeeCents,
        connectedAccountId,
      },
    }, 200);
  } catch (error) {
    console.error("[create-event-payment-intent]", error);
    return json({ error: (error as Error).message }, 500);
  }
});

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
