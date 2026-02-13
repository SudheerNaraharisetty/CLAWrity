/**
 * CLAWrity Support Script (TypeScript)
 *
 * Detect mode, generate companion visual via fal.ai Grok Imagine,
 * and send supportive messages via OpenClaw.
 *
 * Usage (CLI):
 *   npx ts-node scripts/clawrity.ts <user_context> <channel> [mode] [caption]
 *
 * Usage (Module):
 *   import { supportAndSend, detectMode, buildPrompt } from './clawrity';
 */

import { exec } from "child_process";
import { promisify } from "util";

const execAsync = promisify(exec);

// --------------------------------------------------------------------------
// Types
// --------------------------------------------------------------------------

type SupportMode =
    | "body-double"
    | "task-decompose"
    | "transition"
    | "sensory-break"
    | "social-script"
    | "celebration";

type AutoMode = SupportMode | "auto";

interface GeneratedImage {
    url: string;
    content_type: string;
    width: number;
    height: number;
}

interface FalApiResponse {
    images: GeneratedImage[];
    revised_prompt?: string;
}

interface SupportResult {
    mode: SupportMode;
    imageUrl: string | null;
    caption: string;
    channel: string;
    hasImage: boolean;
    status: "sent" | "generated";
}

interface SupportOptions {
    userContext: string;
    channel: string;
    mode?: AutoMode;
    caption?: string;
    skipSend?: boolean;
}

// --------------------------------------------------------------------------
// Constants
// --------------------------------------------------------------------------

const DEFAULT_COMPANION =
    "https://cdn.jsdelivr.net/gh/SudheerNaraharisetty/CLAWrity@main/assets/companion.png";

const FAL_API_URL = "https://fal.run/xai/grok-imagine-image/edit";

// --------------------------------------------------------------------------
// Mode Detection
// --------------------------------------------------------------------------

const MODE_PATTERNS: Record<SupportMode, RegExp> = {
    "body-double":
        /can't start|body double|sit with me|focus|procrastinat|co-work|work with me/i,
    "task-decompose":
        /overwhelmed|break it down|too much|simplify|where to start|steps/i,
    transition:
        /finished.*next|what's next|switch|move on|perseverat|next task|done.*now/i,
    "sensory-break":
        /overload|sensory|meltdown|shutdown|calm down|stim|too (loud|bright|much)/i,
    "social-script":
        /how do i say|respond|email|awkward|phrase|social|reply|text back/i,
    celebration:
        /did it|done!|finished!|completed|finally|accomplished|made it/i,
};

export function detectMode(userContext: string): SupportMode {
    for (const [mode, regex] of Object.entries(MODE_PATTERNS)) {
        if (regex.test(userContext)) {
            return mode as SupportMode;
        }
    }
    return "body-double"; // default fallback
}

// --------------------------------------------------------------------------
// Prompt Templates
// --------------------------------------------------------------------------

const PROMPT_TEMPLATES: Record<SupportMode, (ctx: string) => string> = {
    "body-double": (ctx) =>
        `the companion character sitting at a desk working alongside the viewer, cozy warm lighting, focused but relaxed atmosphere, ${ctx}, encouraging and supportive presence`,
    "task-decompose": (ctx) =>
        `a beautifully designed visual task board showing organized steps, clean minimal design, calming colors, ${ctx}, motivating but not overwhelming, soft rounded edges`,
    transition: (ctx) =>
        `a peaceful illustrated pathway or bridge connecting two scenes, ${ctx}, dreamy soft atmosphere, gentle transition, calming pastels`,
    "sensory-break": (ctx) =>
        `a serene natural scene, extremely soft lighting, muted gentle colors, no harsh contrasts, peaceful and grounding, minimal visual elements, ${ctx}`,
    "social-script": (ctx) =>
        `a warm supportive illustration of two people having a comfortable conversation, friendly body language, ${ctx}, approachable and non-threatening atmosphere`,
    celebration: (ctx) =>
        `the companion character celebrating with confetti and sparkles, joyful radiant energy, bright but not overwhelming colors, ${ctx}, achievement unlocked feeling, warm congratulatory atmosphere`,
};

export function buildPrompt(
    userContext: string,
    mode: SupportMode
): string {
    return PROMPT_TEMPLATES[mode](userContext);
}

// --------------------------------------------------------------------------
// Default Captions
// --------------------------------------------------------------------------

const DEFAULT_CAPTIONS: Record<SupportMode, string> = {
    "body-double":
        "I'm here with you. Let's work on this together. No pressure, just presence. 💛",
    "task-decompose":
        "Here's your task broken into small, manageable pieces. Pick just one to start with — any one counts.",
    transition:
        "Let's gently move to the next thing. Take a breath first — transitions are hard and that's okay.",
    "sensory-break":
        "Everything can wait. Right now, just breathe. You're safe. 🌿",
    "social-script":
        "Here are a few ways you could say that. Pick whichever feels most like you.",
    celebration:
        "YOU DID IT! 🎉 That took real effort and you showed up for it. I'm genuinely proud of you.",
};

export function getCaption(mode: SupportMode): string {
    return DEFAULT_CAPTIONS[mode];
}

// --------------------------------------------------------------------------
// Image Generation
// --------------------------------------------------------------------------

