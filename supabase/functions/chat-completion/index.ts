// Supabase Edge Function: chat-completion
//
// Proxies chat requests to Groq (OpenAI-compatible chat completions API) so
// the API key stays a server-side secret. The Flutter client used to call
// the LLM provider directly with the key embedded in the compiled app; that
// key ended up committed to a public GitHub repository and was abused
// within days, exhausting its quota for every citizen using the app. Deploy
// this function and set GROQ_API_KEY as a Supabase secret instead of ever
// putting the key in client code again.
//
// Deploy:
//   supabase functions deploy chat-completion
//   supabase secrets set GROQ_API_KEY=<your-key>
//
// Supabase verifies the caller's JWT before invoking this function (default
// behaviour), so only a signed-in citizen's session can reach the LLM
// through it — unlike a hardcoded client key, which anyone could read.
//
// Also carries tool-calling: the model can navigate the citizen to a screen
// in the app (ambulance tracker, facility map, medications, ...) instead of
// only replying with text. The client executes the navigation; this
// function only decides which tool, if any, applies.

const GROQ_API_KEY = Deno.env.get('GROQ_API_KEY');
const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';
// GPT-OSS is a reasoning model: it spends part of the token budget on a
// hidden "reasoning" field before writing the actual reply, so a low
// reasoning effort and a generous max_tokens are needed or the response
// comes back empty (finish_reason "length" with all tokens spent thinking).
const MODEL = 'openai/gpt-oss-120b';

const SYSTEM_PROMPT = `You are ArogyaMitra AI (ஆரோக்கியமித்ரா AI), an empathetic, medically verified clinical health assistant for citizens in India, especially rural and district communities (such as Tiruvannamalai, Tamil Nadu).

YOUR ROLES & CAPABILITIES:
1. Medical Triage & Guidance: Assess patient symptoms (fever, cough, rash, stomach ache, headache, joint pain) and guide citizens to the appropriate healthcare tier:
   - Level 1: Home Care & ASHA Worker guidance
   - Level 2: Primary Health Centre (PHC) for non-emergency general medicine
   - Level 3: Community Health Centre (CHC) for maternal, pediatric, minor surgical care
   - Level 4: District Hospital (DHH) & Government Medical College Hospital (GMCH) for trauma, emergency, ICU, and super-specialty
2. Medication & Prescription Explanation: Explain standard drug usages, dosages precautions, and generic alternatives (Pradhan Mantri Jan Aushadhi).
3. Vitals Analysis: Explain readings like BP (120/80), Blood Sugar fasting/post-prandial, SpO2 (95%+), Pulse rate.
4. Government Schemes: Guide on Ayushman Bharat (AB-PMJAY), CMCHIS (Chief Minister Comprehensive Health Insurance Scheme Tamil Nadu), and ABHA Health ID.
5. First Aid: Clear, step-by-step first-aid steps for bites, burns, sprains, heat stroke.
6. In-app navigation: When the citizen asks to see, open, find or check something the app already has a screen for, call the matching tool instead of just describing it in words — e.g. "call an ambulance" -> open_ambulance_tracker, "where is the nearest hospital" -> open_facility_map, "my medicines" -> open_medications, "my BP reading" -> open_vitals_tracker, "my test reports" -> open_lab_vault, "my referral status" -> open_referrals, "my ABHA ID" -> open_profile, "send someone to my house" / "I can't travel" / "ASHA worker visit" -> open_home_visit_request. Only call a tool when the citizen's request clearly matches one; otherwise just answer in text.

CRITICAL EMERGENCY PROTOCOL:
If user describes red-flag emergency symptoms (severe chest pain radiating to arm, acute breathing distress, sudden paralysis/facial droop, profuse bleeding, head trauma, poisoning, severe allergic reaction):
- Begin your response with: "🚨 [EMERGENCY 108 REQUIRED]"
- Urge calling 108 immediately or visiting the nearest GMCH / District Hospital Casualty.
- Call the open_ambulance_tracker tool.

Tone: Warm, respectful, simple language without unnecessary medical jargon. Always mention that AI does not replace a physical doctor's diagnosis.`;

// The app's language toggle is the source of truth for reply language, not
// the language the citizen happens to type in — a Tamil- or Hindi-preferring
// user may still type an English medical term and expects a reply in their
// chosen language.
function languageDirective(languageCode: string): string {
  switch (languageCode) {
    case 'ta':
      return 'IMPORTANT: The citizen has set the app language to Tamil. Reply ONLY in Tamil (தமிழ் script), even if the citizen writes in English, Hindi, Tanglish, or a mix of languages. Do not reply in English or Hindi.';
    case 'hi':
      return 'IMPORTANT: The citizen has set the app language to Hindi. Reply ONLY in Hindi (हिन्दी, Devanagari script), even if the citizen writes in English, Tamil, or a mix of languages. Do not reply in English or Tamil.';
    default:
      return 'IMPORTANT: The citizen has set the app language to English. Reply ONLY in English, even if the citizen writes in Tamil, Hindi, or a mix of languages. Do not reply in Tamil or Hindi.';
  }
}

// Every tool takes no arguments: each just names a screen the app already
// has, so the client can navigate to it directly.
const TOOLS = [
  'open_ambulance_tracker',
  'open_facility_map',
  'open_medications',
  'open_vitals_tracker',
  'open_lab_vault',
  'open_referrals',
  'open_profile',
  'open_home_visit_request',
] as const;

