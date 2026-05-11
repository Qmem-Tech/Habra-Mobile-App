/**
 * Fans a notification row out as FCM HTTP v1 push notifications.
 *
 * Trigger flow:
 *   1. SQL trigger on `notifications` (per-user) or `platform_notifications`
 *      (broadcast) calls this Edge Function via pg_net or http extension.
 *   2. This function loads the row, resolves the audience -> list of fcm tokens,
 *      mints a Google OAuth access token from the FCM_SERVICE_ACCOUNT JSON,
 *      and POSTs each message to https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send.
 *
 * Deploy: `supabase functions deploy send-push-notification`
 *
 * Required secrets (Supabase dashboard → Edge Functions → Secrets):
 *   FCM_SERVICE_ACCOUNT  — entire JSON of a Firebase service account with
 *                          "Firebase Cloud Messaging API" scope.
 *   FCM_PROJECT_ID       — Firebase project ID, e.g. "habra-prod".
 *   (SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY come from the standard env.)
 *
 * Request body:
 *   { source: "user", notification_id: "<uuid>" }
 *     -> reads `public.notifications` row and pushes to that user's tokens.
 *   { source: "platform", notification_id: "<uuid>" }
 *     -> reads `public.platform_notifications` row, then fans out to every
 *        profile whose role matches `audience`.
 */
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2.45.4";
import { create, getNumericDate } from "https://deno.land/x/djwt@v3.0.2/mod.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type AdminClient = ReturnType<typeof createClient>;

interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id?: string;
}

interface NotificationPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

interface PlatformRow {
  id: string;
  title: string;
  body: string;
  audience: string | null;
}

interface UserNotificationRow {
  id: string;
  title: string;
  body: string;
  user_id: string;
  data: Record<string, unknown> | null;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const fcmServiceAccountRaw = Deno.env.get("FCM_SERVICE_ACCOUNT") ?? "";
    const fcmProjectId = Deno.env.get("FCM_PROJECT_ID") ?? "";

    if (!supabaseUrl || !serviceRoleKey) {
      return json({ error: "Missing Supabase server configuration." }, 500);
    }
    if (!fcmServiceAccountRaw || !fcmProjectId) {
      return json(
        {
          error:
            "FCM_SERVICE_ACCOUNT and FCM_PROJECT_ID secrets must be set in Supabase Edge Function secrets.",
        },
        500,
      );
    }

    const serviceAccount = JSON.parse(fcmServiceAccountRaw) as ServiceAccount;
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const body = (await req.json().catch(() => ({}))) as {
      source?: string;
      notification_id?: string;
    };
    const source = body.source;
    const notificationId = body.notification_id;
    if (!source || !notificationId) {
      return json({ error: "source and notification_id are required." }, 400);
    }

    let payload: NotificationPayload;
    let tokens: string[] = [];

    if (source === "platform") {
      const result = await loadPlatformRow(adminClient, notificationId);
      if (!result) return json({ error: "Platform notification not found." }, 404);
      payload = {
        title: result.title,
        body: result.body,
        data: { source: "platform", id: result.id },
      };
      tokens = await tokensForAudience(adminClient, result.audience ?? "all");
    } else if (source === "user") {
      const result = await loadUserRow(adminClient, notificationId);
      if (!result) return json({ error: "Notification not found." }, 404);
      payload = {
        title: result.title,
        body: result.body,
        data: {
          source: "user",
          id: result.id,
          ...stringifyData(result.data),
        },
      };
      tokens = await tokensForUser(adminClient, result.user_id);
    } else {
      return json({ error: "source must be 'user' or 'platform'." }, 400);
    }

    if (tokens.length === 0) {
      return json({ ok: true, delivered: 0, reason: "no_tokens" });
    }

    const accessToken = await mintAccessToken(serviceAccount);
    const fcmEndpoint = `https://fcm.googleapis.com/v1/projects/${fcmProjectId}/messages:send`;

