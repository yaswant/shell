#!/bin/sh
#
# Usage: nf [PATH]
#
# nf: Prints number of files in a specific directory (def cwd).
# Wildcards must be escaped, for example, nf /path/to/files/\*pattern\*
#
# Yaswant Pradhan (2013-02-05)
# #

FILE_PATH="${1:-$(pwd)}"
#echo $FILE_PATH
/bin/ls -1 "$FILE_PATH" 2>/dev/null | wc -l
