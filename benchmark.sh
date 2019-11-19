#!/bin/bash
#shellcheck disable=SC2068

# ----------------------------------------------------------------------------
OPTS=$(getopt -o n:o:hvV --long ntimes:,output:,help,verbose,version \
              -n "${0##*/}" -- "$@") || { echo "Terminating..." >&2; exit 1; }
eval set -- "$OPTS"

version(){ echo "${0##*/} v-2019.11"; }

usage(){
cat<<EOF
Benchmark runner
Note: Requires sudo to clear filesystem memory cache

Usage: ${0##*/} [OPTION] COMMAND

Options:

  -n, --ntimes <value>
        Number of iterations for benchmarking. default: 10.

  -o, --output <filename>
        Output file to keep stats as a csv file. default: benchmark_results.csv

  -h, --help
        show this help and exit

  -v, --verbose
        increase verbosity

  -V, --version
        print version and exit

Examples:

    ${0##*/} -n 50 echo "Hello"

Report bugs to <yaswant.pradhan@metoffice.gov.uk>

EOF
}
# ----------------------------------------------------------------------------

repeats=10
output_file='benchmark_results.csv'
log_file=$(mktemp -t benchmark_errors.XXXX)
while true; do
  case "$1" in
    -n|--ntimes)
        repeats="$2"; shift 2 ;;
    -o|--output)
        output_file="$2"; shift 2 ;;
    -h|--help )
        usage; exit 0 ;;
    -v|--verbose)
        verb=1; shift 1 ;;
    -V|--version)
        version; exit 0 ;;
    --) shift; break ;;
    * ) break ;;
  esac
done

command_to_run=( "$@" )
[[ "$#" -lt 1 ]] && usage && exit

if (( verb )); then
  echo "repeats: $repeats"
  echo "output: $output_file"
  echo "run: /usr/bin/time -f '%E,%U,%S' -ao $output_file ${command_to_run[*]}"
fi

run_tests(){
  echo "Benchmarking:  ${command_to_run[*]}"
  echo "====== ${command_to_run[*]} ======" > "$output_file" || exit
  echo "real,user,sys" >> "$output_file"

  [[ $(id -u) -ne 0 ]] && echo -e "[WARNING] Please run as root to drop cache\n"

  for (( i=1; i<=repeats; i++ )); do

    # Percentage completion and progress indicator
    p=$(( i * 100 / repeats ))
    l=$(seq -s "+" $(( i +1 )) | sed 's/[0-9]//g')

    # Run time on command, output in a comma separated format file specified
    # with -o <out-filename> and -a option to append
    /usr/bin/time \
      -f '%E,%U,%S' \
      -ao "$output_file" ${command_to_run[@]} > "$log_file" 2>&1 \
      || { echo "Something went wrong, Please see: $log_file"; exit 1; }

    # Clear filesystem memory cache
    if [[ $(id -u) -eq 0 ]]; then
      sync
      sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    fi

    # Print progress +++
    echo -ne "${l} (${p}%) \r"
  done
  echo -ne '\n'
  echo '--------------------------' >> "$output_file"
}

run_tests && rm "$log_file"
