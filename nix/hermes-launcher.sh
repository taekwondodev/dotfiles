#!/bin/sh
# The upstream runtime and PM are supplied by Nix, not repaired on first use.
export HERMES_DISABLE_LAZY_INSTALLS=1
exec "@hermes@/bin/@command@" "$@"
