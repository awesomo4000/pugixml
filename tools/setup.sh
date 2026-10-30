#!/bin/sh
# One-time setup for a clone: point git at tools/hooks so the pre-push
# identity check runs. Writes .mise-setup (gitignored) when done; silent
# when it is already in place.
set -eu

cd "$(git rev-parse --show-toplevel)"
marker=.mise-setup

if [ -f "$marker" ] && [ "$(git config core.hooksPath || true)" = tools/hooks ]; then
    exit 0
fi

git config core.hooksPath tools/hooks
date > "$marker"
echo "setup: git hooks installed from tools/hooks"
