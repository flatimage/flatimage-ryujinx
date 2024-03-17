#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Main directory
export DIR_RYUJINX="$SCRIPT_DIR"

# Start
"$DIR_RYUJINX"/bin/Ryujinx "$@"
