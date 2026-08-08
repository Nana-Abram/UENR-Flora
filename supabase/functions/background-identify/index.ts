// Hidden background "second opinion" for the UENR Flora plant scanner.
// Called directly from the Flutter web app (lib/features/scan/services/
// background_identifier_service.dart) only when the on-device MobileNetV2
// classifier's own result is ambiguous — never for a confident scan, and
// never visible in any UI. This is the ONLY place the Claude API key is
// ever used; it never ships inside the public Flutter web bundle.
//
// Deployed with default JWT verification ON (unlike send-daily-challenge-
// push's --no-verify-jwt + shared-secret setup) — supabase_flutter's
// .functions.invoke() already attaches the app's anon key as a bearer
// token automatically, so Supabase's own platform check is sufficient
// access control here. This is also the first edge function in this
// project ever called directly from a browser, which is why CORS
// handling (see _shared/cors.ts) is needed at all — the cron-invoked
// function has no browser-facing precedent that would have needed it.
//
// Contract with the Dart caller: ALWAYS responds HTTP 200 with either
// {success:true, ...} or {success:false, error_message}, for anything
// short of a fundamentally malformed request. Every exception anywhere in
// this handler is caught and turned into the success:false shape rather
// than a 500 — BackgroundIdentifierService's Dart-side catch only needs
// to handle genuine transport failures (timeout, network drop), not
// parse error bodies out of failed HTTP statuses.
//
// Provider history: originally called Gemini (gemini-flash-latest). That
// model generation enforces a mandatory minimum "thinking" budget that
// can't be disabled (confirmed: thinkingBudget:0 is rejected with 400),
// which measured ~20-25s per call end-to-end even for this simple 5-way
// multiple-choice question — thinking tokens alone ran ~6x the actual
// output. Switched to Claude specifically because extended thinking there
// is opt-in and OFF by default (see callClaude below, no `thinking` key
// is sent), which should remove that tax entirely for a task this size.
import { corsHeaders } from "../_shared/cors.ts";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY")!;
// Fastest current vision-capable Claude model — appropriate given this
// still fires on a meaningful share of scans (any local confidence below
// 85%, see BackgroundIdentifierService.shouldActivate). Override via the
// CLAUDE_MODEL secret to pin/upgrade without a redeploy of this file.
const CLAUDE_MODEL = Deno.env.get("CLAUDE_MODEL") ?? "claude-haiku-4-5-20251001";
const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";
const ANTHROPIC_VERSION = "2023-06-01";
// Generous relative to Claude's expected latency (no forced thinking, a
// small structured-output response) — this is a conservative starting
// budget, not a measured ceiling; tighten once real ai_analysis telemetry
// comes in. Compare to the 20s this same constant needed under Gemini.
const CLAUDE_TIMEOUT_MS = 15_000;

// How many of the top candidates (by local model probability — candidates
// arrive pre-sorted, candidate_number 1 is always the local top pick) get
// their reference photos attached is NOT fixed — it tracks how torn the
// local model itself was, via the margin between its top two picks (see
// referenceCandidateCount): a wide margin means only the top guess needs
// visual confirmation, while a narrow one means the model was genuinely
// torn between several candidates, and Claude benefits from comparing all
// of them visually. Each selected candidate sends every gallery photo it
// has (see CandidateSpecies.reference_image_urls) rather than just one,
// since none of them are tagged by content — see that field's own comment.
const WIDE_MARGIN_THRESHOLD = 0.15; // > this → only candidate 1 gets photos
const NARROW_MARGIN_THRESHOLD = 0.05; // >= this (and <= wide) → top 2; below → top 3

function referenceCandidateCount(candidates: CandidateSpecies[]): number {
  if (candidates.length < 2) return 1;
  const margin = candidates[0].local_model_confidence - candidates[1].local_model_confidence;
  if (margin > WIDE_MARGIN_THRESHOLD) return 1;
  if (margin >= NARROW_MARGIN_THRESHOLD) return 2;
  return 3;
}

