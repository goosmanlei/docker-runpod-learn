#!/usr/bin/env bash
# build-push-commit.sh
# Build both Docker tags, push to Docker Hub, auto-commit to GitHub.
# Usage: ./build-push-commit.sh [--pin]
#   --pin  Build images then freeze pip packages into constraints-<tag>.txt.
#          Does NOT push or commit — review the files, then run normally.
set -euo pipefail

IMAGE="goosmanlei/runpod-learn-hf"

# Format: tag:base1:base2:constraints:flash_attn_file:torch_index_url
# flash_attn_file: per-tag file containing a pre-built wheel URL (empty file = skip)
TAGS=(
    "cu1241:runpod/pytorch:0.7.0-cu1241-torch240-ubuntu2204:constraints-cu1241.txt:flash-attn-cu1241.txt:https://download.pytorch.org/whl/cu124"
    "cu1281:runpod/pytorch:1.0.3-cu1281-torch280-ubuntu2404:constraints-cu1281.txt:flash-attn-cu1281.txt:https://download.pytorch.org/whl/cu128"
)

PIN=false
for arg in "$@"; do
    [[ "$arg" == "--pin" ]] && PIN=true
done

# ── 1. Build ────────────────────────────────────────────────────────────────
for entry in "${TAGS[@]}"; do
    IFS=: read -r tag base1 base2 constraints flash_attn_file torch_index <<< "$entry"
    base="$base1:$base2"
    echo "==> Building $IMAGE:$tag (base: $base, constraints: $constraints, torch: $torch_index)"
    docker build --platform linux/amd64 -f Dockerfile.runpod \
        --build-arg BASE_IMAGE="$base" \
        --build-arg CONSTRAINTS_FILE="$constraints" \
        --build-arg FLASH_ATTN_FILE="$flash_attn_file" \
        --build-arg TORCH_INDEX_URL="$torch_index" \
        -t "$IMAGE:$tag" .
done

# ── 1b. Pin (--pin only) ─────────────────────────────────────────────────────
if $PIN; then
    for entry in "${TAGS[@]}"; do
        IFS=: read -r tag base1 base2 constraints flash_attn_file torch_index <<< "$entry"
        echo "==> Pinning $IMAGE:$tag -> $constraints"
        docker run --rm "$IMAGE:$tag" \
            bash -c '$CONDA_ENV_PATH/bin/pip freeze --exclude-editable' \
            | grep -v ' @ file:///' \
            | grep -v '^\[' \
            > "$constraints"
        echo "    $(wc -l < "$constraints") packages written to $constraints"
    done
    echo ""
    echo "==> Constraints updated. Rebuild without --pin to lock versions in."
    exit 0
fi

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
