#!/bin/bash
set -euo pipefail

# ============================================================================
# CLAWrity Support Script
# Detect mode, generate companion visual, and send support via OpenClaw
# ============================================================================

# --------------------------------------------------------------------------
# Constants
# --------------------------------------------------------------------------
VERSION="0.1.0"
DEFAULT_COMPANION="https://cdn.jsdelivr.net/gh/SudheerNaraharisetty/CLAWrity@main/assets/companion.png"
FAL_API_URL="https://fal.run/xai/grok-imagine-image/edit"
GATEWAY_URL="http://localhost:18789/message"

# --------------------------------------------------------------------------
# Colors & Logging
# --------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[CLAWrity]${NC} $1"; }
log_success() { echo -e "${GREEN}[CLAWrity]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[CLAWrity]${NC} $1"; }
log_error()   { echo -e "${RED}[CLAWrity]${NC} $1" >&2; }

# --------------------------------------------------------------------------
# Usage
# --------------------------------------------------------------------------
usage() {
  echo "CLAWrity Support v${VERSION}"
  echo ""
  echo "Usage: $0 <user_context> <channel> [mode] [caption]"
  echo ""
  echo "Arguments:"
  echo "  user_context    Description of what the user needs (e.g., 'I can't start studying')"
  echo "  channel         Target channel for sending (e.g., '#general', '@username')"
  echo "  mode            Optional. One of: body-double, task-decompose, transition,"
  echo "                  sensory-break, social-script, celebration, auto (default: auto)"
  echo "  caption         Optional. Custom message to accompany the visual"
  echo ""
  echo "Modes:"
  echo "  body-double     Co-working presence for task initiation"
  echo "  task-decompose  Break overwhelming tasks into micro-steps"
  echo "  transition      Help switching between activities"
  echo "  sensory-break   Calming support during sensory overload"
  echo "  social-script   Communication scripts for social situations"
  echo "  celebration     Celebrate completed tasks and wins"
  echo "  auto            Auto-detect mode from user context (default)"
  echo ""
  echo "Environment Variables:"
  echo "  FAL_KEY                    Required. Your fal.ai API key"
  echo "  OPENCLAW_GATEWAY_TOKEN     Optional. Gateway token for direct API calls"
  echo "  CLAWRITY_COMPANION_IMAGE   Optional. Override default companion image URL"
  exit 0
}

# --------------------------------------------------------------------------
# Validate Prerequisites
# --------------------------------------------------------------------------
validate_prereqs() {
  if [ -z "${FAL_KEY:-}" ]; then
    log_error "FAL_KEY environment variable is not set."
    log_error "Get your key at: https://fal.ai/dashboard/keys"
    exit 1
  fi

  if ! command -v curl &> /dev/null; then
    log_error "'curl' is required but not installed."
    exit 1
  fi

  if ! command -v jq &> /dev/null; then
    log_error "'jq' is required but not installed."
    log_error "Install it: https://jqlang.github.io/jq/download/"
    exit 1
  fi
}

# --------------------------------------------------------------------------
# Auto-Detect Mode
# --------------------------------------------------------------------------
detect_mode() {
  local context_lower
  context_lower=$(echo "$1" | tr '[:upper:]' '[:lower:]')

  if echo "$context_lower" | grep -qE "can't start|body double|sit with me|focus|procrastinat|co-work|work with me"; then
    echo "body-double"
  elif echo "$context_lower" | grep -qE "overwhelmed|break it down|too much|simplify|where to start|steps"; then
    echo "task-decompose"
  elif echo "$context_lower" | grep -qE "finished.*next|what's next|switch|move on|perseverat|next task|done.*now"; then
    echo "transition"
  elif echo "$context_lower" | grep -qE "overload|sensory|meltdown|shutdown|calm down|stim|too (loud|bright|much)"; then
    echo "sensory-break"
  elif echo "$context_lower" | grep -qE "how do (i|I) say|respond|email|awkward|phrase|social|reply|text back"; then
    echo "social-script"
  elif echo "$context_lower" | grep -qE "did it|done!|finished!|completed|finally|accomplished|made it"; then
    echo "celebration"
  else
    echo "body-double"
  fi
}