    let delivered = 0;
    const invalidTokens: string[] = [];
    for (const token of tokens) {
      const res = await fetch(fcmEndpoint, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token,
            notification: { title: payload.title, body: payload.body },
            data: payload.data ?? {},
            android: { priority: "HIGH" },
            apns: {
              headers: { "apns-priority": "10" },
              payload: { aps: { sound: "default" } },
            },
          },
        }),
      });
      if (res.ok) {
        delivered++;
        continue;
      }
      if (res.status === 404 || res.status === 400) {
        // UNREGISTERED / INVALID_ARGUMENT — drop the stale token.
        invalidTokens.push(token);
      }
    }

    if (invalidTokens.length > 0) {
      await adminClient
        .from("profiles")
        .update({ fcm_token: null })
        .in("fcm_token", invalidTokens);
    }

    return json({ ok: true, delivered, total: tokens.length });
  } catch (e) {
    return json({ error: (e as Error).message }, 500);
  }
});

async function loadPlatformRow(
  adminClient: AdminClient,
  id: string,
): Promise<PlatformRow | null> {
  const { data } = await adminClient
    .from("platform_notifications")
    .select("id, title, body, audience")
    .eq("id", id)
    .maybeSingle();
  return (data as PlatformRow | null) ?? null;
}

async function loadUserRow(
  adminClient: AdminClient,
  id: string,
): Promise<UserNotificationRow | null> {
  const { data } = await adminClient
    .from("notifications")
    .select("id, title, body, user_id, data")
    .eq("id", id)
    .maybeSingle();
  return (data as UserNotificationRow | null) ?? null;
}

async function tokensForUser(
  adminClient: AdminClient,
  userId: string,
): Promise<string[]> {
  const { data } = await adminClient
    .from("profiles")
    .select("fcm_token")
    .eq("id", userId);
  return ((data ?? []) as Array<{ fcm_token: string | null }>)
    .map((row) => row.fcm_token)
    .filter((t): t is string => !!t && t.length > 0);
}

async function tokensForAudience(
  adminClient: AdminClient,
  audience: string,
): Promise<string[]> {
  let query = adminClient.from("profiles").select("fcm_token, role");
  const a = audience.toLowerCase().trim();
  if (a === "customers" || a === "customer") {
    query = query.in("role", ["customer", "guest"]);
  } else if (a === "business_owners" || a === "business_owner") {
    query = query.in("role", ["business_owner", "businessowner", "admin"]);
  }
  const { data } = await query;
  return ((data ?? []) as Array<{ fcm_token: string | null }>)
    .map((row) => row.fcm_token)
    .filter((t): t is string => !!t && t.length > 0);
}

function stringifyData(
  data: Record<string, unknown> | null,
): Record<string, string> {
  if (!data) return {};
  const out: Record<string, string> = {};
  for (const [k, v] of Object.entries(data)) {
    if (v == null) continue;
    out[k] = typeof v === "string" ? v : JSON.stringify(v);
  }
  return out;
}

async function mintAccessToken(account: ServiceAccount): Promise<string> {
  const now = getNumericDate(0);
  const exp = getNumericDate(60 * 55); // 55 minutes

  const privateKey = await importPemKey(account.private_key);
  const jwt = await create(
    { alg: "RS256", typ: "JWT" },
    {
      iss: account.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp,
    },
    privateKey,
  );

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!res.ok) {
    throw new Error(`OAuth token exchange failed: ${res.status}`);
  }
  const data = (await res.json()) as { access_token: string };
  return data.access_token;
}

async function importPemKey(pem: string): Promise<CryptoKey> {
  const cleaned = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\\n/g, "\n")
    .replace(/\s+/g, "");
  const buf = base64ToArrayBuffer(cleaned);
  return crypto.subtle.importKey(
    "pkcs8",
    buf,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

function base64ToArrayBuffer(b64: string): ArrayBuffer {
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
