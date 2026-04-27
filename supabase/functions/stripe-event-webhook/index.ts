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
      await logStripeInvoiceEvent(adminClient, {
        stripeEventId: event.id,
        eventType: event.type,
        stripeCustomerId: asString(intent.customer),
        amountCents: intent.amount_received ?? intent.amount ?? null,
        currency: intent.currency ?? null,
        status: intent.status ?? null,
      });
    } else if (event.type === "payment_intent.payment_failed") {
      const intent = event.data.object as Stripe.PaymentIntent;
      await handlePaymentFailed(adminClient, intent);
      await logStripeInvoiceEvent(adminClient, {
        stripeEventId: event.id,
        eventType: event.type,
        stripeCustomerId: asString(intent.customer),
        amountCents: intent.amount ?? null,
        currency: intent.currency ?? null,
        status: intent.status ?? null,
      });
    } else if (event.type === "charge.refunded") {
      const charge = event.data.object as Stripe.Charge;
      await handleRefunded(adminClient, charge);
      await logStripeInvoiceEvent(adminClient, {
        stripeEventId: event.id,
        eventType: event.type,
        stripeCustomerId: asString(charge.customer),
        stripeInvoiceId: asString(charge.invoice),
        amountCents: charge.amount_refunded ?? null,
        currency: charge.currency ?? null,
        status: "refunded",
      });
    } else if (event.type === "checkout.session.completed") {
      const session = event.data.object as Stripe.Checkout.Session;
      await handleCheckoutSessionCompleted(adminClient, stripe, session);
      if (session.mode === "subscription") {
        await logStripeSubscriptionEvent(adminClient, {
          stripeEventId: event.id,
          eventType: event.type,
          userId: asString(session.metadata?.user_id),
          stripeCustomerId: asString(session.customer),
          stripeSubscriptionId: asString(session.subscription),
          tier: asString(session.metadata?.tier),
          status: "active",
          source: "stripe",
        });
      }
    } else if (event.type === "checkout.session.expired") {
      const session = event.data.object as Stripe.Checkout.Session;
      if (session.mode === "subscription") {
        await logStripeSubscriptionEvent(adminClient, {
          stripeEventId: event.id,
          eventType: event.type,
          userId: asString(session.metadata?.user_id),
          stripeCustomerId: asString(session.customer),
          stripeSubscriptionId: asString(session.subscription),
          tier: asString(session.metadata?.tier),
          status: "incomplete_expired",
          source: "stripe",
        });
      }
    } else if (event.type === "customer.subscription.created") {
      const subscription = event.data.object as Stripe.Subscription;
      await handleCustomerSubscriptionChanged(adminClient, subscription);
      await logStripeSubscriptionEvent(adminClient, {
        stripeEventId: event.id,
        eventType: event.type,
        userId: asString(subscription.metadata?.user_id),
        stripeCustomerId: asString(subscription.customer),
        stripeSubscriptionId: subscription.id,
        tier: tierFromSubscriptionPrice(asString(subscription.items.data[0]?.price?.id)),
        status: normalizeSubscriptionStatus(subscription.status).dbStatus,
        source: "stripe",
      });
    } else if (event.type === "customer.subscription.updated") {
      const subscription = event.data.object as Stripe.Subscription;
      await handleCustomerSubscriptionChanged(adminClient, subscription);
      await logStripeSubscriptionEvent(adminClient, {
        stripeEventId: event.id,
        eventType: event.type,
        userId: asString(subscription.metadata?.user_id),
        stripeCustomerId: asString(subscription.customer),
        stripeSubscriptionId: subscription.id,
        tier: tierFromSubscriptionPrice(asString(subscription.items.data[0]?.price?.id)),
        status: normalizeSubscriptionStatus(subscription.status).dbStatus,
        source: "stripe",
      });
    } else if (event.type === "customer.subscription.deleted") {
      const subscription = event.data.object as Stripe.Subscription;
      await handleCustomerSubscriptionChanged(adminClient, subscription);
      await logStripeSubscriptionEvent(adminClient, {
        stripeEventId: event.id,
        eventType: event.type,
        userId: asString(subscription.metadata?.user_id),
        stripeCustomerId: asString(subscription.customer),
        stripeSubscriptionId: subscription.id,
        tier: tierFromSubscriptionPrice(asString(subscription.items.data[0]?.price?.id)),
        status: normalizeSubscriptionStatus(subscription.status).dbStatus,
        source: "stripe",
      });
    } else if (event.type === "invoice.payment_succeeded") {
      const invoice = event.data.object as Stripe.Invoice;
      await handleInvoicePaymentEvent(adminClient, invoice, true);
      await logStripeInvoiceEvent(adminClient, {
        stripeEventId: event.id,
        eventType: event.type,
        userId: asString(invoice.metadata?.user_id),
        stripeCustomerId: asString(invoice.customer),
        stripeSubscriptionId: asString(invoice.subscription),
        stripeInvoiceId: invoice.id,
        amountCents: invoice.amount_paid ?? null,
        currency: invoice.currency ?? null,
        status: invoice.status ?? "paid",
      });
    } else if (event.type === "invoice.payment_failed") {
      const invoice = event.data.object as Stripe.Invoice;
      await handleInvoicePaymentEvent(adminClient, invoice, false);
      await logStripeInvoiceEvent(adminClient, {
        stripeEventId: event.id,
        eventType: event.type,
        userId: asString(invoice.metadata?.user_id),
        stripeCustomerId: asString(invoice.customer),
        stripeSubscriptionId: asString(invoice.subscription),
        stripeInvoiceId: invoice.id,
        amountCents: invoice.amount_due ?? null,
        currency: invoice.currency ?? null,
        status: invoice.status ?? "open",
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

function tierFromSubscriptionPrice(priceId: string): string | null {
  const proPriceId = Deno.env.get("STRIPE_BUSINESS_PRO_PRICE_ID") ?? "";
  const premiumPriceId = Deno.env.get("STRIPE_BUSINESS_PREMIUM_PRICE_ID") ?? "";
  if (priceId === premiumPriceId) return "premium";
  if (priceId === proPriceId) return "pro";
  return null;
}

function normalizeSubscriptionStatus(status?: string): {
  active: boolean;
  dbStatus: string;
} {
  const s = (status ?? "").toLowerCase();
  switch (s) {
    case "active":
      return { active: true, dbStatus: "active" };
    case "trialing":
      return { active: true, dbStatus: "trialing" };
    case "past_due":
      return { active: false, dbStatus: "past_due" };
    case "canceled":
      return { active: false, dbStatus: "canceled" };
    case "unpaid":
      return { active: false, dbStatus: "inactive" };
    default:
      return { active: false, dbStatus: "inactive" };
  }
}

async function handleCheckoutSessionCompleted(
  adminClient: SupabaseAdminClient,
  stripe: Stripe,
  session: Stripe.Checkout.Session,
) {
  if (session.mode !== "subscription") return;
  const userId = String(session.metadata?.user_id ?? "").trim();
  const subscriptionId = String(session.subscription ?? "").trim();
  const customerId = String(session.customer ?? "").trim();
  if (!userId || !subscriptionId) return;
  const subscription = await stripe.subscriptions.retrieve(subscriptionId);
  await applyBusinessSubscriptionProfile(adminClient, userId, customerId, subscription);
}

async function handleCustomerSubscriptionChanged(
  adminClient: SupabaseAdminClient,
  subscription: Stripe.Subscription,
) {
  const userId = String(subscription.metadata?.user_id ?? "").trim();
  const customerId = String(subscription.customer ?? "").trim();
  if (!userId || !customerId) return;
  await applyBusinessSubscriptionProfile(adminClient, userId, customerId, subscription);
}

async function applyBusinessSubscriptionProfile(
  adminClient: SupabaseAdminClient,
  userId: string,
  customerId: string,
  subscription: Stripe.Subscription,
) {
  const firstItem = subscription.items.data[0];
  const priceId = String(firstItem?.price?.id ?? "");
  const tier = tierFromSubscriptionPrice(priceId) ?? "basic";
  const status = normalizeSubscriptionStatus(subscription.status);
  let payload: Record<string, unknown> = {
    stripe_customer_id: customerId,
    owner_tools_subscription_active: status.active,
    owner_tools_subscription_tier: tier,
    owner_tools_subscription_status: status.dbStatus,
    owner_tools_subscription_updated_at: new Date().toISOString(),
    owner_tools_subscription_source: "stripe",
    owner_tools_subscription_origin_id: subscription.id,
  };
  try {
    await adminClient.from("profiles").update(payload).eq("id", userId);
  } catch (_) {
    // Backward-compatible fallback for schemas that only have active/tier columns.
    payload = {
      stripe_customer_id: customerId,
      owner_tools_subscription_active: status.active,
      owner_tools_subscription_tier: tier,
      owner_tools_subscription_source: "stripe",
      owner_tools_subscription_origin_id: subscription.id,
    };
    await adminClient.from("profiles").update(payload).eq("id", userId);
  }
}

async function handleInvoicePaymentEvent(
  adminClient: SupabaseAdminClient,
  invoice: Stripe.Invoice,
  paid: boolean,
) {
  const userId = asString(invoice.metadata?.user_id);
  const customerId = asString(invoice.customer);
  const subscriptionId = asString(invoice.subscription);
  if (!userId || !customerId || !subscriptionId) return;

  const status = paid
    ? { active: true, dbStatus: "active" }
    : { active: false, dbStatus: "past_due" };
  const payload: Record<string, unknown> = {
    stripe_customer_id: customerId,
    owner_tools_subscription_active: status.active,
    owner_tools_subscription_status: status.dbStatus,
    owner_tools_subscription_updated_at: new Date().toISOString(),
    owner_tools_subscription_source: "stripe",
    owner_tools_subscription_origin_id: subscriptionId,
  };
  try {
    await adminClient.from("profiles").update(payload).eq("id", userId);
  } catch (_) {
    await adminClient
      .from("profiles")
      .update({
        stripe_customer_id: customerId,
        owner_tools_subscription_active: status.active,
      })
      .eq("id", userId);
  }
}

function asString(value: unknown): string {
  return String(value ?? "").trim();
}

async function logStripeSubscriptionEvent(
  adminClient: SupabaseAdminClient,
  payload: {
    stripeEventId: string;
    eventType: string;
    userId?: string | null;
    stripeCustomerId?: string | null;
    stripeSubscriptionId?: string | null;
    tier?: string | null;
    status?: string | null;
    source?: string | null;
  },
) {
  const row = {
    stripe_event_id: payload.stripeEventId,
    event_type: payload.eventType,
    user_id: payload.userId || null,
    stripe_customer_id: payload.stripeCustomerId || null,
    stripe_subscription_id: payload.stripeSubscriptionId || null,
    tier: payload.tier || "basic",
    status: payload.status || "inactive",
    source: payload.source || "stripe",
    payload_json: payload,
  };
  try {
    await adminClient
      .from("billing_subscription_events")
      .upsert(row, { onConflict: "stripe_event_id" });
  } catch (_) {
    // Backward compatibility: do not fail webhook processing if ledger tables
    // are not deployed yet in the target environment.
  }
}

async function logStripeInvoiceEvent(
  adminClient: SupabaseAdminClient,
  payload: {
    stripeEventId: string;
    eventType: string;
    userId?: string | null;
    stripeCustomerId?: string | null;
    stripeSubscriptionId?: string | null;
    stripeInvoiceId?: string | null;
    amountCents?: number | null;
    currency?: string | null;
    status?: string | null;
  },
) {
  const row = {
    stripe_event_id: payload.stripeEventId,
    event_type: payload.eventType,
    user_id: payload.userId || null,
    stripe_customer_id: payload.stripeCustomerId || null,
    stripe_subscription_id: payload.stripeSubscriptionId || null,
    stripe_invoice_id: payload.stripeInvoiceId || null,
    amount_cents: payload.amountCents ?? null,
    currency: payload.currency || null,
    status: payload.status || null,
    payload_json: payload,
  };
  try {
    await adminClient
      .from("billing_invoice_events")
      .upsert(row, { onConflict: "stripe_event_id" });
  } catch (_) {
    // Backward compatibility: do not fail webhook processing if ledger tables
    // are not deployed yet in the target environment.
  }
}
