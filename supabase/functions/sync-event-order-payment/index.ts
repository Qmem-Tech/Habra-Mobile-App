/**
 * Called by the mobile app right after Stripe Payment Sheet succeeds.
 * Pulls PaymentIntent status from Stripe and runs the same DB finalization as
 * `stripe-event-webhook` so orders complete without waiting for webhook delivery.
 *
 * Deploy: `supabase functions deploy sync-event-order-payment`
 * Secrets: STRIPE_SECRET_KEY, SUPABASE_SERVICE_ROLE_KEY (standard Edge env)
 */
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import Stripe from "npm:stripe@16.5.0";
import { createClient } from "npm:@supabase/supabase-js@2.45.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

type SupabaseAdminClient = ReturnType<typeof createClient>;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY") ?? "";

    if (!supabaseUrl || !supabaseAnonKey || !serviceRoleKey || !stripeSecretKey) {
      return new Response(JSON.stringify({ error: "Missing server configuration." }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
    });
    const adminClient = createClient(supabaseUrl, serviceRoleKey);
    const stripe = new Stripe(stripeSecretKey, { apiVersion: "2024-04-10" });

    const { data: authData, error: authError } = await userClient.auth.getUser();
    if (authError || !authData.user) {
      return new Response(JSON.stringify({ error: "Unauthorized." }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.json().catch(() => ({}));
    const orderId = String(body?.order_id ?? "");
    if (!orderId) {
      return new Response(JSON.stringify({ error: "order_id is required." }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: order, error: orderErr } = await adminClient
      .from("orders")
      .select("id, user_id, event_id, status, stripe_payment_intent_id")
      .eq("id", orderId)
      .maybeSingle();

    if (orderErr || !order || order.user_id !== authData.user.id) {
      return new Response(JSON.stringify({ error: "Order not found." }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (order.status === "completed") {
      return new Response(JSON.stringify({ ok: true, orderStatus: "completed", synced: true }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const piId = order.stripe_payment_intent_id as string | null;
    if (!piId) {
      return new Response(JSON.stringify({ ok: false, reason: "no_payment_intent" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const intent = await stripe.paymentIntents.retrieve(piId);

    if (intent.status === "succeeded") {
      await finalizeSucceededOrder(adminClient, intent, orderId);
      return new Response(JSON.stringify({ ok: true, orderStatus: "completed", synced: true }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (intent.status === "canceled" || intent.status === "requires_payment_method") {
      await adminClient.rpc("finalize_event_order_payment", {
        p_order_id: orderId,
        p_stripe_payment_intent_id: intent.id,
        p_payment_method: "stripe_payment_sheet",
        p_payment_id: intent.latest_charge ? String(intent.latest_charge) : intent.id,
        p_status: "failed",
        p_failure_reason: intent.last_payment_error?.message ?? `Stripe status: ${intent.status}`,
      });
      return new Response(JSON.stringify({ ok: false, orderStatus: "failed", stripeStatus: intent.status }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(
      JSON.stringify({
        ok: false,
        synced: false,
        stripeStatus: intent.status,
        message: "Payment still processing in Stripe.",
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

async function finalizeSucceededOrder(
  adminClient: SupabaseAdminClient,
  intent: Stripe.PaymentIntent,
  orderId: string,
) {
  const { data: order } = await adminClient
    .from("orders")
    .select("id, event_id, user_id, status")
    .eq("id", orderId)
    .maybeSingle();
  if (!order) return;

  await adminClient.rpc("finalize_event_order_payment", {
    p_order_id: orderId,
    p_stripe_payment_intent_id: intent.id,
    p_payment_method: "stripe_payment_sheet",
    p_payment_id: intent.latest_charge ? String(intent.latest_charge) : intent.id,
    p_status: "completed",
    p_failure_reason: null,
  });

  const { data: tickets } = await adminClient
    .from("tickets")
    .select("event_ticket_id, quantity, event_tickets!inner(price)")
    .eq("order_id", orderId);
  if (!tickets || !order.event_id || !order.user_id) return;

  const merged = new Map<string, { quantity: number; totalCents: number }>();
  for (const row of tickets) {
    const ticketId = String((row as any).event_ticket_id ?? "");
    if (!ticketId) continue;
    const qty = Number((row as any).quantity ?? 1);
    const price = Number((row as any).event_tickets?.price ?? 0);
    const prev = merged.get(ticketId) ?? { quantity: 0, totalCents: 0 };
    merged.set(ticketId, {
      quantity: prev.quantity + qty,
      totalCents: prev.totalCents + Math.round(price * qty * 100),
    });
  }

  const purchaseRows = Array.from(merged.entries()).map(([eventTicketId, values]) => ({
    order_id: orderId,
    event_id: order.event_id,
    event_ticket_id: eventTicketId,
    buyer_id: order.user_id,
    quantity: values.quantity,
    total_cents: values.totalCents,
    status: "completed",
  }));

  if (purchaseRows.length > 0) {
    await adminClient.from("event_ticket_purchases").upsert(purchaseRows, {
      onConflict: "order_id,event_ticket_id",
    });
  }
}
