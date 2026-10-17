#!/bin/sh
# Keep upstream's profile/home resolution and the caller's working directory.
exec "@hermes@/bin/hermes" -p "@profile@" "$@"
