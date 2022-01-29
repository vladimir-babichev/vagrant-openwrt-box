#!/usr/bin/env bash

set -e

EXT_CODE=0

for dir in $(echo "$@" | xargs -n1 dirname | sort -u | uniq); do
    echo "Running 'packer validate -syntax-only' in directory '$dir'"
    pushd "$dir" >/dev/null
    packer validate -syntax-only . || EXT_CODE=$?
    popd >/dev/null
done

exit ${EXT_CODE}
