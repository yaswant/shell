#!/bin/bash
#
# Usage: nf [PATH]
#
# nf: Prints number of files in a specific directory (def cwd).
# Wildcards must be escaped or quoted, for example,
# nf /path/to/files/\*pattern\*
# nf "/path/to/files/*pattern*"
#
# Yaswant Pradhan (2013-02-05)
# #

FILE_PATH="${1:-$(pwd)/*}"
printf "%s\n" ${FILE_PATH[@]} | wc -l
