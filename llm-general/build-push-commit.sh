#!/usr/bin/env bash
set -euo pipefail

IMAGE="goosmanlei/runpod-learn-general"

# Format: tag:base_repository:base_tag:constraints:torch_constraints:torch_index_url
TAGS=(
    "cu1263:runpod/pytorch:0.7.0-cu1263-torch260-ubuntu2404:constraints-cu1263.txt:constraints-torch-cu1263.txt:https://download.pytorch.org/whl/cu126"
    "cu1281:runpod/pytorch:1.0.3-cu1281-torch280-ubuntu2404:constraints-cu1281.txt:constraints-torch-cu1281.txt:https://download.pytorch.org/whl/cu128"
)

PIN=false
for arg in "$@"; do
    [[ "$arg" == "--pin" ]] && PIN=true
done

for entry in "${TAGS[@]}"; do
    IFS=: read -r tag base_repo base_tag constraints torch_constraints torch_index <<< "$entry"
    base="$base_repo:$base_tag"
    echo "==> Building $IMAGE:$tag (base: $base, constraints: $constraints, torch: $torch_index)"
    docker build --platform linux/amd64 -f Dockerfile.runpod \
        --build-arg BASE_IMAGE="$base" \
        --build-arg CONSTRAINTS_FILE="$constraints" \
        --build-arg TORCH_CONSTRAINTS_FILE="$torch_constraints" \
        --build-arg TORCH_INDEX_URL="$torch_index" \
        -t "$IMAGE:$tag" .
done

if $PIN; then
    for entry in "${TAGS[@]}"; do
        IFS=: read -r tag base_repo base_tag constraints torch_constraints torch_index <<< "$entry"
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

for entry in "${TAGS[@]}"; do
    tag="${entry%%:*}"
    echo "==> Pushing $IMAGE:$tag"
    docker push "$IMAGE:$tag"
done

if git diff --quiet && git diff --cached --quiet; then
    echo "==> No changes to commit."
    exit 0
fi

git add -A
git commit -m "chore: update llm-general image files"
git push origin "$(git rev-parse --abbrev-ref HEAD)"
echo "==> Done."
