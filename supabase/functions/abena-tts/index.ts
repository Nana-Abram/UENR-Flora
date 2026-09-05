import { createClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

const ABENA_API_URL = "https://abena.mobobi.com/playground/api/v1/tts/synthesize/";
const ABENA_TIMEOUT_MS = 45_000;
const KEY_COUNT = 6;
// Kept below each account's real 50-credit free-tier cap so we switch to the
// next key ahead of exhaustion instead of discovering it via a failed call.
const USAGE_LIMIT = 48;

// ABENA_API_KEY_1 falls back to the original single-key secret name so the
// already-configured first account keeps working without re-entering it.
const ABENA_KEYS: (string | undefined)[] = Array.from({ length: KEY_COUNT }, (_, i) => {
  const key = Deno.env.get(`ABENA_API_KEY_${i + 1}`)?.trim();
  if (key) return key;
  return i === 0 ? Deno.env.get("ABENA_API_KEY")?.trim() : undefined;
});

const supabaseAdmin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

function isQuotaError(status: number) {
  return status === 401 || status === 402 || status === 403 || status === 429;
}

async function callAbena(text: string, apiKey: string, signal: AbortSignal) {
  return fetch(ABENA_API_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-API-Key": apiKey,
      "Authorization": `Bearer ${apiKey}`,
    },
    body: JSON.stringify({ text, voice: "abena_twi_high", speed: 1.0 }),
    signal,
  });
}

/// Tries keys in rotation order, proactively skipping ones near their credit
/// limit (per `pick_abena_key`) and reactively marking one exhausted and
/// retrying the next only when Abena itself reports a quota/auth error —
/// a generic failure (timeout, 5xx) is surfaced immediately without rotating,
/// since switching keys wouldn't fix a service-side problem.
async function synthesizeWithRotation(text: string): Promise<{ status: number; body: string }> {
  for (let attempt = 0; attempt < KEY_COUNT; attempt++) {
    const { data: keyIndex, error: pickError } = await supabaseAdmin.rpc("pick_abena_key", {
      usage_limit: USAGE_LIMIT,
    });
    if (pickError || keyIndex == null) break;

    const apiKey = ABENA_KEYS[keyIndex - 1];
    if (!apiKey) {
      // Not configured yet (account not created/secret not set) — treat like
      // exhausted so future requests skip straight past it.
      await supabaseAdmin.rpc("mark_abena_key_exhausted", { idx: keyIndex });
      continue;
    }

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), ABENA_TIMEOUT_MS);
    let response: Response;
    try {
      response = await callAbena(text, apiKey, controller.signal);
    } finally {
      clearTimeout(timeout);
    }

    if (isQuotaError(response.status)) {
      await supabaseAdmin.rpc("mark_abena_key_exhausted", { idx: keyIndex });
      continue;
    }
    if (response.ok) {
      await supabaseAdmin.rpc("record_abena_key_success", { idx: keyIndex });
    }
    return { status: response.status, body: await response.text() };
  }
  return {
    status: 503,
    body: JSON.stringify({ error: "All Abena TTS accounts have used their available credits" }),
  };
}

Deno.serve(async (req) => {
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
    const body = await req.json();
    const text = typeof body.text === "string" ? body.text.trim() : "";
    if (!text || text.length > 500) {
      return new Response(JSON.stringify({ error: "Text must contain 1 to 500 characters" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { status, body: responseBody } = await synthesizeWithRotation(text);
    return new Response(responseBody, {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("abena-tts failed:", error);
    return new Response(JSON.stringify({ error: "TTS request failed" }), {
      status: 502,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
