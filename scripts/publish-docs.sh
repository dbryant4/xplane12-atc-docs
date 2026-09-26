#!/usr/bin/env bash
set -euo pipefail

# Publishes one version of the docs site to the gh-pages branch with mike.
#
#   scripts/publish-docs.sh X.Y.Z   # an app release: deploys docs version X.Y. If X.Y is the
#                                   # newest release, also moves the "latest" alias to it and
#                                   # makes "latest" the site's default (front-page redirect).
#   scripts/publish-docs.sh dev     # main: deploys docs version "dev". Until a release exists,
#                                   # "dev" is also the default. CI runs this on every push to main.
#
# Options:
#   --dry-run   print the git/mike commands without running any of them
#   --no-push   commit to the local gh-pages branch only (to preview with `mike serve`)
#
# Release docs are published only with the owner's go-ahead, right after the matching
# GitHub Release of xatc (the app's scripts/release.sh prints this command).

usage() {
  echo "usage: $(basename "$0") X.Y.Z|dev [--dry-run] [--no-push]" >&2
  exit 2
}

[[ $# -ge 1 ]] || usage
TARGET="$1"
shift
DRY_RUN=false
PUSH=true
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --no-push) PUSH=false ;;
    *) usage ;;
  esac
done

MIKE="${MIKE:-mike}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

run() {
  echo "+ $*"
  if ! $DRY_RUN; then
    "$@"
  fi
}

# The site root's 404 page (site-root/404.html): redirects a pre-versioning link (no
# version in its path) to the same page under the default version. mike only manages the
# version folders, versions.json and the root index.html, so this keeps 404.html on
# gh-pages in step with the source after every deploy.
sync_root_404() {
  local src="$REPO_ROOT/site-root/404.html"
  [[ -f "$src" ]] || return 0
  if $DRY_RUN; then
    echo "+ (gh-pages: 404.html <- site-root/404.html, committed if changed)"
    return 0
  fi
  local wt
  wt="$(mktemp -d "${TMPDIR:-/tmp}/xatc-docs-gh-pages.XXXXXX")"
  git worktree add -q "$wt" gh-pages
  if ! cmp -s "$src" "$wt/404.html"; then
    cp "$src" "$wt/404.html"
    git -C "$wt" add 404.html
    git -C "$wt" commit -q -m "Root 404 page: send unversioned links to the default docs version"
    if $PUSH; then
      git -C "$wt" push -q origin gh-pages
    fi
  fi
  git worktree remove --force "$wt"
}

PUSH_ARGS=()
if $PUSH; then
  PUSH_ARGS=(--push)
fi

if [[ "$TARGET" == "dev" ]]; then
  DOC_VERSION="dev"
elif [[ "$TARGET" =~ ^([0-9]+)\.([0-9]+)(\.[0-9]+)?$ ]]; then
  DOC_VERSION="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
else
  usage
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "publish-docs.sh: working tree is dirty -- commit or stash first" >&2
  $DRY_RUN || exit 1
fi
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if $PUSH && [[ "$BRANCH" != "main" && "${GITHUB_REF_NAME:-}" != "main" ]]; then
  echo "publish-docs.sh: publish from main (currently on '${BRANCH}'), or use --no-push to preview" >&2
  $DRY_RUN || exit 1
fi
SHA="$(git rev-parse --short HEAD)"

# Start from what's already published, so this deploy adds to gh-pages instead of
# replacing it. Fast-forward only: a diverged local gh-pages stops here.
if git remote get-url origin >/dev/null 2>&1 && git ls-remote --exit-code --heads origin gh-pages >/dev/null 2>&1; then
  run git fetch origin gh-pages:gh-pages
fi

# The published versions, e.g. [{"version": "0.7", "aliases": ["latest"], ...}, ...].
PUBLISHED="$("$MIKE" list --json 2>/dev/null || echo '[]')"

if [[ "$DOC_VERSION" == "dev" ]]; then
  run "$MIKE" deploy ${PUSH_ARGS[@]+"${PUSH_ARGS[@]}"} --message "Deploy docs dev from ${SHA}" dev
  if ! python3 -c 'import json,sys; sys.exit(0 if any("latest" in v.get("aliases", []) for v in json.loads(sys.argv[1] or "[]")) else 1)' "$PUBLISHED"; then
    echo "==> No release published yet: the site's default is dev"
    run "$MIKE" set-default ${PUSH_ARGS[@]+"${PUSH_ARGS[@]}"} dev
  fi
  sync_root_404
  exit 0
fi

# Only the newest release gets "latest": a patch to an older line (0.6.1 after 0.7.0)
# updates its own version and leaves "latest" where it is.
IS_NEWEST="$(python3 - "$PUBLISHED" "$DOC_VERSION" <<'EOF'
import json, re, sys
published, candidate = json.loads(sys.argv[1] or "[]"), sys.argv[2]
key = lambda v: tuple(int(p) for p in v.split("."))
releases = [v["version"] for v in published if re.fullmatch(r"\d+\.\d+", v["version"])]
print("yes" if all(key(candidate) >= key(v) for v in releases) else "no")
EOF
)"

if [[ "$IS_NEWEST" == "yes" ]]; then
  run "$MIKE" deploy ${PUSH_ARGS[@]+"${PUSH_ARGS[@]}"} --update-aliases \
    --message "Deploy docs ${DOC_VERSION} (xatc ${TARGET}) from ${SHA}" "$DOC_VERSION" latest
  run "$MIKE" set-default ${PUSH_ARGS[@]+"${PUSH_ARGS[@]}"} latest
else
  echo "==> ${DOC_VERSION} is older than the newest published release: leaving 'latest' alone"
  run "$MIKE" deploy ${PUSH_ARGS[@]+"${PUSH_ARGS[@]}"} \
    --message "Deploy docs ${DOC_VERSION} (xatc ${TARGET}) from ${SHA}" "$DOC_VERSION"
fi

sync_root_404
