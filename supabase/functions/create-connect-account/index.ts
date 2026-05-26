/**
 * Creates (or retrieves) a Stripe Express connected account for a business owner
 * and returns an onboarding URL.
 *
 * Request body (POST):
 *   { business_id: string, return_url: string, refresh_url: string }
 *
 * Response:
 *   { url: string }  — open this in the browser; Stripe handles the rest.
 *
 * After the owner completes onboarding, Stripe fires `account.updated` which
 * the stripe-connect-webhook function picks up to mark the account complete.
 */
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import Stripe from "npm:stripe@16.5.0";
import { createClient } from "npm:@supabase/supabase-js@2.45.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return json({ ok: true }, 200);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY") ?? "";

    if (!supabaseUrl || !supabaseAnonKey || !serviceRoleKey || !stripeSecretKey) {
      return json({ error: "Missing server configuration." }, 500);
    }

    // Authenticate the calling user.
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
    });
    const { data: authData, error: authError } = await userClient.auth.getUser();
    if (authError || !authData.user) {
      return json({ error: "Unauthorized." }, 401);
    }

    const body = await req.json();
    const businessId = String(body?.business_id ?? "").trim();
    const checkStatusOnly = body?.check_status === true;
    const returnUrl = String(body?.return_url ?? "").trim();
    const refreshUrl = String(body?.refresh_url ?? "").trim();

    if (!businessId) {
      return json({ error: "business_id is required." }, 400);
    }
    if (!checkStatusOnly && (!returnUrl || !refreshUrl)) {
      return json({ error: "return_url and refresh_url are required." }, 400);
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    // Verify this business belongs to the authenticated user.
    const { data: business, error: bizError } = await adminClient
      .from("businesses")
      .select("id, owner_id, name, stripe_account_id, stripe_connect_status, stripe_connect_onboarded_at")
      .eq("id", businessId)
      .maybeSingle();

    if (bizError || !business) {
      return json({ error: "Business not found." }, 404);
    }
    if (business.owner_id !== authData.user.id) {
      return json({ error: "You do not own this business." }, 403);
    }

    const stripe = new Stripe(stripeSecretKey, { apiVersion: "2024-04-10" });

    // ── If called with check_status=true, sync status directly from Stripe ───
    if (checkStatusOnly) {
      const existingAccountId = business.stripe_account_id as string | null;
      if (!existingAccountId) {
        return json({ status: "pending", charges_enabled: false, payouts_enabled: false }, 200);
      }
      const acct = await stripe.accounts.retrieve(existingAccountId);
      let status: string;
      if (acct.charges_enabled && acct.payouts_enabled) {
        status = "complete";
      } else if (
        (acct.requirements?.currently_due?.length ?? 0) > 0 ||
        (acct.requirements?.past_due?.length ?? 0) > 0
      ) {
        status = "restricted";
      } else {
        status = "pending";
      }
      const update: Record<string, unknown> = { stripe_connect_status: status };
      if (status === "complete" && !business.stripe_connect_onboarded_at) {
        update.stripe_connect_onboarded_at = new Date().toISOString();
      }
      await adminClient.from("businesses").update(update).eq("id", businessId);
      return json({
        status,
        charges_enabled: acct.charges_enabled,
        payouts_enabled: acct.payouts_enabled,
        requirements: acct.requirements,
      }, 200);
    }

    // ── Reuse existing account if one was already created ────────────────────
    let accountId = business.stripe_account_id as string | null;
    if (!accountId) {
      const account = await stripe.accounts.create({
        type: "express",
        capabilities: {
          card_payments: { requested: true },
          transfers: { requested: true },
        },
        business_type: "individual",
        metadata: {
          business_id: businessId,
          owner_id: authData.user.id,
        },
      });
      accountId = account.id;

      // Persist the account id immediately so we never create duplicates.
      await adminClient
        .from("businesses")
        .update({
          stripe_account_id: accountId,
          stripe_connect_status: "pending",
        })
        .eq("id", businessId);
    }

    // Generate a fresh onboarding link (they expire after a few minutes).
    const accountLink = await stripe.accountLinks.create({
      account: accountId,
      refresh_url: refreshUrl,
      return_url: returnUrl,
      type: "account_onboarding",
    });

    return json({ url: accountLink.url, account_id: accountId }, 200);
  } catch (error) {
    console.error("[create-connect-account]", error);
    return json({ error: (error as Error).message }, 500);
  }
});

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
