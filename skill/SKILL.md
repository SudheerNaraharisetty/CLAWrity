---
name: clawrity
description: Neurodivergent-friendly companion providing body doubling, task decomposition, transition support, sensory regulation, social scripting, and celebration via OpenClaw
allowed-tools: Bash(npm:*) Bash(npx:*) Bash(openclaw:*) Bash(curl:*) Read Write WebFetch
---

# CLAWrity

A neurodivergent-friendly companion skill for OpenClaw. CLAWrity provides six support modes for individuals with ADHD, Autism, or both (AuDHD): body doubling, task decomposition, transition assistance, sensory regulation, social scripting, and celebration.

## Reference Image

The skill uses a default companion reference image hosted on jsDelivr CDN:

```
https://cdn.jsdelivr.net/gh/SudheerNaraharisetty/CLAWrity@main/assets/companion.png
```

Users may override this with their own image via `openclaw.json`:
```json
{
  "skills": {
    "entries": {
      "clawrity": {
        "env": {
          "CLAWRITY_COMPANION_IMAGE": "https://your-custom-image-url.png"
        }
      }
    }
  }
}
```

## When to Use

### Body Double Mode
- User says "I can't start", "body double me", "sit with me", "stay with me"
- User says "I keep getting distracted", "help me focus", "I'm procrastinating"
- User describes task avoidance or inability to begin work
- User says "work with me", "be here with me", "co-work"

### Task Decomposition Mode
- User says "I'm overwhelmed", "I don't know where to start"
- User says "break it down", "make it smaller", "too much", "simplify this"
- User describes a large or complex task they're struggling with
- User says "I have to do [big task] and I can't even think about it"

### Transition Mode
- User says "I finished [task]", "what's next", "help me switch"
- User says "I'm stuck between tasks", "I can't switch gears"
- User says "I need to move on but I can't", "I'm perseverating"
- User needs help shifting from one activity to another

### Sensory Break Mode
- User says "I'm overloaded", "sensory overload", "I need a break"
- User says "meltdown", "shutdown", "too much noise/light/people"
- User says "I need to stim", "help me calm down", "everything is too much"
- User expresses acute distress or overstimulation

### Social Script Mode
- User says "how do I say", "help me respond to", "help me email"
- User says "awkward situation", "I don't know what to say"
- User describes a social interaction they need help navigating
- User says "write a reply for me", "how should I phrase this"

### Celebration Mode
- User says "I did it!", "done!", "finished!", "I completed it"
- User reports completing a task or reaching a milestone
- User says "I finally [did something]", "it's done!"
- Any expression of task completion or achievement

## Quick Reference

### Environment Variables
```bash
FAL_KEY=your_fal_api_key                    # Optional: Get from https://fal.ai/dashboard/keys (text-only mode if not set)
OPENCLAW_GATEWAY_TOKEN=your_token            # From: openclaw doctor --generate-gateway-token
CLAWRITY_COMPANION_IMAGE=custom_url          # Optional: override default companion image
```

### Workflow
1. **Detect mode** from user message keywords
2. **Build prompt** using mode-specific template + user context
3. **Generate visual** via fal.ai Grok Imagine Edit API with companion reference
4. **Compose message** with supportive text tailored to the mode
5. **Send to OpenClaw** with target channel(s)

## Mode Detection Logic

| Keywords in Request | Auto-Select Mode |
|---------------------|------------------|
| can't start, body double, sit with me, focus, procrastinating, co-work | `body-double` |
| overwhelmed, break it down, too much, simplify, where to start | `task-decompose` |
| finished, what's next, switch, move on, perseverating, next task | `transition` |
| overloaded, sensory, meltdown, shutdown, calm down, break, stim | `sensory-break` |
| how do I say, respond, email, awkward, phrase, social, reply | `social-script` |
| did it, done, finished, completed, finally, accomplished | `celebration` |

## Step-by-Step Instructions

