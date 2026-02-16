#!/bin/bash
set -euo pipefail

# ============================================================================
# CLAWrity Support Script v0.1.3
# Dynamic companion responses, smart detection, memory integration
# ============================================================================

# --------------------------------------------------------------------------
# Constants
# --------------------------------------------------------------------------
VERSION="0.1.3"
DEFAULT_COMPANION="https://cdn.jsdelivr.net/gh/SudheerNaraharisetty/CLAWrity@main/assets/companion.png"
FAL_API_URL="https://fal.run/xai/grok-imagine-image/edit"
GATEWAY_URL="http://localhost:18789/message"
MEMORY_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}/memory"
TEMP_DIR="${TMPDIR:-/tmp}/clawrity"

# --------------------------------------------------------------------------
# Dynamic Response Pools (10+ variations per mode)
# --------------------------------------------------------------------------
BODY_DOUBLE_RESPONSES=(
  "I'm right here with you 💛"
  "Let's do this together 🦞"
  "You're not alone"
  "I'm staying with you"
  "We've got this"
  "Presence > pressure"
  "Sitting with you now 🧠"
  "No rush, no pressure"
  "I'm here for this"
  "Doing this with you"
)

TASK_DECOMPOSE_RESPONSES=(
  "Here's your task broken into small, manageable pieces. Pick just one to start with 💛"
  "One tiny step at a time 🦞"
  "Small pieces, you've got this"
  "Any one step counts 🧠"
  "Start with the smallest piece"
  "Breaking it down for you"
  "One piece at a time 💛"
  "Tiny steps lead to big wins"
  "Pick the easiest first 🦞"
  "You've got this, piece by piece"
)

TRANSITION_RESPONSES=(
  "Let's gently move to the next thing. Take a breath first 💛"
  "Transitions are hard and that's okay 🦞"
  "One breath, then we move"
  "Gentle shift to the next thing 🧠"
  "You did great. Now we transition"
  "Breath first, then move 💛"
  "Transitions take energy - honor that"
  "Ready when you are 🦞"
  "Let's make the shift together"
  "Gentle bridge to what's next"
)

SENSORY_BREAK_RESPONSES=(
  "Everything can wait. Right now, just breathe. You're safe 🌿"
  "Your nervous system needs this 💛"
  "Grounding with you right now 🦞"
  "Safe and calm together 🧠"
  "Everything else can wait"
  "Just breathe, I've got you 💛"
  "Sensory rest is necessary"
  "Quiet and calm right now 🌿"
  "You're safe here 🦞"
  "Rest is productive too"
)

SOCIAL_SCRIPT_RESPONSES=(
  "Here are a few ways you could say that. Pick whichever feels most like you 💛"
  "Some options for you 🦞"
  "Find the words that feel right"
  "Pick what feels authentic 🧠"
  "Your voice matters - choose what fits"
  "Options that honor your style 💛"
  "Say it your way"
  "Choose what feels comfortable 🦞"
  "Words that work for you"
  "Your authenticity matters most"
)

CELEBRATION_RESPONSES=(
  "YES!! You did it! 🎉"
  "I'm literally cheering rn! 🦞🧠"
  "So proud of you!! 💛"
  "That took real effort - amazing!"
  "LOOK AT YOU GO! ✨"
  "You showed up and did it! 🦞"
  "Look at what you accomplished! 🧠"
  "That's a win! 🎉"
  "You crushed it! 💛"
  "Proof that you can do hard things"
)

CHECKIN_RESPONSES=(
  "Hey {name} 🦞 Just checking in - how are you doing?"
  "Thinking of you, {name} 🧠 Wanted to see how you're feeling"
  "Quick check in {name} 💛 What's your energy like right now?"
  "Hey {name} 🦞🧠 How's it going?"
  "Checking in, {name} 🦞 No pressure to reply, just here if you need me 💛"
)

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
# Setup
# --------------------------------------------------------------------------
ensure_dir() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
  fi
}

# Initialize temp directory
ensure_dir "$TEMP_DIR"
ensure_dir "$MEMORY_DIR"

