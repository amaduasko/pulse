// Pulse AI coach: Cloudflare Pages Function backed by Workers AI.
// POST /api/coach  { mode: "plan", profile } -> { plan }
//                  { mode: "chat", profile, messages } -> { reply }
const MODEL = "@cf/meta/llama-3.3-70b-instruct-fp8-fast";
const GOALS = ["lose_weight", "build_muscle", "stay_active", "endurance"];
const LEVELS = ["beginner", "intermediate", "advanced"];
const EQUIP = ["none", "dumbbells", "gym"];

const json = (body, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json", "cache-control": "no-store" },
  });

function cleanProfile(p = {}) {
  const pick = (v, list, d) => (list.includes(v) ? v : d);
  const minutes = Math.min(90, Math.max(10, Number(p.minutes) || 30));
  return {
    goal: pick(p.goal, GOALS, "stay_active"),
    level: pick(p.level, LEVELS, "beginner"),
    equipment: pick(p.equipment, EQUIP, "none"),
    minutes,
  };
}

function profileText(p) {
  return `Goal: ${p.goal.replace("_", " ")}. Level: ${p.level}. Equipment: ${p.equipment}. Session length: ${p.minutes} minutes.`;
}

function extractJson(text) {
  if (typeof text === "object" && text) return text;
  const s = String(text || "");
  const a = s.indexOf("{"), b = s.lastIndexOf("}");
  if (a < 0 || b <= a) throw new Error("no json");
  return JSON.parse(s.slice(a, b + 1));
}

function validPlan(raw) {
  const ex = Array.isArray(raw?.exercises) ? raw.exercises : [];
  const exercises = ex
    .map((e) => ({
      name: String(e?.name || "").slice(0, 60).trim(),
      sets: Math.min(10, Math.max(1, parseInt(e?.sets) || 3)),
      reps: String(e?.reps ?? "10").slice(0, 20).trim() || "10",
      restSeconds: Math.min(300, Math.max(0, parseInt(e?.restSeconds) || 45)),
      tip: String(e?.tip || "").slice(0, 140).trim(),
    }))
    .filter((e) => e.name)
    .slice(0, 8);
  if (exercises.length < 3) throw new Error("plan too short");
  return {
    title: String(raw?.title || "Today's workout").slice(0, 60),
    summary: String(raw?.summary || "").slice(0, 200),
    exercises,
  };
}

async function makePlan(env, profile) {
  const out = await env.AI.run(MODEL, {
    messages: [
      {
        role: "system",
        content:
          "You are a certified personal trainer. Reply with JSON only, no prose: " +
          '{"title": string (max 5 words), "summary": string (one sentence), "exercises": ' +
          '[{"name": string, "sets": integer, "reps": string like "12" or "30 s", "restSeconds": integer, "tip": string (one short form cue)}]}. ' +
          "Use 5 to 7 safe exercises that fit the equipment and the session length.",
      },
      { role: "user", content: profileText(profile) },
    ],
    max_tokens: 900,
    temperature: 0.7,
  });
  return validPlan(extractJson(out?.response));
}

async function chat(env, profile, messages) {
  const history = (Array.isArray(messages) ? messages : [])
    .filter((m) => m && (m.role === "user" || m.role === "assistant"))
    .slice(-10)
    .map((m) => ({ role: m.role, content: String(m.content || "").slice(0, 1000) }));
  if (!history.length || history[history.length - 1].role !== "user") throw Object.assign(new Error("Send at least one user message"), { status: 400 });
  const out = await env.AI.run(MODEL, {
    messages: [
      {
        role: "system",
        content:
          "You are Pulse, a friendly fitness and nutrition coach in a mobile app. " +
          "Answer in the user's language, in at most 120 words, practical and specific. " +
          "No medical diagnosis: for pain, injury or a health condition, advise seeing a doctor. " +
          "User profile: " + profileText(profile),
      },
      ...history,
    ],
    max_tokens: 400,
    temperature: 0.6,
  });
  const reply = String(out?.response || "").trim();
  if (!reply) throw new Error("empty reply");
  return reply;
}

export async function onRequestPost({ request, env }) {
  let body;
  try {
    const text = await request.text();
    if (text.length > 20000) return json({ error: "Request too large" }, 413);
    body = JSON.parse(text);
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }
  const profile = cleanProfile(body.profile);
  try {
    if (body.mode === "plan") return json({ plan: await makePlan(env, profile) });
    if (body.mode === "chat") return json({ reply: await chat(env, profile, body.messages) });
    return json({ error: "Unknown mode" }, 400);
  } catch (e) {
    if (e.status === 400) return json({ error: e.message }, 400);
    return json({ error: "The coach is unavailable right now." }, 502);
  }
}

export const onRequest = () => json({ error: "Method not allowed" }, 405);