### Step 1: Collect User Input

Parse the user's message to determine:
- **Mode**: Which of the 6 modes to activate (auto-detect from keywords above)
- **User context**: The specific situation, task, or emotion described
- **Energy level** (optional): Detect from language — short/terse = low energy, enthusiastic = high energy
- **Target channel(s)**: Where to send the visual (e.g., `#general`, `@username`, channel ID)
- **Platform** (optional): Which platform? (discord, telegram, whatsapp, slack)

### Step 2: Build Prompt

Use the mode-specific prompt template, filling in the user's context.

## Visual Generation Prompts

### Mode 1: Body Double (Working Together)

Best for: co-working scenes, focused work environments, companionship during tasks

```
the companion character sitting at a desk working alongside the viewer, cozy warm lighting, focused but relaxed atmosphere, <USER_CONTEXT>, encouraging and supportive presence
```

**Example**: User says "body double me while I study" →
```
the companion character sitting at a desk working alongside the viewer, cozy warm lighting, focused but relaxed atmosphere, studying together with books and notes, encouraging and supportive presence
```

### Mode 2: Task Decomposition (Visual Task Card)

Best for: checklist visuals, organized breakdown images, structured planning scenes

```
a beautifully designed visual task board showing organized steps, clean minimal design, calming colors, <TASK_ITEMS_VISUAL>, motivating but not overwhelming, soft rounded edges
```

**Example**: User says "I need to clean my apartment" →
```
a beautifully designed visual task board showing organized steps, clean minimal design, calming colors, apartment cleaning broken into small friendly steps, motivating but not overwhelming, soft rounded edges
```

### Mode 3: Transition (Bridge Scene)

Best for: visual metaphors for change, pathway imagery, gentle movement scenes

```
a peaceful illustrated pathway or bridge connecting two scenes, the left side shows <PREVIOUS_ACTIVITY>, the right side shows <NEXT_ACTIVITY>, dreamy soft atmosphere, gentle transition, calming pastels
```

**Example**: User finished studying, needs to start cooking →
```
a peaceful illustrated pathway or bridge connecting two scenes, the left side shows a cozy study desk with books, the right side shows a warm inviting kitchen, dreamy soft atmosphere, gentle transition, calming pastels
```

### Mode 4: Sensory Break (Calming Scene)

Best for: nature scenes, minimal sensory input, grounding imagery

```
a serene <USER_CALM_PREFERENCE> scene, extremely soft lighting, muted gentle colors, no harsh contrasts, peaceful and grounding, minimal visual elements, <SENSORY_SAFE_DESCRIPTORS>
```

**Example**: User says "sensory overload, I need nature" →
```
a serene forest clearing scene, extremely soft lighting, muted gentle colors, no harsh contrasts, peaceful and grounding, minimal visual elements, soft moss, gentle stream, dappled sunlight through leaves
```

### Mode 5: Social Script (Communication Helper)

For social script mode, visual generation is **optional**. The primary output is text-based communication scripts. If a visual is requested:

```
a warm supportive illustration of two people having a comfortable conversation, friendly body language, speech bubbles with gentle text, <SOCIAL_CONTEXT>, approachable and non-threatening atmosphere
```

### Mode 6: Celebration (Reward Scene)

Best for: achievement imagery, joyful scenes, positive reinforcement

```
the companion character celebrating with <USER_REWARD_PREFERENCE>, joyful radiant energy, bright but not overwhelming colors, confetti and sparkles, achievement unlocked feeling, warm congratulatory atmosphere
```

**Example**: User says "I finally submitted my assignment!" →
```
the companion character celebrating with confetti and a golden star, joyful radiant energy, bright but not overwhelming colors, confetti and sparkles, achievement unlocked feeling, warm congratulatory atmosphere
```

### Prompt Selection Logic