interface CandidateSpecies {
  candidate_number: number;
  scientific_name: string;
  common_name: string;
  family_name?: string;
  leaf_type?: string;
  growth_habit?: string;
  growth_type?: string;
  origin?: string;
  // Morphology detail beyond leaf_type — populated by a one-time research
  // backfill, not guaranteed present for every species (see
  // PlantSpecies' own field-level comments on the Dart side).
  leaf_arrangement?: string;
  leaf_margin?: string;
  venation?: string;
  leaf_shape?: string;
  leaf_texture?: string;
  flower?: string;
  fruit?: string;
  bark?: string;
  local_model_confidence: number;
  // Up to 3 gallery photos for this species — none tagged by content (no
  // "leaf close-up" vs "whole tree" label exists in the database), so all
  // of them go to Claude together when this candidate is selected for
  // reference photos at all (see referenceCandidateCount).
  reference_image_urls?: string[];
}

// Every OTHER species in the database (id/names only, no metadata, no
// photos) — lets Claude name a species outside the 5 numbered candidates
// when none of them fit, instead of always falling through to "uncertain".
// See buildFullListBlock and the pick===0 handling below.
interface SpeciesRef {
  species_id: string;
  scientific_name: string;
  common_name: string;
}

interface ImagePayload {
  data: string;
  mime_type: string;
}

interface RequestBody {
  ping?: boolean;
  images: ImagePayload[];
  candidates: CandidateSpecies[];
  all_species?: SpeciesRef[];
  // True when the Dart client's OodDetector placed this scan in the
  // Borderline zone (see lib/features/scan/services/ood_detector.dart) —
  // appends BORDERLINE_NOTE to the prompt. Optional/defaulted false so an
  // older client build that doesn't send it yet still works unchanged.
  ood_borderline?: boolean;
}

// Appended to the prompt only when RequestBody.ood_borderline is true — the
// local model's own feature-space signal (independent of this Claude call)
// suggests the photo might not be one of the 76 documented species at all.
// Claude's submit_verdict tool already supports suggested_candidate_number:
// 0 ("none of these") via the outside-species path in buildFullListBlock's
// instructions; this note just makes that outcome more likely to actually
// get picked when warranted, instead of defaulting to whichever numbered
// candidate looks least-wrong.
const BORDERLINE_NOTE =
  "\n\nNote: the local model's internal feature distance suggests this plant may not be one of the 76 documented species. Consider carefully whether any of the candidates are a genuine match, or whether this is an unknown/undocumented plant.";

interface ClaudeVerdict {
  suggested_candidate_number: number;
  // Only meaningful when suggested_candidate_number is 0 — Claude's pick
  // of a species OUTSIDE the numbered candidates, by exact id from the
  // all_species list. Absent/empty means Claude just doesn't think the
  // photo matches anything it was shown at all.
  outside_species_id?: string;
  confidence_score: number;
  reasoning: string;
}

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function failure(message: string): Response {
  return jsonResponse({ success: false, error_message: message });
}