# --------------------------------------------------------------------------
# Build Prompt & Caption
# --------------------------------------------------------------------------
build_prompt_and_caption() {
  local mode="$1"
  local context="$2"
  local custom_caption="${3:-}"

  case "$mode" in
    body-double)
      PROMPT="the companion character sitting at a desk working alongside the viewer, cozy warm lighting, focused but relaxed atmosphere, ${context}, encouraging and supportive presence"
      [ -z "$custom_caption" ] && CAPTION="I'm here with you. Let's work on this together. No pressure, just presence. 💛"
      ;;
    task-decompose)
      PROMPT="a beautifully designed visual task board showing organized steps, clean minimal design, calming colors, ${context}, motivating but not overwhelming, soft rounded edges"
      [ -z "$custom_caption" ] && CAPTION="Here's your task broken into small, manageable pieces. Pick just one to start with — any one counts."
      ;;
    transition)
      PROMPT="a peaceful illustrated pathway or bridge connecting two scenes, ${context}, dreamy soft atmosphere, gentle transition, calming pastels"
      [ -z "$custom_caption" ] && CAPTION="Let's gently move to the next thing. Take a breath first — transitions are hard and that's okay."
      ;;
    sensory-break)
      PROMPT="a serene natural scene, extremely soft lighting, muted gentle colors, no harsh contrasts, peaceful and grounding, minimal visual elements, ${context}"
      [ -z "$custom_caption" ] && CAPTION="Everything can wait. Right now, just breathe. You're safe. 🌿"
      ;;
    social-script)
      PROMPT="a warm supportive illustration of two people having a comfortable conversation, friendly body language, ${context}, approachable and non-threatening atmosphere"
      [ -z "$custom_caption" ] && CAPTION="Here are a few ways you could say that. Pick whichever feels most like you."
      ;;
    celebration)
      PROMPT="the companion character celebrating with confetti and sparkles, joyful radiant energy, bright but not overwhelming colors, ${context}, achievement unlocked feeling, warm congratulatory atmosphere"
      [ -z "$custom_caption" ] && CAPTION="YOU DID IT! 🎉 That took real effort and you showed up for it. I'm genuinely proud of you."
      ;;
    *)
      log_error "Unknown mode: ${mode}"
      exit 1
      ;;
  esac

  [ -n "$custom_caption" ] && CAPTION="$custom_caption"
}

# --------------------------------------------------------------------------
# Generate Visual
# --------------------------------------------------------------------------
generate_visual() {
  local companion_image="${CLAWRITY_COMPANION_IMAGE:-$DEFAULT_COMPANION}"

  log_info "Generating visual with Grok Imagine..."
  log_info "Companion image: $companion_image"

  local json_payload
  json_payload=$(jq -n \
    --arg image_url "$companion_image" \
    --arg prompt "$PROMPT" \
    '{image_url: $image_url, prompt: $prompt, num_images: 1, output_format: "jpeg"}')

  local response
  response=$(curl -s -X POST "$FAL_API_URL" \
    -H "Authorization: Key $FAL_KEY" \
    -H "Content-Type: application/json" \
    -d "$json_payload")

  IMAGE_URL=$(echo "$response" | jq -r '.images[0].url // empty')

  if [ -z "$IMAGE_URL" ]; then
    local error_msg
    error_msg=$(echo "$response" | jq -r '.detail // .error // "Unknown error"')
    log_error "Image generation failed: $error_msg"
    log_error "Full response: $response"
    exit 1
  fi

  log_success "Visual generated: $IMAGE_URL"
}

# --------------------------------------------------------------------------
# Send via OpenClaw
# --------------------------------------------------------------------------
send_to_channel() {
  local channel="$1"

  log_info "Sending to channel: $channel"

  if command -v openclaw &> /dev/null; then
    openclaw message send \
      --action send \
      --channel "$channel" \
      --message "$CAPTION" \
      --media "$IMAGE_URL"
  elif [ -n "${OPENCLAW_GATEWAY_TOKEN:-}" ]; then
    log_warn "openclaw CLI not found, using direct API call"
    local send_payload
    send_payload=$(jq -n \
      --arg channel "$channel" \
      --arg message "$CAPTION" \
      --arg media "$IMAGE_URL" \
      '{action: "send", channel: $channel, message: $message, media: $media}')

    curl -s -X POST "$GATEWAY_URL" \
      -H "Authorization: Bearer $OPENCLAW_GATEWAY_TOKEN" \
      -H "Content-Type: application/json" \
      -d "$send_payload"
  else
    log_error "Neither 'openclaw' CLI nor OPENCLAW_GATEWAY_TOKEN found."
    log_error "Install OpenClaw or set the gateway token."
    exit 1
  fi

  log_success "Sent to $channel ✓"
}

# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------
main() {
  [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && usage

  local user_context="${1:-}"
  local channel="${2:-}"
  local mode="${3:-auto}"
  local custom_caption="${4:-}"

  if [ -z "$user_context" ] || [ -z "$channel" ]; then
    log_error "Missing required arguments."
    echo ""
    usage
  fi

  validate_prereqs

  # Auto-detect mode if needed
  if [ "$mode" = "auto" ]; then
    mode=$(detect_mode "$user_context")
    log_info "Auto-detected mode: $mode"
  fi

  log_info "Mode: $mode"
  build_prompt_and_caption "$mode" "$user_context" "$custom_caption"
  generate_visual
  send_to_channel "$channel"

  log_success "Done! 🦞🧠"

  # Output structured result
  jq -n \
    --arg mode "$mode" \
    --arg image_url "$IMAGE_URL" \
    --arg caption "$CAPTION" \
    --arg channel "$channel" \
    '{mode: $mode, image_url: $image_url, caption: $caption, channel: $channel, status: "sent"}'
}

main "$@"
