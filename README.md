# xatc documentation

Source for the xatc documentation site: automated FAA-style voice ATC for X-Plane 12.
Built with [MkDocs Material](https://squidfunk.github.io/mkdocs-material/) and versioned
with [mike](https://github.com/jimporter/mike): each xatc release has its own copy of the
site, and a version selector sits next to the site title.

## Build locally

```bash
python -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt
mkdocs serve
```

`mkdocs build --strict` runs on every pull request, so a broken link fails the build.

## Versions and publishing

The site lives on the `gh-pages` branch, which GitHub Pages serves ("Deploy from a
branch": `gh-pages`, `/ (root)`). mike keeps one folder per version there:

| Version | Built from | Published by |
|---|---|---|
| `dev` | `main` | CI, on every push to `main` (`scripts/publish-docs.sh dev`) |
| `X.Y`, aliased `latest` | `main` at the time of app release `vX.Y.Z` | the owner, by hand, right after the GitHub Release |

The front page redirects to `latest` (or to `dev` until the first release is published).
Patch releases (0.7.1) redeploy their `X.Y` version; a patch to an older line leaves
`latest` where it is.

Publish the docs for an app release from an up-to-date, clean `main`:

```bash
git checkout main && git pull
scripts/publish-docs.sh 0.7.0 --dry-run   # show the mike commands
scripts/publish-docs.sh 0.7.0             # mike deploy --push --update-aliases 0.7 latest
                                          # mike set-default --push latest
```

Preview without publishing: `scripts/publish-docs.sh 0.7.0 --no-push` commits to your
local `gh-pages` branch only, then `mike serve` shows the site with its version selector
and `mike list` lists the versions. Reset a local preview with
`git branch -D gh-pages && git fetch origin gh-pages:gh-pages`.
