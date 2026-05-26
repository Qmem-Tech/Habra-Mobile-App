import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import Stripe from "npm:stripe@16.5.0";
import { createClient } from "npm:@supabase/supabase-js@2.45.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405, headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY") ?? "";
    if (!supabaseUrl || !serviceRoleKey || !stripeSecretKey) {
      return new Response(JSON.stringify({ error: "Missing server configuration." }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const stripe = new Stripe(stripeSecretKey, { apiVersion: "2024-04-10" });
    const adminClient = createClient(supabaseUrl, serviceRoleKey);
    const payload = await req.json();
    const orderId = String(payload?.order_id ?? "");
    const reason = String(payload?.reason ?? "requested_by_customer");
    if (!orderId) {
      return new Response(JSON.stringify({ error: "order_id is required." }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: order, error } = await adminClient
      .from("orders")
      .select("id, stripe_payment_intent_id, total_amount, status")
      .eq("id", orderId)
      .maybeSingle();

    if (error || !order) {
      return new Response(JSON.stringify({ error: "Order not found." }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    if (!order.stripe_payment_intent_id) {
      return new Response(JSON.stringify({ error: "Order has no Stripe payment intent." }), {
        status: 409,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    if (order.status === "refunded") {
      return new Response(JSON.stringify({ error: "Order already refunded." }), {
        status: 409,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const refund = await stripe.refunds.create({
      payment_intent: String(order.stripe_payment_intent_id),
      reason: reason as Stripe.RefundCreateParams.Reason,
    });

    await adminClient
      .from("orders")
      .update({
        refund_status: refund.status,
        refunded_amount: (refund.amount ?? 0) / 100,
        updated_at: new Date().toISOString(),
      })
      .eq("id", orderId);

    return new Response(JSON.stringify({ refundId: refund.id, refundStatus: refund.status }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