// A separate on-device model has already narrowed the photo down to a
// fixed list of N candidates, ranked by its own confidence — Claude's job
// is only to confirm or challenge that specific shortlist using the
// attached photos, never to name a species outside it. Framed as an
// internal quality-control step (per the product spec) since reasoning is
// never shown to any user.
//
// referenceCount is how many of the candidates got an actual reference
// photo attached (see buildContent) — mentioned explicitly so Claude
// knows *some* candidates are text-only and shouldn't be penalised for
// lacking a photo to compare against.
// Only species NOT already among the numbered candidates get listed here —
// no point spending tokens repeating candidates Claude already saw in
// full detail above. Text-only (id + names), no metadata/photos: this is
// a name/id lookup list, not something to visually compare against.
function buildFullListBlock(allSpecies: SpeciesRef[], candidates: CandidateSpecies[]): string {
  if (allSpecies.length === 0) return "";
  const candidateNames = new Set(candidates.map((c) => c.scientific_name));
  const remaining = allSpecies.filter((s) => !candidateNames.has(s.scientific_name));
  if (remaining.length === 0) return "";

  const list = remaining.map((s) => `${s.species_id}: ${s.scientific_name} (${s.common_name})`).join("\n");
  return `\n\nIf you do NOT think the photo(s) match any of the ${candidates.length} numbered candidates above, but you clearly and confidently recognise the plant as one of these OTHER species in the same database, call submit_verdict with suggested_candidate_number: 0 and outside_species_id set to that species' exact id string from the list below (copy it exactly). Only do this if you are genuinely confident — otherwise leave outside_species_id unset and just return suggested_candidate_number: 0.

Other database species (id: scientific name (common name)):
${list}`;
}

function buildPrompt(
  candidates: CandidateSpecies[],
  userPhotoCount: number,
  referenceCount: number,
  allSpecies: SpeciesRef[],
  oodBorderline: boolean,
): string {
  const list = candidates
    .map((c) => {
      const fields = [
        `family: ${c.family_name ?? "unknown"}`,
        `leaf type: ${c.leaf_type ?? "unknown"}`,
        `growth habit: ${c.growth_habit ?? "unknown"}`,
        `origin: ${c.origin ?? "unknown"}`,
        // Morphology detail — omitted entirely (not even as "unknown")
        // when absent, rather than padding the prompt with filler for
        // species the one-time research backfill hasn't reached yet.
        c.leaf_arrangement ? `leaf arrangement: ${c.leaf_arrangement}` : null,
        c.leaf_margin ? `leaf margin: ${c.leaf_margin}` : null,
        c.venation ? `venation: ${c.venation}` : null,
        c.leaf_shape ? `leaf shape: ${c.leaf_shape}` : null,
        c.leaf_texture ? `leaf texture: ${c.leaf_texture}` : null,
        c.flower ? `flower: ${c.flower}` : null,
        c.fruit ? `fruit: ${c.fruit}` : null,
        c.bark ? `bark: ${c.bark}` : null,
        `local model confidence: ${c.local_model_confidence.toFixed(2)}`,
      ].filter((f) => f !== null).join(", ");
      return `${c.candidate_number}. ${c.scientific_name} (${c.common_name}) — ${fields}`;
    })
    .join("\n");

  const photoLine = userPhotoCount === 1
    ? "The first image below is the user's photo of the plant."
    : `The first ${userPhotoCount} images below are the user's own photos of the SAME plant, taken from different angles.`;
  const referenceLine = referenceCount > 0
    ? ` After that, reference photos for ${referenceCount} of the candidates follow (possibly several angles per candidate), each set immediately preceded by a text label naming which candidate they're reference photos for — use these for an actual visual comparison, not just the text description. Candidates without reference photos attached should be judged on the text description alone.`
    : "";
  const fullListBlock = buildFullListBlock(allSpecies, candidates);

  const borderlineNote = oodBorderline ? BORDERLINE_NOTE : "";

  return `You are an internal botanical quality-control step in a plant identification pipeline. A separate on-device machine learning model has already analysed the user's photo(s) and narrowed the result down to the following ${candidates.length} candidate species, ranked by that model's own confidence (candidate 1 is its top guess). Your job is ONLY to confirm or challenge that call, not to choose from all possible plant species.

${photoLine}${referenceLine}

Candidates:
${list}${fullListBlock}

Examine the user's photo(s) against each candidate's characteristics (and reference photo, where provided), then call the submit_verdict tool with suggested_candidate_number (an integer from 1 to ${candidates.length}, or exactly 0 if you are not reasonably confident the photo matches ANY of these ${candidates.length} candidates), confidence_score (0 to 1, your own confidence in that pick), and reasoning (one or two sentences — internal use only, never shown to any user). Do not suggest a species outside the candidates and the other-species list above.${borderlineNote}`;
}

