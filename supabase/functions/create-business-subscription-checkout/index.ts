import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import Stripe from "npm:stripe@16.5.0";
import { createClient } from "npm:@supabase/supabase-js@2.45.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function tierToPriceId(tier: string): string | null {
  const normalized = tier.trim().toLowerCase();
  if (normalized === "premium") {
    return Deno.env.get("STRIPE_BUSINESS_PREMIUM_PRICE_ID") ?? null;
  }
  if (normalized === "pro") {
    return Deno.env.get("STRIPE_BUSINESS_PRO_PRICE_ID") ?? null;
  }
  return null;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY") ?? "";
    if (!supabaseUrl || !supabaseAnonKey || !serviceRoleKey || !stripeSecretKey) {
      return new Response(
        JSON.stringify({ error: "Missing server configuration." }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
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
    const tier = String(body?.tier ?? "").trim().toLowerCase();
    const successUrl = String(body?.success_url ?? "").trim();
    const cancelUrl = String(body?.cancel_url ?? "").trim();
    const priceId = tierToPriceId(tier);
    if (!priceId) {
      return new Response(
        JSON.stringify({ error: "Unsupported tier or missing Stripe price id." }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }
    if (!successUrl || !cancelUrl) {
      return new Response(
        JSON.stringify({ error: "success_url and cancel_url are required." }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const userId = authData.user.id;
    const { data: profile } = await adminClient
      .from("profiles")
      .select("email, stripe_customer_id")
      .eq("id", userId)
      .maybeSingle();
    const profileEmail = typeof profile?.email === "string" ? profile.email : null;
    let customerId =
      typeof profile?.stripe_customer_id === "string" ? profile.stripe_customer_id : null;
    if (!customerId) {
      const customer = await stripe.customers.create({
        email: profileEmail ?? authData.user.email ?? undefined,
        metadata: {
          supabase_user_id: userId,
        },
      });
      customerId = customer.id;
      await adminClient
        .from("profiles")
        .update({ stripe_customer_id: customerId })
        .eq("id", userId);
    }

    const session = await stripe.checkout.sessions.create({
      mode: "subscription",
      customer: customerId,
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: successUrl,
      cancel_url: cancelUrl,
      metadata: {
        user_id: userId,
        tier,
        feature: "business_owner_subscription",
      },
      subscription_data: {
        metadata: {
          user_id: userId,
          tier,
          feature: "business_owner_subscription",
        },
      },
      allow_promotion_codes: true,
    });

    return new Response(
      JSON.stringify({
        url: session.url,
        id: session.id,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
