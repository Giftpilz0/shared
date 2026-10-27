#!/usr/bin/env bash
# Linearize a branch: drop bot commits (Renovate, Dependabot, GitHub Actions, Flux, Copilot, ...)
# and merge commits. Every kept commit keeps its exact tree, message, author and dates, so nothing
# can conflict: bot changes simply land in the next human commit. Bot changes after the last human
# commit become one "Dependency updates" commit. Rerunning is cheap: unchanged commits get the same hashes.
#
# usage: strip-bot-commits.sh [branch]        (default: main; run inside the repo)
#        BOT_RE='...' strip-bot-commits.sh    (override the author pattern, matched against "name <email>")
# then:  git push --force-with-lease origin <branch>
set -euo pipefail

branch=${1:-main}
bot_re=${BOT_RE:-'\[bot\]|dependabot|renovate|github action|^flux <|copilot'}

root=$(git rev-parse --show-toplevel)
cd "$root"
[ "$(git branch --show-current)" = "$branch" ] || {
    echo "❌ check out $branch first" >&2
    exit 1
}

# Bot PRs are merged on GitHub: the remote state must be part of local history
# (by tree, since a previous unpushed run rewrote the hashes).
git fetch -q origin "$branch"
if ! git merge-base --is-ancestor "origin/$branch" HEAD &&
    ! git log --format=%T HEAD | grep -qx "$(git rev-parse "origin/$branch^{tree}")"; then
    echo "❌ origin/$branch has changes that are not in $branch, run git pull first" >&2
    exit 1
fi

old=$(git rev-parse HEAD)
new=""
kept=0 dropped=0

while IFS=$'\x1f' read -r c parents author; do
    if [[ $parents == *" "* ]] || grep -qiE "$bot_re" <<<"$author"; then
        dropped=$((dropped + 1))
        continue
    fi
    IFS=$'\x1f' read -r an ae ad cn ce cd < <(git log -1 --format='%an%x1f%ae%x1f%aI%x1f%cn%x1f%ce%x1f%cI' "$c")
    # Exact message from the raw object (log --format=%B adds a newline, changing the hash on rerun)
    new=$(git cat-file commit "$c" | sed '1,/^$/d' |
        GIT_AUTHOR_NAME=$an GIT_AUTHOR_EMAIL=$ae GIT_AUTHOR_DATE=$ad \
            GIT_COMMITTER_NAME=$cn GIT_COMMITTER_EMAIL=$ce GIT_COMMITTER_DATE=$cd \
            git commit-tree "$c^{tree}" ${new:+-p "$new"})
    kept=$((kept + 1))
done < <(git log --reverse --first-parent --format='%H%x1f%P%x1f%an <%ae>' HEAD)

if [ -z "$new" ] || [ "$(git rev-parse "HEAD^{tree}")" != "$(git rev-parse "$new^{tree}")" ]; then
    new=$(echo "Dependency updates" | git commit-tree "HEAD^{tree}" ${new:+-p "$new"})
fi

if [ "$new" = "$old" ]; then
    echo "✅ already clean ($kept commits)"
    exit 0
fi

stamp=$(date +%Y%m%d-%H%M%S)
bundle="$(dirname "$root")/$(basename "$root")-$stamp.bundle"
git bundle create -q "$bundle" --all
backup="backup/$branch-$stamp"
git branch "$backup" "$old"
# Same tree as before: staged and unstaged changes stay untouched
git reset -q --soft "$new"

echo "✅ $branch: kept $kept commits, dropped $dropped bot/merge commits, final tree unchanged"
echo "   old state: $backup (delete with: git branch -D $backup)"
echo "   bundle:    $bundle (restore with: git clone $bundle)"

orphaned=$(git for-each-ref --format='%(refname:short)' --merged "$old" --no-merged "$new" refs/tags)
if [ -n "$orphaned" ]; then
    echo "⚠️  these tags point to rewritten commits and would no longer be on $branch:"
    while IFS= read -r tag; do echo "     $tag"; done <<<"$orphaned"
fi

echo "   publish:   git push --force-with-lease origin $branch"
