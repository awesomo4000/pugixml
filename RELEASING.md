# Development and releases

## Remotes

This repo has two remotes:

- `origin`: the primary repo. Commit and push here as usual, with this
  clone's own git identity.
- `github`: the public repo at github.com/awesomo4000/pugixml. Everything
  on it carries the public identity in `tools/public-identity.sh`, so its
  commits are copies of `origin`'s with the author, committer and tagger
  rewritten. The hashes differ and the two histories share no commits;
  the file contents are identical.

Never `git push github` directly. Use the mise tasks below.

## Setup

`mise run setup` points git at `tools/hooks`. You rarely need to run it by
hand: entering the repo in a shell with `mise activate` runs it, and so
does every mise task. It writes a gitignored `.mise-setup` marker and is
silent once that and the hook setting are in place.

The `pre-push` hook checks every push to github.com: each new commit's
author and committer, and each tag's tagger, must be on the allowlist in
`tools/public-identity.sh`. Anything else is refused. `git push
--no-verify` skips it, so don't use that.

## Day to day

```
git push origin main
mise run push:github
```

`push:github` finds the newest commit on `main` whose files match the tip
of `github/main`, re-creates each later commit with the public identity
(same files, message and dates) and pushes them. Running it again when
nothing is new does nothing.

If someone commits on GitHub directly (for example through the web UI), the
trees no longer match and `push:github` stops with a "diverged" error
rather than overwrite it. Make the same change on `origin` first.

## Releasing

1. Bump `.version` in `build.zig.zon` and commit it, for example
   "Bump version to X.Y.Z".
2. `mise run check`
3. Push `main` to both remotes:

   ```
   git push origin main
   mise run push:github
   ```

4. Tag on `origin`. Tags are annotated, with a message of the form
   "Version X.Y.Z - short summary":

   ```
   git tag -a vX.Y.Z -m "Version X.Y.Z - ..."
   git push origin vX.Y.Z
   ```

5. Tag on GitHub. This makes a tag with the same name and message,
   tagged by the public identity, on the matching public commit:

   ```
   mise run tag:github -- vX.Y.Z
   ```

Local tags are the `origin` versions, so never push tags to `github`
directly (`git push github --tags`). The hook refuses them anyway.
