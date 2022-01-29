#!/usr/bin/env bash

set -e

EXT_CODE=0

for dir in $(echo "$@" | xargs -n1 dirname | sort | uniq); do
    echo "Running 'packer fmt' in directory '$dir'"
    pushd "$dir" >/dev/null
    packer fmt . || EXT_CODE=$?
    popd >/dev/null
done

exit ${EXT_CODE}