async function generateVisual(
    prompt: string,
    companionImage: string
): Promise<string | null> {
    const falKey = process.env.FAL_KEY;
    if (!falKey) {
        console.log(
            "[CLAWrity] FAL_KEY not set — running in text-only mode (no image generation)"
        );
        console.log(
            "[CLAWrity] Get a key at: https://fal.ai/dashboard/keys to enable visuals"
        );
        return null;
    }

    // Try using @fal-ai/client first, fall back to fetch
    try {
        // @ts-ignore — optional dependency, falls back to fetch below
        const { fal } = await import("@fal-ai/client");
        fal.config({ credentials: falKey });

        const result = await fal.subscribe("xai/grok-imagine-image/edit", {
            input: {
                image_url: companionImage,
                prompt,
                num_images: 1,
                output_format: "jpeg",
            },
        });

        const data = result.data as FalApiResponse;
        if (!data.images?.[0]?.url) {
            throw new Error("No image URL in fal.ai response");
        }
        return data.images[0].url;
    } catch (importError) {
        // Fallback to direct fetch
        console.log("[CLAWrity] @fal-ai/client not available, using fetch fallback");

        const response = await fetch(FAL_API_URL, {
            method: "POST",
            headers: {
                Authorization: `Key ${falKey}`,
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                image_url: companionImage,
                prompt,
                num_images: 1,
                output_format: "jpeg",
            }),
        });

        if (!response.ok) {
            const errorText = await response.text();
            throw new Error(`fal.ai API error (${response.status}): ${errorText}`);
        }

        const data = (await response.json()) as FalApiResponse;
        if (!data.images?.[0]?.url) {
            throw new Error("No image URL in fal.ai response");
        }
        return data.images[0].url;
    }
}

// --------------------------------------------------------------------------
// Send via OpenClaw
// --------------------------------------------------------------------------

async function sendViaOpenClaw(
    channel: string,
    message: string,
    mediaUrl: string | null
): Promise<void> {
    try {
        const mediaFlag = mediaUrl ? ` --media "${mediaUrl}"` : "";
        await execAsync(
            `openclaw message send --action send --channel "${channel}" --message "${message.replace(/"/g, '\\"')}"${mediaFlag}`
        );
    } catch {
        // Fallback to direct gateway API
        const gatewayToken = process.env.OPENCLAW_GATEWAY_TOKEN;
        if (!gatewayToken) {
            throw new Error(
                "openclaw CLI not available and OPENCLAW_GATEWAY_TOKEN not set"
            );
        }

        console.log("[CLAWrity] openclaw CLI not found, using direct API call");

        const payload: Record<string, string> = {
            action: "send",
            channel,
            message,
        };
        if (mediaUrl) payload.media = mediaUrl;

        const response = await fetch("http://localhost:18789/message", {
            method: "POST",
            headers: {
                Authorization: `Bearer ${gatewayToken}`,
                "Content-Type": "application/json",
            },
            body: JSON.stringify(payload),
        });

        if (!response.ok) {
            const errorText = await response.text();
            throw new Error(
                `OpenClaw Gateway error (${response.status}): ${errorText}`
            );
        }
    }
}

// --------------------------------------------------------------------------
// Main Export
// --------------------------------------------------------------------------

export async function supportAndSend(
    options: SupportOptions
): Promise<SupportResult> {
    const {
        userContext,
        channel,
        mode: requestedMode = "auto",
        caption: customCaption,
        skipSend = false,
    } = options;

    const companionImage =
        process.env.CLAWRITY_COMPANION_IMAGE || DEFAULT_COMPANION;

    // Resolve mode
    const mode: SupportMode =
        requestedMode === "auto" ? detectMode(userContext) : requestedMode;

    console.log(`[CLAWrity] Mode: ${mode}`);

    // Build prompt and generate visual (if FAL_KEY is set)
    const prompt = buildPrompt(userContext, mode);
    const imageUrl = await generateVisual(prompt, companionImage);

    if (imageUrl) {
        console.log(`[CLAWrity] Visual generated: ${imageUrl}`);
    }

    // Get caption
    const caption = customCaption || getCaption(mode);

    // Send via OpenClaw
    if (!skipSend) {
        console.log(`[CLAWrity] Sending to ${channel}...`);
        await sendViaOpenClaw(channel, caption, imageUrl);
        console.log(`[CLAWrity] Sent ✓`);
    }

    return {
        mode,
        imageUrl,
        caption,
        channel,
        hasImage: imageUrl !== null,
        status: skipSend ? "generated" : "sent",
    };
}

// --------------------------------------------------------------------------
// CLI Entry Point
// --------------------------------------------------------------------------

if (require.main === module) {
    const [, , userContext, channel, mode, caption] = process.argv;

    if (!userContext || !channel) {
        console.log("CLAWrity Support v0.1.0\n");
        console.log("Usage: npx ts-node scripts/clawrity.ts <user_context> <channel> [mode] [caption]\n");
        console.log("Modes: body-double, task-decompose, transition, sensory-break, social-script, celebration, auto\n");
        process.exit(0);
    }

    supportAndSend({
        userContext,
        channel,
        mode: (mode as AutoMode) || "auto",
        caption,
    })
        .then((result) => {
            console.log(JSON.stringify(result, null, 2));
        })
        .catch((error) => {
            console.error(`[CLAWrity] Error: ${error.message}`);
            process.exit(1);
        });
}
