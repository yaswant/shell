#!/bin/bash -e
# td: time-delta between two datetime strings
#
# Activate debug mode
if [[ "$DEBUG" ]]; then
  PS4='L${LINENO}: '
  set -x
fi
# ----------------------------------------------------------------------------
OPTS=$(getopt -o u:hv -long unit:,help,version -n "${0##*/}" -- "$@") \
      || { echo "Terminating..." >&2; exit 1; }
eval set -- "$OPTS"

version(){
cat<<EOF
${0##*/} 2019.version

Copyright (C) 2019 Free Software Foundation, Inc.
This is free software; see the source for copying conditions. There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Written by Yaswant Pradhan.
EOF
}

usage(){
cat<<EOF
${0##*/} Calculate time delta between two datetimes.

Usage: ${0##*/} [OPTION] [DATETIME1 [DATETIME2]]

Args:
  DATETIME1             Initial date and time string. Defaults to 0 hour today.
  DATETIME2 [OPTIONAL]  Final dete and time string. Defaults current datetime.

Options:
  -u, --unit[=VALUE]    Set time delta unit. Defaults to Hours.
                        Other options are [D]ays, [M]inutes, and [S]econds.
  -h, --help            print this help and exit
  -v, --version         print version and exit

Examples:
  td (time delta in hours from midnight)
  td "2010-01-01 02:30:10" "2010-01-02 01:30:10"

Warning:
  unit conversion is based on the first chracter of unit value, so a value starts with M|m will silently process and present reslut in minutes, even when the user input os Month.
  TODO: apply strict input error checks.

Report bugs to <yaswant.pradhan@metoffice.gov.uk>

EOF
}
# ----------------------------------------------------------------------------
while true; do
  case "$1" in
    -u |--unit)     td_unit="$2"; shift 2 ;;
    -h |--help )    usage; exit 0 ;;
    -v |--version ) version; exit 0 ;;
    -- )            shift; break ;;
    * )             break ;;
  esac
done

s1=$(date -d "$1" +%s)
[[ "$2" ]] && s2=$(date -d "$2" +%s) || s2=$(date +%s)
TDU=$(tr '[:lower:]' '[:upper:]' <<< "$td_unit")
tdf=3600
case "${TDU:0:1}" in
  "D") tdf=86400;;
  "H") tdf=3600;;
  "M") tdf=60;;
  "S") tdf=1;;
esac

# Print time delta in decimal hours
awk '{printf "%0.2f\n",($2-$1)/$3}' <<< "$s1 $s2 $tdf"
