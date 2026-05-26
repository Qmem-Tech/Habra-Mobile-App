import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
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
    return new Response("Method not allowed", { status: 405, headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const webhookAuth = (Deno.env.get("REVENUECAT_WEBHOOK_AUTH") ?? "").trim();
    if (!supabaseUrl || !serviceRoleKey) {
      return new Response(JSON.stringify({ error: "Missing server configuration." }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (webhookAuth) {
      const authHeader = (req.headers.get("authorization") ?? "").trim();
      const expected = `Bearer ${webhookAuth}`;
      if (authHeader !== expected) {
        return new Response(JSON.stringify({ error: "Unauthorized webhook call." }), {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey);
    const body = await req.json();
    const event = normalizeEvent(body);
    if (!event.userId) {
      return new Response(JSON.stringify({ received: true, ignored: "missing app_user_id" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const tier = resolveTier(event);
    const status = resolveStatus(event.type);
    await applyProfileSnapshot(adminClient, {
      userId: event.userId,
      active: status.active,
      tier,
      dbStatus: status.dbStatus,
      originId: event.subscriptionOrTransactionId,
    });

    await logSubscriptionLedger(adminClient, {
      provider: "revenuecat",
      providerEventId: event.id,
      eventType: event.type,
      userId: event.userId,
      providerCustomerId: event.originalAppUserId,
      providerSubscriptionId: event.subscriptionOrTransactionId,
      tier,
      status: status.dbStatus,
      payload: body,
    });

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

function normalizeEvent(payload: Record<string, unknown>) {
  const rawEvent = (payload.event ?? payload) as Record<string, unknown>;
  const eventId = asString(rawEvent.id) || asString(rawEvent.event_id) || crypto.randomUUID();
  const type = asString(rawEvent.type).toUpperCase();
  const userId = asString(rawEvent.app_user_id);
  const originalAppUserId = asString(rawEvent.original_app_user_id);
  const entitlementIds = asStringArray(rawEvent.entitlement_ids);
  const productId = asString(rawEvent.product_id);
  const transactionId =
    asString(rawEvent.transaction_id) || asString(rawEvent.original_transaction_id);
  const subscriptionId = asString(rawEvent.store_transaction_id);

  return {
    id: eventId,
    type,
    userId,
    originalAppUserId,
    entitlementIds,
    productId,
    subscriptionOrTransactionId: subscriptionId || transactionId || eventId,
  };
}

function resolveTier(event: ReturnType<typeof normalizeEvent>): string {
  const probes = [
    ...event.entitlementIds,
    event.productId,
    event.subscriptionOrTransactionId,
  ].join(" ").toLowerCase();
  if (probes.includes("premium")) return "premium";
  if (probes.includes("pro")) return "pro";
  return "basic";
}

function resolveStatus(type: string): { active: boolean; dbStatus: string } {
  switch (type) {
    case "INITIAL_PURCHASE":
    case "RENEWAL":
    case "UNCANCELLATION":
      return { active: true, dbStatus: "active" };
    case "BILLING_ISSUE":
      return { active: false, dbStatus: "past_due" };
    case "CANCELLATION":
    case "EXPIRATION":
      return { active: false, dbStatus: "canceled" };
    default:
      return { active: false, dbStatus: "inactive" };
  }
}

async function applyProfileSnapshot(
  adminClient: SupabaseAdminClient,
  payload: {
    userId: string;
    active: boolean;
    tier: string;
    dbStatus: string;
    originId: string;
  },
) {
  const row: Record<string, unknown> = {
    owner_tools_subscription_active: payload.active,
    owner_tools_subscription_tier: payload.tier,
    owner_tools_subscription_status: payload.dbStatus,
    owner_tools_subscription_updated_at: new Date().toISOString(),
    owner_tools_subscription_source: "revenuecat",
    owner_tools_subscription_origin_id: payload.originId,
  };
  try {
    await adminClient.from("profiles").update(row).eq("id", payload.userId);
  } catch (_) {
    await adminClient.from("profiles").update({
      owner_tools_subscription_active: payload.active,
      owner_tools_subscription_tier: payload.tier,
    }).eq("id", payload.userId);
  }
}

async function logSubscriptionLedger(
  adminClient: SupabaseAdminClient,
  payload: {
    provider: string;
    providerEventId: string;
    eventType: string;
    userId: string;
    providerCustomerId?: string;
    providerSubscriptionId?: string;
    tier: string;
    status: string;
    payload: unknown;
  },
) {
  try {
    await adminClient
      .from("billing_subscription_events")
      .upsert({
        provider: payload.provider,
        provider_event_id: payload.providerEventId,
        event_type: payload.eventType,
        user_id: payload.userId,
        provider_customer_id: payload.providerCustomerId ?? null,
        provider_subscription_id: payload.providerSubscriptionId ?? null,
        tier: payload.tier,
        status: payload.status,
        source: "revenuecat",
        payload_json: payload.payload,
      }, {
        onConflict: "provider,provider_event_id",
      });
  } catch (_) {
    // Keep webhook resilient if migration is not deployed yet.
  }
}

function asString(value: unknown): string {
  return String(value ?? "").trim();
}

function asStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.map((v) => asString(v)).filter((v) => v.length > 0);
}