| Keywords in User Context | Auto-Select Prompt |
|--------------------------|-------------------|
| can't start, body double, focus, work with me | Body Double prompt |
| overwhelmed, break it down, too much, simplify | Task Decomposition prompt |
| finished, what's next, switch tasks, move on | Transition prompt |
| overloaded, sensory, meltdown, calm down, break | Sensory Break prompt |
| how do I say, respond, email, social | Social Script (text-primary) |
| did it, done, finished, accomplished | Celebration prompt |

### Step 3: Generate Visual with Grok Imagine

Use the fal.ai API to edit the companion reference image:

```bash
COMPANION_IMAGE="${CLAWRITY_COMPANION_IMAGE:-https://cdn.jsdelivr.net/gh/SudheerNaraharisetty/CLAWrity@main/assets/companion.png}"

# Build JSON payload with jq (handles escaping properly)
JSON_PAYLOAD=$(jq -n \
  --arg image_url "$COMPANION_IMAGE" \
  --arg prompt "$PROMPT" \
  '{image_url: $image_url, prompt: $prompt, num_images: 1, output_format: "jpeg"}')

curl -X POST "https://fal.run/xai/grok-imagine-image/edit" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD"
```

**Response Format:**
```json
{
  "images": [
    {
      "url": "https://v3b.fal.media/files/...",
      "content_type": "image/jpeg",
      "width": 1024,
      "height": 1024
    }
  ],
  "revised_prompt": "Enhanced prompt text..."
}
```

### Step 4: Compose Supportive Message

Based on the detected mode, compose an accompanying text message:

- **Body Double**: "I'm here with you. Let's work on this together. No pressure, just presence. 💛"
- **Task Decomposition**: "Here's your task broken into small, manageable pieces. Pick just one to start with — any one counts."
- **Transition**: "You did great with [previous]. Let's gently move to [next]. Take a breath first — transitions are hard and that's okay."
- **Sensory Break**: "Everything can wait. Right now, just breathe. You're safe. Here's something calming for you. 🌿"
- **Social Script**: "Here are a few ways you could say that. Pick whichever feels most like you — or mix and match."
- **Celebration**: "YOU DID IT! 🎉 That took real effort and you showed up for it. I'm genuinely proud of you."

### Step 5: Send via OpenClaw

Use the OpenClaw messaging API to send the generated visual and supportive message:

```bash
openclaw message send \
  --action send \
  --channel "<TARGET_CHANNEL>" \
  --message "<SUPPORTIVE_MESSAGE>" \
  --media "<IMAGE_URL>"
```

**Alternative: Direct API call**
```bash
curl -X POST "http://localhost:18789/message" \
  -H "Authorization: Bearer $OPENCLAW_GATEWAY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "send",
    "channel": "<TARGET_CHANNEL>",
    "message": "<SUPPORTIVE_MESSAGE>",
    "media": "<IMAGE_URL>"
  }'
```

## Complete Script Example

