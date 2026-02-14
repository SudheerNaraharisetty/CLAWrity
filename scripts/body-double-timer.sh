#!/bin/bash
set -euo pipefail

# ============================================================================
# CLAWrity Body Double Timer
# Periodic check-ins to keep you on track.
# ============================================================================

CHANNEL=${1:-}
INTERVAL=${2:-15} # Minutes

if [ -z "$CHANNEL" ]; then
  echo "Usage: $0 <channel> [interval_minutes]"
  exit 1
fi

# Check OpenClaw availability
if ! command -v openclaw &> /dev/null; then
  echo "Error: 'openclaw' CLI not found. Please install it first."
  exit 1
fi

log_info() { echo -e "\033[0;34m[BodyDouble]\033[0m $1"; }

MESSAGES=(
  "Still focusing? You're doing great. 🦞"
  "Time for a quick posture check! Shoulders down, jaw loose."
  "Just checking in. Keep going!"
  "Drink some water! 💧"
  "You've got this. One small step at a time."
  "Release the tension in your hands."
  "Breathe in... 1, 2, 3. Breathe out... 1, 2, 3."
  "Still with you. 🤜🤛"
)

log_info "Starting Body Double Timer for channel: $CHANNEL"
log_info "Interval: $INTERVAL minutes"
log_info "Press Ctrl+C to stop."

while true; do
  # Sleep for interval
  sleep "$((INTERVAL * 60))"

  # Pick random message
  MSG=${MESSAGES[$RANDOM % ${#MESSAGES[@]}]}

  # Send message
  log_info "Sending check-in: $MSG"
  openclaw message send --channel "$CHANNEL" --message "$MSG" --media "" || true
done
