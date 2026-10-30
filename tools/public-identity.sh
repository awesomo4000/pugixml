# shellcheck shell=sh disable=SC2034
# Identity used for everything pushed to the public GitHub repo.
# Sourced by tools/push-github.sh and tools/hooks/pre-push.

PUBLIC_NAME="awesomo4000"
PUBLIC_EMAIL="alrhodes@gmail.com"
PUBLIC_REMOTE="github"

# Emails allowed as author, committer or tagger on the public remote.
# noreply@github.com is the committer GitHub records for web-UI commits.
PUBLIC_ALLOWED_EMAILS="$PUBLIC_EMAIL noreply@github.com"
