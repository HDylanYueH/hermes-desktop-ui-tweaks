#!/bin/bash
# Double-clickable entry point (Finder → Terminal). Same as running
# scripts/apply-and-repack.sh from the command line.
exec "$(cd "$(dirname "$0")" && pwd)/scripts/apply-and-repack.sh"