// Builds the ordered content blocks: prompt text, then every user photo,
// then (candidate label + all its gallery photos) for however many top
// candidates referenceCandidateCount says need a visual check. Reference
// photos are attached by URL, not fetched/re-encoded here — confirmed
// working directly against the Anthropic API (a real Supabase Storage
// species photo was correctly identified via a source:{type:"url"} image
// block), so there's no need for the edge function to download+base64
// these files itself on every call.
function buildContent(
  images: ImagePayload[],
  candidates: CandidateSpecies[],
  allSpecies: SpeciesRef[],
  oodBorderline: boolean,
): Record<string, unknown>[] {
  const cutoff = referenceCandidateCount(candidates);
  const referenceCandidates = candidates.filter(
    (c) => c.candidate_number <= cutoff && (c.reference_image_urls?.length ?? 0) > 0,
  );

  const prompt = buildPrompt(candidates, images.length, referenceCandidates.length, allSpecies, oodBorderline);

  const content: Record<string, unknown>[] = [{ type: "text", text: prompt }];

  for (const img of images) {
    content.push({
      type: "image",
      source: { type: "base64", media_type: img.mime_type, data: img.data },
    });
  }

  for (const c of referenceCandidates) {
    const urls = c.reference_image_urls ?? [];
    content.push({
      type: "text",
      text: `Reference photo${urls.length > 1 ? "s" : ""} for candidate ${c.candidate_number} (${c.scientific_name}):`,
    });
    for (const url of urls) {
      content.push({ type: "image", source: { type: "url", url } });
    }
  }

  return content;
}