# --------------------------------------------------------------------------
# Input Sanitization (Security)
# --------------------------------------------------------------------------
sanitize_context() {
  local context="$1"
  # Remove shell metacharacters to prevent command injection
  context=$(echo "$context" | tr -d '`$(){}[];&|\|!*?#')
  # Escape quotes
  context=$(echo "$context" | sed 's/"/\\"/g')
  # Limit length to prevent memory issues
  [ ${#context} -gt 1000 ] && context="${context:0:1000}"
  echo "$context"
}

# --------------------------------------------------------------------------
# Smart Mode Detection (5 Layers)
# --------------------------------------------------------------------------
detect_mode_smart() {
  local context="$1"
  local lowercase=$(echo "$context" | tr '[:upper:]' '[:lower:]')
  local triggers=""
  
  # Layer 1: Explicit keywords (high confidence)
  case "$lowercase" in
    *"body double"*|*"can't start"*|*"sit with me"*|*"work with me"*|*"co-work"*)
      echo "mode:body-double|triggers:explicit"
      return ;;
    *"overwhelmed"*|*"break it down"*|*"too much"*|*"simplify"*|*"where to start"*)
      echo "mode:task-decompose|triggers:explicit"
      return ;;
    *"finished"*|*"what's next"*|*"switch"*|*"move on"*|*"can't transition"*)
      echo "mode:transition|triggers:explicit"
      return ;;
    *"overloaded"*|*"sensory"*|*"meltdown"*|*"calm down"*)
      echo "mode:sensory-break|triggers:explicit"
      return ;;
    *"how do i say"*|*"respond to"*|*"awkward"*|*"help me email"*)
      echo "mode:social-script|triggers:explicit"
      return ;;
    *"did it"*|*"done"*|*"finished"*|*"completed"*|*"accomplished"*)
      echo "mode:celebration|triggers:explicit"
      return ;;
  esac
  
  # Layer 2: Emoji emotional signals (with fallback for systems without Unicode support)
  if echo "$context" | grep -qE '[😭😩🥺😤😰💔😫😣]' 2>/dev/null; then
    # Distress detected
    if echo "$lowercase" | grep -qE 'work|task|study|start|do|focus|begin'; then
      echo "mode:body-double|triggers:emoji-distress-task"
      return
    elif echo "$lowercase" | grep -qE 'loud|bright|noise|people|much|overwhelm|sensory'; then
      echo "mode:sensory-break|triggers:emoji-distress-sensory"
      return
    else
      echo "mode:body-double|triggers:emoji-distress-general"
      return
    fi
  fi
  
  # Layer 3: Celebration emojis (with fallback for systems without Unicode support)
  if echo "$context" | grep -qE '[🎉✅💪🏆🎊😄😊🥳]' 2>/dev/null; then
    echo "mode:celebration|triggers:emoji-positive"
    return
  fi
  
  # Layer 4: Capitalization intensity
  if echo "$context" | grep -qE '^[A-Z\s!]{15,}$'; then
    # High emotional intensity
    if echo "$lowercase" | grep -qE 'did|done|finished|complete|win|got|made'; then
      echo "mode:celebration|triggers:all-caps-win"
      return
    else
      echo "mode:body-double|triggers:all-caps-distress"
      return
    fi
  fi
  
  # Layer 5: Indirect expressions (neurodivergent communication patterns)
  if echo "$lowercase" | grep -qE 'ugh|stuck|hard|difficult|can.t|impossible|forever|never|always|why is this'; then
    echo "mode:body-double|triggers:indirect-struggle"
    return
  fi
  
  # Default fallback
  echo "mode:body-double|triggers:default"
}

# --------------------------------------------------------------------------
# Memory Integration (OpenClaw Native)
# --------------------------------------------------------------------------
log_to_memory() {
  local mode="$1"
  local context="$2"
  local detected_triggers="$3"
  local timestamp=$(date -Iseconds)
  
  # Sanitize context for safe logging
  context=$(sanitize_context "$context")
  
  # Create memory entry
  local entry="- ${timestamp} | ${mode} | ${context}"
  [ -n "$detected_triggers" ] && entry="${entry} | ${detected_triggers}"
  
  # Write to daily memory file
  local memory_file="${MEMORY_DIR}/$(date +%Y-%m-%d).md"
  echo "$entry" >> "$memory_file"
  
  # Update pattern file for quick lookup
  if [ -n "$detected_triggers" ]; then
    local pattern_file="${MEMORY_DIR}/patterns.md"
    echo "$(date +%Y-%m-%d): ${detected_triggers} | ${context}" >> "$pattern_file"
  fi
}

