#!/bin/bash -e
# Check uptime and send an email if up over a week
#
# uptime-checker.sh [HOSTNAME] [EMAIL]
#
# Author:
#   yaswant.pradhan 2019-11-19
# -----------------------------------------------------------------------------

HOST="${1:-$HOSTNAME}"
EMAIL="${2:-$(getent passwd "$USER" | awk -F: '{print $5}')@metoffice.gov.uk}"
up_since="$(ssh "$HOST" 2>/dev/null uptime --since)"
OVER_WEEK=$(echo "$(date -d "$up_since" +%s)" "$(date +%s)" |\
            awk '{printf "%d", ($2-$1)/604800}')

if (( OVER_WEEK >= 1 )); then
  ssh "$HOST" 2>/dev/null w --short | mail -s "Uptime for $HOST" "$EMAIL"
  S='week'; (( OVER_WEEK > 1 )) && S+=s
  [ -t 1 ] && echo "Over $OVER_WEEK $S; Email sent to $EMAIL"
else
  [ -t 1 ] && echo "OK! Up under a week."
fi
