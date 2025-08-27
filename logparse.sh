#!/bin/bash

# === Simple Incremental Log Parser ===
LOG_FILE="/var/log/auth.log"
STATE_FILE="$HOME/.log_offset"
REPORT_DIR="$HOME/logreports"
mkdir -p "$REPORT_DIR"

# Where to save report
REPORT="$REPORT_DIR/report-$(date +%Y%m%d-%H%M%S).txt"

# Figure out where we left off
LAST_OFFSET=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
CURRENT_SIZE=$(sudo stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)

# Handle log rotation (file reset)
if [ "$CURRENT_SIZE" -lt "$LAST_OFFSET" ]; then
  LAST_OFFSET=0
fi

# Extract only NEW lines since last run
sudo tail -c +$((LAST_OFFSET+1)) "$LOG_FILE" > /tmp/new_auth.log
echo "$CURRENT_SIZE" > "$STATE_FILE"

# Start report
echo "=== Log Report ($(date)) ===" | tee "$REPORT"

echo "" | tee -a "$REPORT"
echo "=== Failed SSH Logins ===" | tee -a "$REPORT"
grep "Failed password" /tmp/new_auth.log | tee -a "$REPORT" || echo "(none)" | tee -a "$REPORT"

echo "" | tee -a "$REPORT"
echo "=== Invalid User Attempts ===" | tee -a "$REPORT"
grep "Invalid user" /tmp/new_auth.log | tee -a "$REPORT" || echo "(none)" | tee -a "$REPORT"

echo "" | tee -a "$REPORT"
echo "=== Sudo Failures ===" | tee -a "$REPORT"
grep "sudo:" /tmp/new_auth.log | grep -i "authentication failure\|NOT in sudoers" | tee -a "$REPORT" || echo "(none)" | tee -a "$REPORT"

echo "" | tee -a "$REPORT"
echo "Report saved to $REPORT"