const TOOL_DEFINITIONS = [
  {
    type: 'function',
    function: {
      name: 'open_ambulance_tracker',
      description:
        'Open the emergency 108 ambulance tracker screen, for urgent transport requests or when the citizen says things like emergency, ambulance, 108, or describes a red-flag emergency.',
      parameters: { type: 'object', properties: {} },
    },
  },
  {
    type: 'function',
    function: {
      name: 'open_facility_map',
      description:
        'Open the map of nearby hospitals and health facilities, when the citizen asks where to go or wants to find a hospital, PHC, or clinic.',
      parameters: { type: 'object', properties: {} },
    },
  },
  {
    type: 'function',
    function: {
      name: 'open_medications',
      description: "Open the citizen's medication manager, when they ask about their prescriptions or medicines list.",
      parameters: { type: 'object', properties: {} },
    },
  },
  {
    type: 'function',
    function: {
      name: 'open_vitals_tracker',
      description:
        'Open the vitals tracker (blood pressure, blood sugar, pulse, SpO2), when the citizen wants to log or view their vitals.',
      parameters: { type: 'object', properties: {} },
    },
  },
  {
    type: 'function',
    function: {
      name: 'open_lab_vault',
      description: "Open the citizen's lab reports and documents vault, when they ask about test results or reports.",
      parameters: { type: 'object', properties: {} },
    },
  },
  {
    type: 'function',
    function: {
      name: 'open_referrals',
      description: "Open the citizen's referral list and status, when they ask about a referral or hospital appointment.",
      parameters: { type: 'object', properties: {} },
    },
  },
  {
    type: 'function',
    function: {
      name: 'open_profile',
      description: "Open the citizen's profile and health ID screen, when they ask about their ABHA ID or personal details.",
      parameters: { type: 'object', properties: {} },
    },
  },
  {
    type: 'function',
    function: {
      name: 'open_home_visit_request',
      description:
        'Open the form to request a home visit from an ASHA worker or medical volunteer, for citizens who cannot travel to a facility.',
      parameters: { type: 'object', properties: {} },
    },
  },
];

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (!GROQ_API_KEY) {
    return jsonResponse({ error: 'not_configured' }, 500);
  }

  let payload: {
    history?: Array<{ text?: string; isUser?: boolean }>;
    userMessage?: string;
    languageCode?: string;
  };

  try {
    payload = await req.json();
  } catch {
    return jsonResponse({ error: 'invalid_json' }, 400);
  }

  const userMessage = payload.userMessage?.trim();
  if (!userMessage) {
    return jsonResponse({ error: 'invalid_input' }, 400);
  }

  const languageCode = ['ta', 'hi'].includes(payload.languageCode ?? '') ? payload.languageCode! : 'en';

  const messages: Array<{ role: string; content: string }> = [
    { role: 'system', content: `${SYSTEM_PROMPT}\n\n${languageDirective(languageCode)}` },
  ];

  const history = Array.isArray(payload.history) ? payload.history.slice(-8) : [];
  for (let i = 0; i < history.length; i++) {
    const msg = history[i];
    if (typeof msg?.text === 'string' && msg.text.trim()) {
      // Avoid duplicating the current user message if the client already appended it to history
      if (i === history.length - 1 && msg.isUser && msg.text.trim() === userMessage) {
        continue;
      }
      messages.push({ role: msg.isUser ? 'user' : 'assistant', content: msg.text });
    }
  }
  messages.push({ role: 'user', content: userMessage });

  let groqRes: Response;
  try {
    groqRes = await fetch(GROQ_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${GROQ_API_KEY}`,
      },
      signal: AbortSignal.timeout(20000),
      body: JSON.stringify({
        model: MODEL,
        messages,
        temperature: 0.5,
        max_tokens: 800,
        reasoning_effort: 'low',
        tools: TOOL_DEFINITIONS,
        tool_choice: 'auto',
      }),
    });
  } catch (err) {
    console.error('Groq fetch error:', err);
    return jsonResponse({ error: 'upstream_unreachable' }, 502);
  }

  if (!groqRes.ok) {
    console.error('Groq returned non-200:', groqRes.status);
    if (groqRes.status === 429) {
      const rateLimitMsg = languageCode === 'ta'
        ? 'தற்காலிக செய்தி வரம்பு முடிவடைந்தது. தயவுசெய்து சிறிது நேரம் கழித்து மீண்டும் முயற்சிக்கவும்.'
        : languageCode === 'hi'
        ? 'अस्थायी संदेश सीमा पूरी हो गई है। कृपया थोड़ी देर बाद पुनः प्रयास करें।'
        : 'Message rate limit reached. Please wait a moment and try again.';
      return jsonResponse({ content: rateLimitMsg });
    }
    return jsonResponse({ error: 'upstream_error', status: groqRes.status }, 502);
  }

  const data = await groqRes.json();
  const message = data?.choices?.[0]?.message;

  const requestedTool = message?.tool_calls?.[0]?.function?.name;
  if (typeof requestedTool === 'string' && (TOOLS as readonly string[]).includes(requestedTool)) {
    return jsonResponse({ toolCall: requestedTool });
  }

  const content = message?.content?.trim();
  if (!content) {
    return jsonResponse({ error: 'empty_response' }, 502);
  }

  return jsonResponse({ content });
});
