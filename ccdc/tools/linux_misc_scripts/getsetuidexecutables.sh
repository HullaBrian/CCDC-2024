#!/bin/bash
echo "This script finds FILES that have a setUID or setGID bit set and prints them, machine comparably, to stdout (default sort settings)" >&2
echo "If you need this output to be human readable, consider piping it through \`column -s $'\t' -t\`" >&2
sudo find / \( \( -path '/dev*' -o -path '/proc*' -o -path '/sys*' \) -prune \) -o -type f -perm /7000 -printf '%p\t%u:%g\t%M\n' | sort

