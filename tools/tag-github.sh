#!/bin/sh
# Publish an annotated tag to the public GitHub repo under the public identity.
#
# usage: tools/tag-github.sh vX.Y.Z
#
# The tag must already exist locally. Its commit's public twin is the
# first-parent commit on github/main with the same tree (run push:github
# first). The public tag gets the same name and message, tagged by the
# public identity.
set -eu

. "$(git rev-parse --show-toplevel)/tools/public-identity.sh"

tag="${1:?usage: tag-github.sh vX.Y.Z}"
remote_ref="refs/remotes/$PUBLIC_REMOTE/main"

git fetch --quiet --no-tags "$PUBLIC_REMOTE" main
tree=$(git rev-parse "$tag^{tree}")

twin=""
for c in $(git rev-list --first-parent "$remote_ref"); do
    if [ "$(git rev-parse "$c^{tree}")" = "$tree" ]; then
        twin=$c
        break
    fi
done

if [ -z "$twin" ]; then
    echo "tag-github: no commit on $PUBLIC_REMOTE/main matches $tag; run mise run push:github first" >&2
    exit 1
fi

message=$(git for-each-ref --format='%(contents)' "refs/tags/$tag")
if [ -z "$message" ]; then
    echo "tag-github: $tag is not an annotated tag" >&2
    exit 1
fi

tag_obj=$(
    printf 'object %s\ntype commit\ntag %s\ntagger %s <%s> %s\n\n%s\n' \
        "$twin" "$tag" "$PUBLIC_NAME" "$PUBLIC_EMAIL" \
        "$(git for-each-ref --format='%(taggerdate:raw)' "refs/tags/$tag")" \
        "$message" |
        git mktag
)

git push "$PUBLIC_REMOTE" "$tag_obj:refs/tags/$tag"