```bash
#!/bin/bash
# clawrity-support.sh
# Detect mode, generate companion visual, and send support via OpenClaw

if [ -z "$FAL_KEY" ]; then
  echo "[CLAWrity] FAL_KEY not set — running in text-only mode (no image generation)"
  IMAGE_GENERATION=false
else
  IMAGE_GENERATION=true
fi

COMPANION_IMAGE="${CLAWRITY_COMPANION_IMAGE:-https://cdn.jsdelivr.net/gh/SudheerNaraharisetty/CLAWrity@main/assets/companion.png}"

USER_CONTEXT="$1"
CHANNEL="$2"
MODE="${3:-auto}"
CAPTION="${4:-}"

if [ -z "$USER_CONTEXT" ] || [ -z "$CHANNEL" ]; then
  echo "Usage: $0 <user_context> <channel> [mode] [caption]"
  echo "Modes: body-double, task-decompose, transition, sensory-break, social-script, celebration, auto"
  exit 1
fi

# Auto-detect mode
if [ "$MODE" == "auto" ]; then
  if echo "$USER_CONTEXT" | grep -qiE "can't start|body double|sit with me|focus|procrastinat|co-work"; then
    MODE="body-double"
  elif echo "$USER_CONTEXT" | grep -qiE "overwhelmed|break it down|too much|simplify|where to start"; then
    MODE="task-decompose"
  elif echo "$USER_CONTEXT" | grep -qiE "finished|what's next|switch|move on|perseverat|next task"; then
    MODE="transition"
  elif echo "$USER_CONTEXT" | grep -qiE "overload|sensory|meltdown|shutdown|calm down|stim|break"; then
    MODE="sensory-break"
  elif echo "$USER_CONTEXT" | grep -qiE "how do I say|respond|email|awkward|phrase|social|reply"; then
    MODE="social-script"
  elif echo "$USER_CONTEXT" | grep -qiE "did it|done|finished|completed|finally|accomplished"; then
    MODE="celebration"
  else
    MODE="body-double"  # default fallback
  fi
  echo "Auto-detected mode: $MODE"
fi

# Build prompt based on mode
case "$MODE" in
  body-double)
    EDIT_PROMPT="the companion character sitting at a desk working alongside the viewer, cozy warm lighting, focused but relaxed atmosphere, $USER_CONTEXT, encouraging and supportive presence"
    [ -z "$CAPTION" ] && CAPTION="I'm here with you. Let's work on this together. No pressure, just presence. 💛"
    ;;
  task-decompose)
    EDIT_PROMPT="a beautifully designed visual task board showing organized steps, clean minimal design, calming colors, $USER_CONTEXT, motivating but not overwhelming, soft rounded edges"
    [ -z "$CAPTION" ] && CAPTION="Here's your task broken into small, manageable pieces. Pick just one to start with."
    ;;
  transition)
    EDIT_PROMPT="a peaceful illustrated pathway or bridge connecting two scenes, $USER_CONTEXT, dreamy soft atmosphere, gentle transition, calming pastels"
    [ -z "$CAPTION" ] && CAPTION="Let's gently move to the next thing. Take a breath first — transitions are hard and that's okay."
    ;;
  sensory-break)
    EDIT_PROMPT="a serene natural scene, extremely soft lighting, muted gentle colors, no harsh contrasts, peaceful and grounding, minimal visual elements, $USER_CONTEXT"
    [ -z "$CAPTION" ] && CAPTION="Everything can wait. Right now, just breathe. You're safe. 🌿"
    ;;
  social-script)
    EDIT_PROMPT="a warm supportive illustration of two people having a comfortable conversation, friendly body language, $USER_CONTEXT, approachable and non-threatening atmosphere"
    [ -z "$CAPTION" ] && CAPTION="Here are a few ways you could say that. Pick whichever feels most like you."
    ;;
  celebration)
    EDIT_PROMPT="the companion character celebrating with confetti and sparkles, joyful radiant energy, bright but not overwhelming colors, $USER_CONTEXT, achievement unlocked feeling, warm congratulatory atmosphere"
    [ -z "$CAPTION" ] && CAPTION="YOU DID IT! 🎉 That took real effort and you showed up for it. I'm proud of you."
    ;;
esac

echo "Mode: $MODE"
echo "Editing companion image with prompt: $EDIT_PROMPT"

# Generate visual via fal.ai (only if FAL_KEY is set)
if [ "$IMAGE_GENERATION" = true ]; then
  JSON_PAYLOAD=$(jq -n \
    --arg image_url "$COMPANION_IMAGE" \
    --arg prompt "$EDIT_PROMPT" \
    '{image_url: $image_url, prompt: $prompt, num_images: 1, output_format: "jpeg"}')

  RESPONSE=$(curl -s -X POST "https://fal.run/xai/grok-imagine-image/edit" \
    -H "Authorization: Key $FAL_KEY" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD")

  IMAGE_URL=$(echo "$RESPONSE" | jq -r '.images[0].url')

  if [ "$IMAGE_URL" == "null" ] || [ -z "$IMAGE_URL" ]; then
    echo "Error: Failed to generate image"
    echo "Response: $RESPONSE"
    exit 1
  fi

  echo "Image generated: $IMAGE_URL"
else
  IMAGE_URL=""
  echo "Skipping image generation (text-only mode)"
fi

echo "Sending to channel: $CHANNEL"

# Send via OpenClaw
if [ -n "$IMAGE_URL" ]; then
  openclaw message send \
    --action send \
    --channel "$CHANNEL" \
    --message "$CAPTION" \
    --media "$IMAGE_URL"
else
  openclaw message send \
    --action send \
    --channel "$CHANNEL" \
    --message "$CAPTION"
fi

echo "Done!"
```