# Pattern Detection Examples
check_contextual_patterns() {
  local current_context="$1"
  local lowercase=$(echo "$current_context" | tr '[:upper:]' '[:lower:]')
  local user_name="friend"
  
  # Check last 7 days of memory
  local recent_memory=""
  if [ -d "$MEMORY_DIR" ]; then
    recent_memory=$(find "$MEMORY_DIR" -name "*.md" -mtime -7 -size -100k -exec head -c 10000 {} \; 2>/dev/null || echo "")
  fi
  
  # Pattern 1: Smoking + Study (as requested example)
  if echo "$lowercase" | grep -qE 'study|work|focus|assignment|deadline|homework'; then
    if echo "$recent_memory" | grep -i 'smok\|cigarette\|craving\|nicotine' | head -1 | grep -q '.'; then
      # High-risk trigger: studying + previous smoking mention
      echo "pattern:smoking-study|action:gentle-check-in"
      return 0
    fi
  fi
  
  # Pattern 2: Late night anxiety (after 10pm + anxiety words)
  local hour=$(date +%H)
  if [ "$hour" -ge 22 ] || [ "$hour" -le 02 ]; then
    if echo "$lowercase" | grep -qE 'anxious|worried|can.t sleep|racing'; then
      if echo "$recent_memory" | grep -i 'night\|sleep\|anxious' | wc -l | grep -q '[3-9]\|10'; then
        echo "pattern:late-night-anxiety|action:night-support"
        return 0
      fi
    fi
  fi
  
  # Pattern 3: Recurring task avoidance
  if echo "$lowercase" | grep -qE 'avoid|putting off|keep delaying'; then
    local task_avoidance_count=$(echo "$recent_memory" | grep -c 'body-double' 2>/dev/null || echo "0")
    if [ "$task_avoidance_count" -gt 5 ]; then
      echo "pattern:recurring-avoidance|action:gentle-accountability"
      return 0
    fi
  fi
  
  return 1
}

