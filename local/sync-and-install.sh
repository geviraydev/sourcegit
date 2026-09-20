#!/usr/bin/env bash
#
# Local-only helper (excluded via .git/info/exclude).
# Syncs the fork's feature branch with upstream develop, force-pushes it,
# and rebuilds/installs the local SourceGit build.

set -euo pipefail

BRANCH=${BRANCH:-feat/diff-line-totals}
UPSTREAM_BRANCH=${UPSTREAM_BRANCH:-upstream/develop}
FORK_REMOTE=${FORK_REMOTE:-origin}
INSTALL_DIR=${INSTALL_DIR:-$HOME/.local/opt/sourcegit}
RUNTIME=${RUNTIME:-linux-x64}

DO_PUSH=1
DO_BUILD=1
USE_AOT=0

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

  --no-push     skip the force-push to the fork
  --no-build    skip publish/install (sync + push only)
  --aot         publish with NativeAOT (requires clang)
  -h, --help    show this help

Env overrides: BRANCH, UPSTREAM_BRANCH, FORK_REMOTE, INSTALL_DIR, RUNTIME
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-push)  DO_PUSH=0 ;;
        --no-build) DO_BUILD=0 ;;
        --aot)      USE_AOT=1 ;;
        -h|--help)  usage ;;
        *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
    shift
done

cd "$(dirname "$(readlink -f "$0")")/.."

step() { printf '\n==> %s\n' "$*"; }

if [[ -d .git/rebase-merge || -d .git/rebase-apply ]]; then
    echo "error: a rebase is already in progress."
    echo "Resolve the conflicts, run 'git rebase --continue', then re-run this script."
    exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
    echo "error: working tree is not clean:"
    git status --short
    exit 1
fi

step "Fetching $FORK_REMOTE and upstream"
git fetch "$FORK_REMOTE" --prune
git fetch upstream --prune --tags

step "Checking out $BRANCH"
git switch "$BRANCH"

step "Rebasing $BRANCH onto $UPSTREAM_BRANCH"
if ! git rebase "$UPSTREAM_BRANCH"; then
    printf '\nRebase stopped due to conflicts.\n'
    echo "Resolve them, run 'git rebase --continue', then re-run this script."
    exit 1
fi

if [[ $DO_PUSH -eq 1 ]]; then
    step "Force-pushing to $FORK_REMOTE/$BRANCH"
    git push --force-with-lease "$FORK_REMOTE" "$BRANCH"
fi

if [[ $DO_BUILD -eq 1 ]]; then
    rm -rf "$INSTALL_DIR.new"
    if [[ $USE_AOT -eq 1 ]]; then
        step "Publishing (NativeAOT)"
        dotnet publish src/SourceGit.csproj -c Release -r "$RUNTIME" \
            -o "$INSTALL_DIR.new" --nologo
    else
        step "Publishing (framework-dependent, DisableAOT)"
        dotnet publish src/SourceGit.csproj -c Release -r "$RUNTIME" \
            -p:DisableAOT=true -o "$INSTALL_DIR.new" --nologo
    fi

    if [[ -f "$INSTALL_DIR.new/SourceGit" && ! -f "$INSTALL_DIR.new/sourcegit" ]]; then
        mv "$INSTALL_DIR.new/SourceGit" "$INSTALL_DIR.new/sourcegit"
    fi

    step "Installing to $INSTALL_DIR"
    rm -rf "$INSTALL_DIR.old"
    if [[ -d "$INSTALL_DIR" ]]; then
        mv "$INSTALL_DIR" "$INSTALL_DIR.old"
    fi
    mv "$INSTALL_DIR.new" "$INSTALL_DIR"
    rm -rf "$INSTALL_DIR.old"

    printf '\nDone: %s\n' "$(git log -1 --format='%h %s')"
    echo "Restart SourceGit to pick up the new build."
fi
