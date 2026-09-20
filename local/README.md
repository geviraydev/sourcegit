# local/ - fork maintenance helpers

Local-only helpers for this fork. This folder is excluded from git in the
working tree via `.git/info/exclude`, so it can never end up in a PR.

## sync-and-install.sh

Rebases `feat/diff-line-totals` onto `upstream/develop`, force-pushes the
result to this fork, then rebuilds and reinstalls the local SourceGit build
into `~/.local/opt/sourcegit`.

Run from anywhere:

```
sourcegit-fork-update
```

or from the repo:

```
git fork-update
local/sync-and-install.sh
```

There is also a `SourceGit Update (fork build)` entry in the KDE app menu that
runs this script in a terminal.

Options:

```
--no-push     sync only (no force-push)
--no-build    push only (no rebuild/install)
--aot         publish with NativeAOT (requires clang)
--help        usage
```

If the rebase hits conflicts the script stops; resolve them, run
`git rebase --continue`, then run the script again.

## Backup copy

The same files are mirrored on the `local-tools` branch of this fork, which is
never part of a PR. If this folder disappears (fresh clone, `git clean`, moving
machines), restore it with:

```
git fetch origin local-tools
git checkout origin/local-tools -- local/
echo 'local/' >> .git/info/exclude
```

Do not commit this folder to the feature branch. If the script is edited,
update the mirror:

```
git fetch origin local-tools
git worktree add --detach /tmp/local-tools origin/local-tools
cp local/* /tmp/local-tools/local/
git -C /tmp/local-tools add -f local
git -C /tmp/local-tools commit -m "chore: update local helpers"
git -C /tmp/local-tools push origin local-tools
git worktree remove --force /tmp/local-tools
```
