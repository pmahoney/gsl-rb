#!/bin/sh

[ -n "$LIBGSL" ] || {
    [ -n "$1" ] && LIBGSL="$1" || LIBGSL="/usr/lib/libgsl.so"
}

echo "module GSL"
echo "SYMBOLS = %w["
objdump -T "$LIBGSL" | grep gsl_ | awk '{print $7}' | sort
echo "]"
echo "end"