## Node.js/TypeScript Implementation

```typescript
import { fal } from "@fal-ai/client";
import { exec } from "child_process";
import { promisify } from "util";

const execAsync = promisify(exec);

const DEFAULT_COMPANION =
  "https://cdn.jsdelivr.net/gh/SudheerNaraharisetty/CLAWrity@main/assets/companion.png";

type SupportMode =
  | "body-double"
  | "task-decompose"
  | "transition"
  | "sensory-break"
  | "social-script"
  | "celebration"
  | "auto";

function detectMode(userContext: string): Exclude<SupportMode, "auto"> {
  const patterns: Record<Exclude<SupportMode, "auto">, RegExp> = {
    "body-double":
      /can't start|body double|sit with me|focus|procrastinat|co-work/i,
    "task-decompose":
      /overwhelmed|break it down|too much|simplify|where to start/i,
    transition:
      /finished|what's next|switch|move on|perseverat|next task/i,
    "sensory-break":
      /overload|sensory|meltdown|shutdown|calm down|stim|break/i,
    "social-script":
      /how do I say|respond|email|awkward|phrase|social|reply/i,
    celebration:
      /did it|done|finished|completed|finally|accomplished/i,
  };

  for (const [mode, regex] of Object.entries(patterns)) {
    if (regex.test(userContext)) return mode as Exclude<SupportMode, "auto">;
  }
  return "body-double"; // default
}

function buildPrompt(
  userContext: string,
  mode: Exclude<SupportMode, "auto">
): string {
  const templates: Record<Exclude<SupportMode, "auto">, string> = {
    "body-double": `the companion character sitting at a desk working alongside the viewer, cozy warm lighting, focused but relaxed atmosphere, ${userContext}, encouraging and supportive presence`,
    "task-decompose": `a beautifully designed visual task board showing organized steps, clean minimal design, calming colors, ${userContext}, motivating but not overwhelming, soft rounded edges`,
    transition: `a peaceful illustrated pathway or bridge connecting two scenes, ${userContext}, dreamy soft atmosphere, gentle transition, calming pastels`,
    "sensory-break": `a serene natural scene, extremely soft lighting, muted gentle colors, no harsh contrasts, peaceful and grounding, minimal visual elements, ${userContext}`,
    "social-script": `a warm supportive illustration of two people having a comfortable conversation, friendly body language, ${userContext}, approachable and non-threatening atmosphere`,
    celebration: `the companion character celebrating with confetti and sparkles, joyful radiant energy, bright but not overwhelming colors, ${userContext}, achievement unlocked feeling, warm congratulatory atmosphere`,
  };

  return templates[mode];
}

function getDefaultCaption(mode: Exclude<SupportMode, "auto">): string {
  const captions: Record<Exclude<SupportMode, "auto">, string> = {
    "body-double":
      "I'm here with you. Let's work on this together. No pressure, just presence. 💛",
    "task-decompose":
      "Here's your task broken into small, manageable pieces. Pick just one to start with.",
    transition:
      "Let's gently move to the next thing. Take a breath first — transitions are hard and that's okay.",
    "sensory-break":
      "Everything can wait. Right now, just breathe. You're safe. 🌿",
    "social-script":
      "Here are a few ways you could say that. Pick whichever feels most like you.",
    celebration:
      "YOU DID IT! 🎉 That took real effort and you showed up for it. I'm proud of you.",
  };

  return captions[mode];
}

async function supportAndSend(
  userContext: string,
  channel: string,
  mode: SupportMode = "auto",
  caption?: string
): Promise<string> {
  fal.config({ credentials: process.env.FAL_KEY! });

  const companionImage =
    process.env.CLAWRITY_COMPANION_IMAGE || DEFAULT_COMPANION;
  const resolvedMode = mode === "auto" ? detectMode(userContext) : mode;

  console.log(`Mode: ${resolvedMode}`);

  const editPrompt = buildPrompt(userContext, resolvedMode);
  console.log(`Generating visual: "${editPrompt}"`);

  const result = await fal.subscribe("xai/grok-imagine-image/edit", {
    input: {
      image_url: companionImage,
      prompt: editPrompt,
      num_images: 1,
      output_format: "jpeg",
    },
  });

  const imageUrl = (result.data as any).images[0].url;
  console.log(`Image generated: ${imageUrl}`);

  const message = caption || getDefaultCaption(resolvedMode);

  await execAsync(
    `openclaw message send --action send --channel "${channel}" --message "${message}" --media "${imageUrl}"`
  );

  console.log(`Sent to ${channel}`);
  return imageUrl;
}
```

