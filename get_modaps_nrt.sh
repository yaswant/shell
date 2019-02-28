#!/bin/bash -l
##SBATCH --job-name="get_modis_nrt"
##SBATCH --time=30
##SBATCH --ntasks=4
##SBATCH --mem=1000
##SBATCH --output=<path>/%x-%j.out
##SBATCH --mail-type=FAIL
##SBATCH --mail-user=<e-mail>
# =============================================================================
# ^^ To run as sbatch job remove one '#' from SBATCH  options above ^^
#
# Download MODIS Level-2 files from nrt4 server via https authentication.
#
# Warning: This script is designed for MODIS aerosol products download - running
# the script without any keyword parameters may download files which are not
# desired.
#
# TODO: Use checksum to verify downloaded files.
#
# 2018-09-24 Yaswant Pradhan. working version
# 2018-11-07 Update with various command-line options. yp.
# 2018-11-07 Auto-switch remote server when one is down. yp.
# =============================================================================
if [[ "$OSTYPE" == 'linux-gnu' ]]; then
  OPTS="$(getopt -o c:hk:p:P:r:s:v \
    --long collection:,help,key:,product:,directory-prefix:,remote-dir:,server:,version \
    --name "$0" -- "$@")"
  [ $? != 0 ] && { echo "Terminating..." >&2; exit 1 ; }
  eval set -- "$OPTS"
fi


# Default Options -------------------------------------------------------------
COLLECT=61                                      # 1 | 6 | 61 | 5000 | 5001
SERVER=https://nrt3.modaps.eosdis.nasa.gov      # nrt3 preferred server
ALT_SERVER=https://nrt4.modaps.eosdis.nasa.gov  # nrt4 alternate server
ENDPOINTS=api/v2/content                        # ENDPOINTS=api/v2/files
PRODUCT=MYD04_L2                                # MYD04_L2 | MOD04_L2
DIR=$(date -u +'%Y/%j')                         # Recent | %Y/%j
AUTH=$(cat ~/.modaps_auth)                      # app authentication token

# LIST_FMT=csv                                  # csv | json | html (TODO)
# -----------------------------------------------------------------------------

msg() { echo -e "$(date -u +'%F %R:%S') $*" ;}

check_remote_host()
{ # Check if any of the remote servers are up and running (rc: 2 = fail)
  local def_server=${1:-$SERVER}
  local alt_server=${2:-$ALT_SERVER}
  curl --fail -L "$def_server" &>/dev/null \
    || { curl --fail -L "$alt_server" &>/dev/null && SERVER=$ALT_SERVER ;} \
    || { echo  "** ERROR: Remote servers not available. **"; return 2 ;}
}
# -----------------------------------------------------------------------------
version(){
cat<<EOF
${0##*/} 2018.11.2

Copyright (C) 2019 Free Software Foundation, Inc.
This is free software; see the source for copying conditions. There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Written by Yaswant Pradhan.
EOF
}
usage(){
cat<<EOF
Usage: ${0##*/} [OPTION]

Options:
  -c, --collection[=VALUE]    MODIS processing version/collection number. One from 1, 6, 61, 5000, 5001. Default: $COLLECT
  -e, --end-point[=VALUE]     HTTPS endpoint path appended to server to get content details. Default: $ENDPOINTS
  -k, --key[=VALUE]           application authentication key (token) passed in via an Authorization HTTP header. See https://nrt3.modaps.eosdis.nasa.gov/help/downloads. Default: read from ~/.modaps_auth file if available.
  -p, --product[=VALUE]       MODIS product category. For complete list, see https://earthdata.nasa.gov/earth-observation-data/near-real-time OR https://lance-modis.eosdis.nasa.gov/data_products. Default: $PRODUCT
  -P, --directory-prefix[=PATH]   Set directory prefix to prefix. The directory prefix is the directory where all files will be saved to. Default: ${SCRATCH}/${COLLECT}/${PRODUCT}/${DIR}
  -r, --remote-dir=[VALUE]    remote directory name from where files will be fetched, in 'year/sday' or 'Recent'. Default: $DIR
  -s, --server[=VALUE]        MODAPS near-real time host server name. Default: $SERVER Alt: $ALT_SERVER
  -h, --help                  display this help and exit
  -v, --version               output version information and exit

Examples:
  ${0##*/} -c 61 -p MYD04_L2 -P ${TMPDIR}/${DIR} -s https://nrt4.modaps.eosdis.nasa.gov     downloads all MYD04_L2 collection 6.1 files for current date ($DIR) to ${TMPDIR}/${DIR}

Report bugs to <yaswant.pradhan>
EOF
}
# -----------------------------------------------------------------------------
while true; do
  case "$1" in
    -c |--collection )      COLLECT="$2"; shift 2 ;;
    -e |--end-point)        ENDPOINTS="$2"; shift 2;;
    -k |--key )             AUTH="$2"; shift 2 ;;
    -p |--product )         PRODUCT="$2"; shift 2 ;;
    -P |--directory-prefix) WORK_DIR="$2"; shift 2;;
    -r |--remote-dir )      DIR="$2"; shift 2 ;;
    -s |--server )          SERVER="$2"; shift 2 ;;
    -h |--help )            usage; exit 0 ;;
    -v |--version)          version; exit 0 ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

