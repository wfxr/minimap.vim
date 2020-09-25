#!/usr/bin/env bash
############################################################################
#    Author: Wenxuan Zhang                                                 #
#     Email: wenxuangm@gmail.com                                           #
#   Created: 2020-09-25 14:37                                              #
############################################################################
set -eo pipefail
IFS=$'\n\t'

usage() { echo "Usage: $(basename "$0") <hscale> <vscale> <fill_width> [file]" >&2; }

(( $# < 3 || $# > 4 )) && usage && exit 1

hscale=$1
vscale=$2
fill_width=$3
file=$4

minimap_gen() {
    if [ -z "$file" ]; then
        code-minimap -H "$hscale" -V "$vscale"
    else
        code-minimap -H "$hscale" -V "$vscale" "$file"
    fi
}

minimap_gen | awk "{printf \"%-${fill_width}s\n\",\$1}"
