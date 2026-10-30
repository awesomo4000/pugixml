#!/bin/sh
# Publish main to the public GitHub repo under the public identity.
#
# The public history is a copy of main with every commit re-authored, so
# the two have different hashes. Find the newest commit on main whose tree
# matches the public tip, then re-create each later first-parent commit with
# the same tree, message and dates but the public identity. Re-running is
# idempotent: the same input produces the same hashes.
set -eu

. "$(git rev-parse --show-toplevel)/tools/public-identity.sh"

branch="${1:-main}"
remote_ref="refs/remotes/$PUBLIC_REMOTE/main"

git fetch --quiet --no-tags "$PUBLIC_REMOTE" main
public_tip=$(git rev-parse "$remote_ref")
public_tree=$(git rev-parse "$public_tip^{tree}")

base=""
for c in $(git rev-list --first-parent "$branch"); do
    if [ "$(git rev-parse "$c^{tree}")" = "$public_tree" ]; then
        base=$c
        break
    fi
done

if [ -z "$base" ]; then
    echo "push-github: no commit on $branch matches $PUBLIC_REMOTE/main; histories have diverged" >&2
    exit 1
fi

commits=$(git rev-list --reverse --first-parent "$base..$branch")
if [ -z "$commits" ]; then
    echo "push-github: $PUBLIC_REMOTE/main is up to date"
    exit 0
fi

parent=$public_tip
for c in $commits; do
    parent=$(
        GIT_AUTHOR_NAME="$PUBLIC_NAME" GIT_AUTHOR_EMAIL="$PUBLIC_EMAIL" \
        GIT_AUTHOR_DATE="$(git log -1 --format=%ad --date=raw "$c")" \
        GIT_COMMITTER_NAME="$PUBLIC_NAME" GIT_COMMITTER_EMAIL="$PUBLIC_EMAIL" \
        GIT_COMMITTER_DATE="$(git log -1 --format=%cd --date=raw "$c")" \
        git log -1 --format=%B "$c" | git commit-tree "$c^{tree}" -p "$parent"
    )
    git log -1 --format="%h %s" "$parent"
done

git push "$PUBLIC_REMOTE" "$parent:refs/heads/main"