async function callClaude(
  images: ImagePayload[],
  candidates: CandidateSpecies[],
  allSpecies: SpeciesRef[],
  oodBorderline: boolean,
): Promise<ClaudeVerdict> {
  const response = await fetch(ANTHROPIC_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": ANTHROPIC_API_KEY,
      "anthropic-version": ANTHROPIC_VERSION,
    },
    signal: AbortSignal.timeout(CLAUDE_TIMEOUT_MS),
    body: JSON.stringify({
      model: CLAUDE_MODEL,
      max_tokens: 300,
      // No `thinking` key — extended thinking on Claude is opt-in and OFF
      // by default, which is the entire point of this switch (see the
      // file-level comment). Nothing to disable here, unlike Gemini.
      messages: [{ role: "user", content: buildContent(images, candidates, allSpecies, oodBorderline) }],
      // Forces a structured response via tool-use instead of freeform
      // text parsing — same intent as Gemini's responseSchema, different
      // mechanism. Claude returns the parsed arguments object directly
      // (content[].input), no JSON.parse of a text blob needed.
      tools: [
        {
          name: "submit_verdict",
          description: "Submit the botanical quality-control verdict for this photo.",
          input_schema: {
            type: "object",
            properties: {
              suggested_candidate_number: { type: "integer" },
              outside_species_id: {
                type: "string",
                description:
                  "Only set when suggested_candidate_number is 0 AND you recognise the plant as a specific OTHER species from the provided database list — its exact id string. Leave unset otherwise.",
              },
              confidence_score: { type: "number" },
              reasoning: { type: "string" },
            },
            required: ["suggested_candidate_number", "confidence_score", "reasoning"],
          },
        },
      ],
      tool_choice: { type: "tool", name: "submit_verdict" },
    }),
  });

  if (!response.ok) {
    const body = await response.text().catch(() => "");
    throw new Error(`claude_request_failed: ${response.status} ${body}`.slice(0, 300));
  }

  const data = await response.json();
  const toolUse = (data?.content as Array<Record<string, unknown>> | undefined)?.find(
    (block) => block.type === "tool_use" && block.name === "submit_verdict",
  );
  const verdict = toolUse?.input as ClaudeVerdict | undefined;
  if (!verdict || typeof verdict.suggested_candidate_number !== "number") {
    throw new Error("claude_response_malformed");
  }
  return verdict;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const body = (await req.json().catch(() => null)) as RequestBody | null;

    // Keep-alive path (see lib/services/edge_function_keep_alive.dart) —
    // answered before any candidate/image validation so a warm-up ping
    // never touches the Claude API or burns any quota.
    if (body?.ping === true) {
      return jsonResponse({ success: true, warm: true });
    }

    if (
      !body ||
      !Array.isArray(body.images) ||
      body.images.length === 0 ||
      body.images.some((img) => typeof img?.data !== "string" || img.data.length === 0) ||
      !Array.isArray(body.candidates) ||
      body.candidates.length === 0
    ) {
      return failure("invalid_request");
    }

    // Optional and defaulted to empty rather than required — an older
    // client build that doesn't send it yet should still work, just
    // without the outside-candidate fallback.
    const allSpecies = Array.isArray(body.all_species) ? body.all_species : [];

    const verdict = await callClaude(
      body.images,
      body.candidates,
      allSpecies,
      body.ood_borderline === true,
    );

    const n = body.candidates.length;
    const pick = Math.trunc(verdict.suggested_candidate_number);
    const confidenceScore = typeof verdict.confidence_score === "number"
      ? verdict.confidence_score
      : 0;
    const reasoning = typeof verdict.reasoning === "string" ? verdict.reasoning : "";

    if (pick === 1) {
      const top = body.candidates[0];
      return jsonResponse({
        success: true,
        agrees_with_local: true,
        replacement_recommended: false,
        is_database_species: true,
        suggested_candidate_number: 1,
        suggested_species_common_name: top.common_name,
        suggested_species_scientific_name: top.scientific_name,
        confidence_score: confidenceScore,
        reasoning,
      });
    }

    if (pick >= 2 && pick <= n) {
      const match = body.candidates[pick - 1];
      return jsonResponse({
        success: true,
        agrees_with_local: false,
        replacement_recommended: true,
        is_database_species: true,
        suggested_candidate_number: pick,
        suggested_species_common_name: match.common_name,
        suggested_species_scientific_name: match.scientific_name,
        confidence_score: confidenceScore,
        reasoning,
      });
    }

    // pick == 0 with a named outside pick — Claude rejected all N numbered
    // candidates but recognised the plant as a DIFFERENT database species.
    // Validated server-side by exact id match against the same all_species
    // list Claude was given (the Dart caller independently re-validates
    // this again against its own species list — defense in depth, not
    // redundant trust, same as the candidate-number path above).
    if (pick === 0 && typeof verdict.outside_species_id === "string" && verdict.outside_species_id.length > 0) {
      const match = allSpecies.find((s) => s.species_id === verdict.outside_species_id);
      if (match) {
        return jsonResponse({
          success: true,
          agrees_with_local: false,
          replacement_recommended: true,
          is_database_species: true,
          suggested_candidate_number: 0,
          suggested_species_id: match.species_id,
          suggested_species_common_name: match.common_name,
          suggested_species_scientific_name: match.scientific_name,
          confidence_score: confidenceScore,
          reasoning,
        });
      }
      // Unmatched id — falls through to the uncertain response below
      // rather than trusting a string that doesn't correspond to any
      // species we actually sent.
    }

    // pick == 0 with no (or unmatched) outside pick, or out of range /
    // malformed — Claude itself is uncertain. Never invents a species
    // outside the provided candidates and full-species lists.
    return jsonResponse({
      success: true,
      agrees_with_local: false,
      replacement_recommended: false,
      is_database_species: false,
      confidence_score: confidenceScore,
      reasoning,
    });
  } catch (err) {
    console.error("background-identify failed:", err);
    return failure(String(err));
  }
});