## Supported Platforms

OpenClaw supports sending to:

| Platform | Channel Format | Example |
|----------|----------------|---------|
| Discord | `#channel-name` or channel ID | `#general`, `123456789` |
| Telegram | `@username` or chat ID | `@mychannel`, `-100123456` |
| WhatsApp | Phone number (JID format) | `1234567890@s.whatsapp.net` |
| Slack | `#channel-name` | `#random` |
| Signal | Phone number | `+1234567890` |
| MS Teams | Channel reference | (varies) |

## Grok Imagine Edit Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `image_url` | string | required | URL of companion reference image |
| `prompt` | string | required | Mode-specific generation instruction |
| `num_images` | 1-4 | 1 | Number of images to generate |
| `output_format` | enum | "jpeg" | jpeg, png, webp |

## Setup Requirements

### 1. Install fal.ai client (for Node.js usage)
```bash
npm install @fal-ai/client
```

### 2. Install OpenClaw CLI
```bash
npm install -g openclaw
```

### 3. Configure OpenClaw Gateway
```bash
openclaw config set gateway.mode=local
openclaw doctor --generate-gateway-token
```

### 4. Start OpenClaw Gateway
```bash
openclaw gateway start
```

## Error Handling

- **FAL_KEY missing**: CLAWrity runs in text-only mode (no image generation) — set the key in `openclaw.json` to enable visuals
- **Image generation failed**: Check prompt content and fal.ai API quota
- **OpenClaw send failed**: Verify gateway is running (`openclaw gateway start`) and channel exists
- **Rate limits**: fal.ai has rate limits; the agent should implement retry logic if needed
- **Mode detection missed**: Falls back to body-double mode if no keywords match

## Tips

1. **Body Double examples**: "sit with me while I write", "co-work session", "I can't start this email"
2. **Task Decomposition examples**: "I need to clean my whole apartment", "I have a 10-page paper due", "too many things to do"
3. **Transition examples**: "I finished studying, now I need to cook", "done with work, can't switch to relaxing"
4. **Sensory Break examples**: "the noise is too much", "everything feels too bright", "I need to decompress"
5. **Social Script examples**: "how do I tell my boss I need a day off", "help me respond to this text", "awkward email to write"
6. **Celebration examples**: "I submitted my application!", "finally cleaned my room", "I actually made the phone call!"
7. **Energy detection**: Short, lowercase, no punctuation = low energy → use minimal, gentle responses
8. **Batch support**: Generate visual once, send to multiple channels if needed
