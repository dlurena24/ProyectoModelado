#!/bin/sh
printf '\033c\033]0;%s\a' Avatars vs Rooks
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Avatars vs Rooks.x86_64" "$@"
