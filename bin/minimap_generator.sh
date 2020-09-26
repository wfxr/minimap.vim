#!/usr/bin/env bash
############################################################################
#    Author: Wenxuan Zhang                                                 #
#     Email: wenxuangm@gmail.com                                           #
#   Created: 2020-09-25 14:37                                              #
############################################################################
usage() { echo "Usage: $(basename "$0") <hscale> <vscale> <padding> [file]" >&2; }

if [ $# -lt 3 ] || [ $# -gt 4 ]; then
    usage && exit 1
fi

hscale=$1
vscale=$2
padding=$3
file=$4

if [ -z "$file" ]; then
    code-minimap -H "$hscale" -V "$vscale" --padding "$padding"
else
    code-minimap -H "$hscale" -V "$vscale" --padding "$padding" "$file"
fi