REM_PATH="allData/${COLLECT}/${PRODUCT}/${DIR}"
WORK_DIR=${WORK_DIR:-${SCRATCH}/${COLLECT}/${PRODUCT}/${DIR}}
REM_LIST_FILE="${PRODUCT}.rem"                # file list on remote server
LOC_LIST_FILE="${PRODUCT}.loc"                # file list on local dir
NEW_LIST_FILE="${PRODUCT}.get"                # new files on remote server
[ -z "$AUTH" ] && echo "Error: Authentication token missing" && exit

# Check and switch if remote server(s) available or exit
check_remote_host "$@" || exit

echo "************************************************************************"
echo -e "* REMOTE_SERVER=$SERVER\n* COLLECTION=$COLLECT\n* PRODUCT=$PRODUCT"
echo -e "* ENDPOINTS=$ENDPOINTS\n* REMOTE_DIR=archives/${REM_PATH}"
echo -e "* LOCAL_DIR=$WORK_DIR"
echo "************************************************************************"

mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || exit

# Update file lists -----------------------------------------------------------
get_remote_list() { # Update file lists on remote server
  remote_files=${1:-$REM_LIST_FILE}
  msg "Create/Update remote file-list> $remote_files ..\c"
  curl --header "Authorization: Bearer $AUTH" \
    --silent "${SERVER}/${ENDPOINTS}/details/${REM_PATH}?format=csv" \
    | cut -d, -f6 | grep .hdf$ | sort > "$remote_files"

  # or with filename size (use cksum field when available) list ---
  # curl --silent ${SERVER}/${ENDPOINTS}/details/${REM_PATH}?format=csv \
  #     | awk -F',' '{print $6,$8}' | grep '.hdf ' > $remote_files
  echo ' done.'
}

get_local_list() { # Update file lists on local path
  local_files=${1:-$LOC_LIST_FILE}
  msg "Create/Update local file-list> $local_files ..\c"
  ls -1 ${PRODUCT}*.hdf 2>/dev/null | sort > "$local_files"

  # or with filename size (use cksum when available on remote server) list --
  # /bin/ls -lb *.hdf | awk '{print $9,$5}' > $local_files
  echo ' done.'
}

get_local_list "$LOC_LIST_FILE"
get_remote_list "$REM_LIST_FILE"

msg "Create/Update downloadable file-list: $NEW_LIST_FILE ..\c"
comm -23 "$REM_LIST_FILE" "$LOC_LIST_FILE" > "$NEW_LIST_FILE"
echo ' done.'


# Check if download needed ----------------------------------------------------
N_NEW=$(< "$NEW_LIST_FILE" wc -l)
if [[ "$N_NEW" -lt 1 ]]; then
  msg "Skip download: All remote files are already in [$WORK_DIR]"
  exit 0
else
  echo; msg "Downloading new files to [$WORK_DIR]"
  cat < "$WORK_DIR/$NEW_LIST_FILE" | nl
fi


# Start download new files ----------------------------------------------------
cnt=0
BATCH=10

while read -r line; do
  printf "+"
  # line does not include remote address, add prefix to line
  curl --header "Authorization: Bearer $AUTH" \
    --continue-at - -OS --max-time 300 --retry 3 \
    --silent -L "${SERVER}/${ENDPOINTS}/archives/${REM_PATH}/${line##*/}" &

  cnt=$((cnt + 1))
  [[ $(( cnt % BATCH )) -eq 0 ]] && wait && echo -e " \c";

done < "$NEW_LIST_FILE"
wait

echo; msg "Download complete."
