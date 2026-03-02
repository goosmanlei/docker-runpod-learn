#!/usr/bin/env bash
# build-push-commit.sh
# Build both Docker tags, push to Docker Hub, auto-commit to GitHub.
# Usage: ./build-push-commit.sh
set -euo pipefail

IMAGE="goosmanlei/runpod-learn"

TAGS=(
    "cu1281:runpod/pytorch:1.0.3-cu1281-torch280-ubuntu2404"
    "cu1241:runpod/pytorch:0.7.0-cu1241-torch240-ubuntu2204"
)

# ── 1. Build ────────────────────────────────────────────────────────────────
for entry in "${TAGS[@]}"; do
    tag="${entry%%:*}"
    base="${entry#*:}"
    echo "==> Building $IMAGE:$tag (base: $base)"
    docker build --platform linux/amd64 -f Dockerfile.runpod \
        --build-arg BASE_IMAGE="$base" \
        -t "$IMAGE:$tag" .
done

# ── 2. Push ─────────────────────────────────────────────────────────────────
for entry in "${TAGS[@]}"; do
    tag="${entry%%:*}"
    echo "==> Pushing $IMAGE:$tag"
    docker push "$IMAGE:$tag"
done

# ── 3. Commit & push to GitHub ───────────────────────────────────────────────
if git diff --quiet && git diff --cached --quiet; then
    echo "==> No changes to commit."
    exit 0
fi

echo "==> Generating commit message with claude -p ..."
DIFF=$(git diff; git diff --cached)

# claude -p cannot run inside a Claude Code session; unset the guard env var.
COMMIT_MSG=$(unset CLAUDECODE && echo "$DIFF" | claude -p \
    "You are helping write git commit messages. \
Read the following git diff and write a concise commit message for it. \
Follow conventional-commits style (feat/fix/docs/chore/refactor). \
Output ONLY the commit message text (subject line + optional blank line + body). \
Do not add any explanation, preamble, or code fences.")

echo "==> Commit message:"
echo "$COMMIT_MSG"
echo ""

git add -A
git commit -m "$COMMIT_MSG

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"

git push origin "$(git rev-parse --abbrev-ref HEAD)"
echo "==> Done."