# --------------------------------------------------------------------------
# Dynamic Response Selection
# --------------------------------------------------------------------------
select_response() {
  local mode="$1"
  local user_name="$2"
  local history_file="${TEMP_DIR}/${mode}_history_$(date +%Y%m%d)"
  
  # Get response array reference
  local -n responses="${mode^^}_RESPONSES"
  
  # Filter out last 3 used responses
  local last_three=""
  if [ -f "$history_file" ]; then
    last_three=$(tail -n 3 "$history_file" 2>/dev/null || echo "")
  fi
  
  local available=()
  for resp in "${responses[@]}"; do
    # Replace {name} placeholder
    resp="${resp//\{name\}/$user_name}"
    
    # Check if used recently
    if ! echo "$last_three" | grep -qxF "$resp"; then
      available+=("$resp")
    fi
  done
  
  # If all used recently, reset history
  if [ ${#available[@]} -eq 0 ]; then
    available=("${responses[@]}")
    > "$history_file" 2>/dev/null || true
  fi
  
  # Random selection
  local idx=$((RANDOM % ${#available[@]}))
  local selected="${available[$idx]}"
  
  # Update history
  echo "$selected" >> "$history_file" 2>/dev/null || true
  
  echo "$selected"
}

# --------------------------------------------------------------------------
# Heartbeat Check-in Generation
# --------------------------------------------------------------------------
generate_checkin() {
  local user_name="friend"
  local checkin_file="${TEMP_DIR}/checkin_history_$(date +%Y%m%d)"
  
  # Get available checkins
  local available=()
  for checkin in "${CHECKIN_RESPONSES[@]}"; do
    checkin="${checkin//\{name\}/$user_name}"
    if ! [ -f "$checkin_file" ] || ! grep -qxF "$checkin" "$checkin_file" 2>/dev/null; then
      available+=("$checkin")
    fi
  done
  
  # Reset if all used
  if [ ${#available[@]} -eq 0 ]; then
    available=("${CHECKIN_RESPONSES[@]}")
    > "$checkin_file" 2>/dev/null || true
  fi
  
  # Time-based selection for variety
  local hour=$(date +%H)
  local idx=$(((hour / 4) % ${#available[@]}))
  local selected="${available[$idx]}"
  selected="${selected//\{name\}/$user_name}"
  
  # Log to history
  echo "$selected" >> "$checkin_file" 2>/dev/null || true
  
  echo "$selected"
}

# --------------------------------------------------------------------------
# Prompt Building
# --------------------------------------------------------------------------
build_prompt_and_caption() {
  local mode="$1"
  local context="$2"
  local custom_caption="$3"
  local user_name="friend"
  
  # Sanitize context to prevent command injection
  context=$(sanitize_context "$context")
  
  # Check for contextual patterns first
  local pattern_result=$(check_contextual_patterns "$context")
  
  case "$mode" in
    body-double)
      # Check for special patterns
      if echo "$pattern_result" | grep -q "smoking-study"; then
        PROMPT="cozy workspace scene with soft calming elements, companion character present and supportive, warm gentle lighting, study session with reassuring presence"
        CAPTION="Hey $user_name 💛 I remember you mentioned smoking before. How are you doing with that? I'm here either way 🦞"
      elif echo "$pattern_result" | grep -q "recurring-avoidance"; then
        PROMPT="cozy workspace scene, companion character sitting alongside with gentle encouraging presence, warm soft lighting, supportive atmosphere"
        CAPTION="I've noticed you've been struggling to start tasks lately $user_name. Want me to sit with you for a bit? 🦞🧠"
      else
        PROMPT="cozy workspace scene, companion character sitting at desk alongside viewer, warm soft lighting, focused but relaxed atmosphere, ${context}, encouraging and supportive presence"
        CAPTION=$(select_response "body_double" "$user_name")
      fi
      ;;
      
    task-decompose)
      PROMPT="clean visual board with colorful organized sections, calming soft colors, minimal design, ${context}, motivating but not overwhelming"
      CAPTION=$(select_response "task_decompose" "$user_name")
      ;;
      
    transition)
      PROMPT="peaceful pathway connecting two soft-colored scenes, dreamy atmosphere, gentle bridge imagery, ${context}, calming pastels"
      CAPTION=$(select_response "transition" "$user_name")
      ;;
      
    sensory-break)
      # Check for late night anxiety pattern
      if echo "$pattern_result" | grep -q "late-night-anxiety"; then
        PROMPT="extremely soft nighttime scene, muted gentle colors only, peaceful minimal composition, calming moonlight, safe and quiet atmosphere"
        CAPTION="Nighttime can be hard $user_name 💛 You're safe. Let's breathe together 🌿"
      else
        PROMPT="serene nature scene, ultra-soft muted lighting, gentle colors only, peaceful minimal composition, ${context}"
        CAPTION=$(select_response "sensory_break" "$user_name")
      fi
      ;;
      
    social-script)
      PROMPT="warm illustration of two people in comfortable conversation, friendly body language, ${context}, approachable atmosphere"
      CAPTION=$(select_response "social_script" "$user_name")
      ;;
      
    celebration)
      PROMPT="joyful scene with confetti and sparkles, warm radiant energy, companion celebrating, achievement vibes, ${context}, congratulatory atmosphere"
      CAPTION=$(select_response "celebration" "$user_name")
      ;;
      
    *)
      log_error "Unknown mode: $mode"
      exit 1
      ;;
  esac
  
  # Override with custom caption if provided
  [ -n "$custom_caption" ] && CAPTION="$custom_caption"
}

# --------------------------------------------------------------------------
# Visual Generation
# --------------------------------------------------------------------------
validate_prereqs() {
  if [ -z "${FAL_KEY:-}" ]; then
    log_warn "FAL_KEY not set — running in text-only mode (no image generation)"
    IMAGE_GENERATION=false
  else
    IMAGE_GENERATION=true
  fi

  if ! command -v curl &> /dev/null; then
    log_error "'curl' is required but not installed."
    exit 1
  fi

  if ! command -v jq &> /dev/null; then
    log_error "'jq' is required but not installed."
    exit 1
  fi
}

generate_visual() {
  local companion_image="${CLAWRITY_COMPANION_IMAGE:-$DEFAULT_COMPANION}"

  log_info "Generating visual with Grok Imagine..."

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
    # Fall back to text-only mode
    IMAGE_GENERATION=false
    IMAGE_URL=""
  else
    log_success "Visual generated: $IMAGE_URL"
  fi
}

# --------------------------------------------------------------------------
# Send via OpenClaw
# --------------------------------------------------------------------------
send_to_channel() {
  local channel="$1"

  log_info "Sending to channel: $channel"

  if command -v openclaw &> /dev/null; then
    if [ -n "${IMAGE_URL:-}" ] && [ "$IMAGE_GENERATION" = true ]; then
      openclaw message send \
        --action send \
        --channel "$channel" \
        --message "$CAPTION" \
        --media "$IMAGE_URL"
    else
      openclaw message send \
        --action send \
        --channel "$channel" \
        --message "$CAPTION"
    fi
  elif [ -n "${OPENCLAW_GATEWAY_TOKEN:-}" ]; then
    log_warn "openclaw CLI not found, using direct API call"
    local send_payload
    if [ -n "${IMAGE_URL:-}" ] && [ "$IMAGE_GENERATION" = true ]; then
      send_payload=$(jq -n \
        --arg channel "$channel" \
        --arg message "$CAPTION" \
        --arg media "$IMAGE_URL" \
        '{action: "send", channel: $channel, message: $message, media: $media}')
    else
      send_payload=$(jq -n \
        --arg channel "$channel" \
        --arg message "$CAPTION" \
        '{action: "send", channel: $channel, message: $message}')
    fi

    curl -s -X POST "$GATEWAY_URL" \
      -H "Authorization: Bearer $OPENCLAW_GATEWAY_TOKEN" \
      -H "Content-Type: application/json" \
      -d "$send_payload"
  else
    log_error "Neither 'openclaw' CLI nor OPENCLAW_GATEWAY_TOKEN found."
    exit 1
  fi

  log_success "Sent to $channel ✓"
}

# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------
main() {
  if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "CLAWrity Support v${VERSION}"
    echo ""
    echo "Usage: $0 <user_context> <channel> [mode] [caption]"
    echo ""
    echo "Modes: body-double, task-decompose, transition, sensory-break, social-script, celebration, auto"
    exit 0
  fi

  local user_context="${1:-}"
  local channel="${2:-}"
  local mode="${3:-auto}"
  local custom_caption="${4:-}"

  if [ -z "$user_context" ] || [ -z "$channel" ]; then
    log_error "Missing required arguments. Use --help for usage."
    exit 1
  fi

  # Validate inputs
  if [ ${#user_context} -gt 1000 ]; then
    log_warn "Input too long, truncating to 1000 characters"
    user_context="${user_context:0:1000}"
  fi
  
  if [[ ! "$channel" =~ ^[a-zA-Z0-9_#@\-\+\.\$\:]+$ ]]; then
    log_error "Invalid channel format. Use valid channel identifiers only."
    exit 1
  fi

  validate_prereqs

  # Smart mode detection
  if [ "$mode" = "auto" ]; then
    local detection_result=$(detect_mode_smart "$user_context")
    mode=$(echo "$detection_result" | cut -d'|' -f1 | cut -d':' -f2)
    local triggers=$(echo "$detection_result" | cut -d'|' -f2 | cut -d':' -f2)
    log_info "Auto-detected mode: $mode (triggers: $triggers)"
  else
    local triggers="explicit"
  fi

  # Log to memory
  log_to_memory "$mode" "$user_context" "$triggers"

  # Build prompt and caption
  build_prompt_and_caption "$mode" "$user_context" "$custom_caption"

  log_info "Mode: $mode"

  # Generate visual if possible
  if [ "$IMAGE_GENERATION" = true ]; then
    generate_visual
  else
    IMAGE_URL=""
    log_info "Skipping image generation (text-only mode)"
  fi

  # Send message
  send_to_channel "$channel"

  log_success "Done! 🦞🧠"

  # Output structured result
  jq -n \
    --arg mode "$mode" \
    --arg image_url "${IMAGE_URL:-}" \
    --arg caption "$CAPTION" \
    --arg channel "$channel" \
    --arg triggers "$triggers" \
    --argjson has_image "$IMAGE_GENERATION" \
    '{mode: $mode, image_url: $image_url, caption: $caption, channel: $channel, triggers: $triggers, has_image: $has_image, status: "sent"}'
}

main "$@"
