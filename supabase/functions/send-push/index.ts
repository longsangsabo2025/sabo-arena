// deno-lint-ignore-file no-explicit-any
// Supabase Edge Function: send-push
// Requires secret FCM_SERVICE_ACCOUNT_JSON (full service account JSON)
// POST payload:
// {
//   "user_ids": ["uuid"], // or "tokens": ["token1", ...]
//   "title": "...",
//   "body": "...",
//   "data": {"key":"value"}
// }

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import * as jose from "https://deno.land/x/jose@v5.9.4/index.ts";

const PROJECT_ID = Deno.env.get("GCP_PROJECT_ID") ?? JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT_JSON") || "{}").project_id;

async function getAccessToken(): Promise<string> {
  const svcRaw = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
  if (!svcRaw) throw new Error("Missing FCM_SERVICE_ACCOUNT_JSON secret");
  const svc = JSON.parse(svcRaw);

  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: svc.client_email,
    sub: svc.client_email,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  };

  const privateKey = svc.private_key as string;
  const alg = "RS256";
  const key = await jose.importPKCS8(privateKey, alg);
  const jwt = await new jose.SignJWT(payload)
    .setProtectedHeader({ alg, typ: "JWT" })
    .sign(key);

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Token exchange failed: ${res.status} ${text}`);
  }
  const json = await res.json();
  return json.access_token as string;
}

async function sendFcm(accessToken: string, message: Record<string, any>) {
  const url = `https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ message }),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`FCM send error: ${res.status} ${text}`);
  }
  return await res.json();
}

serve(async (req) => {
  try {
    if (req.method !== "POST") return new Response("Method Not Allowed", { status: 405 });

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
    });

    const payload = await req.json();
    const { user_ids, tokens, title, body, data } = payload ?? {};

    if ((!user_ids || user_ids.length === 0) && (!tokens || tokens.length === 0)) {
      return new Response(JSON.stringify({ error: "Provide user_ids or tokens" }), { status: 400 });
    }

    let targetTokens: string[] = [];
    if (tokens && Array.isArray(tokens) && tokens.length > 0) {
      targetTokens = tokens;
    } else if (user_ids && Array.isArray(user_ids) && user_ids.length > 0) {
      const { data: rows, error } = await supabase
        .from("device_tokens")
        .select("token")
        .in("user_id", user_ids);
      if (error) throw error;
      targetTokens = (rows ?? []).map((r: any) => r.token).filter((t: string) => !!t);
    }

    if (targetTokens.length === 0) {
      return new Response(JSON.stringify({ warning: "No target tokens" }), { status: 200 });
    }

    const accessToken = await getAccessToken();

    const results: any[] = [];
    for (const token of targetTokens) {
      const message = {
        token,
        notification: title || body ? { title, body } : undefined,
        data: data ? Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])) : undefined,
        apns: {
          headers: { "apns-priority": "10" },
          payload: {
            aps: { alert: { title, body }, sound: "default", badge: 1 },
          },
        },
        android: {
          priority: "HIGH",
          notification: { channel_id: "default_channel" },
        },
      };
      try {
        const res = await sendFcm(accessToken, message);
        results.push({ token, ok: true, id: res?.name ?? null });
      } catch (e) {
        results.push({ token, ok: false, error: String(e) });
      }
    }

    return new Response(JSON.stringify({ count: results.length, results }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
});
