import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import Stripe from "npm:stripe@16.5.0";
import { createClient } from "npm:@supabase/supabase-js@2.45.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, stripe-signature",
};

type SupabaseAdminClient = ReturnType<typeof createClient>;

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
    const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET") ?? "";
    if (!supabaseUrl || !serviceRoleKey || !stripeSecretKey || !webhookSecret) {
      return new Response(JSON.stringify({ error: "Missing server configuration." }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const stripe = new Stripe(stripeSecretKey, { apiVersion: "2024-04-10" });
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const signature = req.headers.get("stripe-signature");
    const payload = await req.text();
    if (!signature) {
      return new Response(JSON.stringify({ error: "Missing stripe-signature header." }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const event = await stripe.webhooks.constructEventAsync(payload, signature, webhookSecret);

    if (event.type === "payment_intent.succeeded") {
      const intent = event.data.object as Stripe.PaymentIntent;
      await handlePaymentSuccess(adminClient, intent);
      await logProviderInvoiceEvent(adminClient, {
        provider: "stripe",
        providerEventId: event.id,
        eventType: event.type,
        providerCustomerId: asString(intent.customer),
        amountCents: intent.amount_received ?? intent.amount ?? null,
        currency: intent.currency ?? null,
        status: intent.status ?? null,
      });
    } else if (event.type === "payment_intent.payment_failed") {
      const intent = event.data.object as Stripe.PaymentIntent;
      await handlePaymentFailed(adminClient, intent);
      await logProviderInvoiceEvent(adminClient, {
        provider: "stripe",
        providerEventId: event.id,
        eventType: event.type,
        providerCustomerId: asString(intent.customer),
        amountCents: intent.amount ?? null,
        currency: intent.currency ?? null,
        status: intent.status ?? null,
      });
    } else if (event.type === "charge.refunded") {
      const charge = event.data.object as Stripe.Charge;
      await handleRefunded(adminClient, charge);
      await logProviderInvoiceEvent(adminClient, {
        provider: "stripe",
        providerEventId: event.id,
        eventType: event.type,
        providerCustomerId: asString(charge.customer),
        providerInvoiceId: asString(charge.invoice),
        amountCents: charge.amount_refunded ?? null,
        currency: charge.currency ?? null,
        status: "refunded",
      });
    }

    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

async function handlePaymentSuccess(adminClient: SupabaseAdminClient, intent: Stripe.PaymentIntent) {
  const orderId = String(intent.metadata?.order_id ?? "");
  if (!orderId) return;

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
    await adminClient
      .from("event_ticket_purchases")
      .upsert(purchaseRows, { onConflict: "order_id,event_ticket_id" });
  }
}

async function handlePaymentFailed(adminClient: SupabaseAdminClient, intent: Stripe.PaymentIntent) {
  const orderId = String(intent.metadata?.order_id ?? "");
  if (!orderId) return;
  await adminClient.rpc("finalize_event_order_payment", {
    p_order_id: orderId,
    p_stripe_payment_intent_id: intent.id,
    p_payment_method: "stripe_payment_sheet",
    p_payment_id: intent.latest_charge ? String(intent.latest_charge) : intent.id,
    p_status: "failed",
    p_failure_reason: intent.last_payment_error?.message ?? "Payment failed",
  });
}

async function handleRefunded(adminClient: SupabaseAdminClient, charge: Stripe.Charge) {
  const paymentIntentId = String(charge.payment_intent ?? "");
  if (!paymentIntentId) return;

  const { data: order } = await adminClient
    .from("orders")
    .select("id")
    .eq("stripe_payment_intent_id", paymentIntentId)
    .maybeSingle();
  if (!order?.id) return;

  await adminClient
    .from("orders")
    .update({
      status: "refunded",
      refund_status: "succeeded",
      refunded_amount: (charge.amount_refunded ?? 0) / 100,
      updated_at: new Date().toISOString(),
    })
    .eq("id", order.id);

  await adminClient
    .from("event_ticket_purchases")
    .update({ status: "refunded" })
    .eq("order_id", order.id);
}

function asString(value: unknown): string {
  return String(value ?? "").trim();
}

async function logProviderInvoiceEvent(
  adminClient: SupabaseAdminClient,
  payload: {
    provider: string;
    providerEventId: string;
    eventType: string;
    userId?: string | null;
    providerCustomerId?: string | null;
    providerSubscriptionId?: string | null;
    providerInvoiceId?: string | null;
    amountCents?: number | null;
    currency?: string | null;
    status?: string | null;
  },
) {
  const row = {
    provider: payload.provider,
    provider_event_id: payload.providerEventId,
    event_type: payload.eventType,
    user_id: payload.userId || null,
    provider_customer_id: payload.providerCustomerId || null,
    provider_subscription_id: payload.providerSubscriptionId || null,
    provider_invoice_id: payload.providerInvoiceId || null,
    amount_cents: payload.amountCents ?? null,
    currency: payload.currency || null,
    status: payload.status || null,
    payload_json: payload,
  };
  try {
    await adminClient
      .from("billing_invoice_events")
      .upsert(row, { onConflict: "provider,provider_event_id" });
  } catch (_) {
    // Backward compatibility: do not fail webhook processing if ledger tables
    // are not deployed yet in the target environment.
  }
}
