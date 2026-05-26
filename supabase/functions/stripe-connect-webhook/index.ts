/**
 * Handles Stripe Connect account webhooks (separate webhook endpoint from the
 * main payment webhook).  Set this up in the Stripe Dashboard under:
 *   Connect > Webhooks > Add endpoint
 * URL: https://<project>.supabase.co/functions/v1/stripe-connect-webhook
 * Events to listen for: account.updated
 *
 * Required secret: STRIPE_CONNECT_WEBHOOK_SECRET
 */
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import Stripe from "npm:stripe@16.5.0";
import { createClient } from "npm:@supabase/supabase-js@2.45.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, stripe-signature",
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
    // Use a SEPARATE webhook secret for Connect webhooks.
    const webhookSecret = Deno.env.get("STRIPE_CONNECT_WEBHOOK_SECRET") ?? "";

    if (!supabaseUrl || !serviceRoleKey || !stripeSecretKey || !webhookSecret) {
      return new Response(
        JSON.stringify({ error: "Missing server configuration." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const stripe = new Stripe(stripeSecretKey, { apiVersion: "2024-04-10" });
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const signature = req.headers.get("stripe-signature");
    const payload = await req.text();

    if (!signature) {
      return new Response(
        JSON.stringify({ error: "Missing stripe-signature header." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const event = await stripe.webhooks.constructEventAsync(payload, signature, webhookSecret);

    if (event.type === "account.updated") {
      const account = event.data.object as Stripe.Account;
      await handleAccountUpdated(adminClient, account);
    }

    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("[stripe-connect-webhook]", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});

async function handleAccountUpdated(
  adminClient: ReturnType<typeof createClient>,
  account: Stripe.Account,
) {
  const accountId = account.id;

  // Determine the onboarding status:
  // - complete  → charges_enabled AND payouts_enabled
  // - restricted → partially completed (requirements pending)
  // - pending   → not yet started / no requirements answered
  let status: string;
  if (account.charges_enabled && account.payouts_enabled) {
    status = "complete";
  } else if (
    (account.requirements?.currently_due?.length ?? 0) > 0 ||
    (account.requirements?.past_due?.length ?? 0) > 0
  ) {
    status = "restricted";
  } else {
    status = "pending";
  }

  const update: Record<string, unknown> = { stripe_connect_status: status };
  if (status === "complete") {
    update.stripe_connect_onboarded_at = new Date().toISOString();
  }

  const { error } = await adminClient
    .from("businesses")
    .update(update)
    .eq("stripe_account_id", accountId);

  if (error) {
    console.error("[stripe-connect-webhook] DB update error:", error);
    throw error;
  }

  console.log(`[stripe-connect-webhook] Account ${accountId} → ${status}`);
}
