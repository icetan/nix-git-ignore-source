#!/bin/bash
set -e

#export NIX_DEBUG=true

run() {
  diff -u \
    $(nix-build --argstr name "$1" --no-out-link) \
    <(echo "$2" | sed -n '/./p' | sort)
}

(cd "$(dirname "$0")"

# First test

run test-1 '
ignore-me-not
not-a-dir
one-deep
one-deep/hi
'

)
