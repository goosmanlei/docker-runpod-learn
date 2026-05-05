#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

IMAGE="goosmanlei/runpod-learn-general"

# Format: tag|base_image|constraints|torch_constraints|torch_index_url
TAGS=(
    "cu1263|runpod/pytorch:0.7.0-cu1263-torch260-ubuntu2404|constraints-cu1263.txt|constraints-torch-cu1263.txt|https://download.pytorch.org/whl/cu126"
    "cu1281|runpod/pytorch:1.0.3-cu1281-torch280-ubuntu2404|constraints-cu1281.txt|constraints-torch-cu1281.txt|https://download.pytorch.org/whl/cu128"
)

PIN=false
BUILD_ONLY=false
for arg in "$@"; do
    case "$arg" in
        --pin)
            PIN=true
            ;;
        --build-only)
            BUILD_ONLY=true
            ;;
        *)
            echo "Unknown argument: $arg" >&2
            echo "Usage: $0 [--pin] [--build-only]" >&2
            exit 2
            ;;
    esac
done

for entry in "${TAGS[@]}"; do
    IFS='|' read -r tag base constraints torch_constraints torch_index <<< "$entry"
    echo "==> Building $IMAGE:$tag"
    echo "    base: $base"
    echo "    constraints: $constraints"
    echo "    torch constraints: $torch_constraints"
    echo "    torch index: $torch_index"
    docker_cmd=(
        docker build --platform linux/amd64 -f Dockerfile.runpod
        --build-arg BASE_IMAGE="$base"
        --build-arg CONSTRAINTS_FILE="$constraints"
        --build-arg TORCH_CONSTRAINTS_FILE="$torch_constraints"
        --build-arg TORCH_INDEX_URL="$torch_index"
        -t "$IMAGE:$tag" .
    )
    "${docker_cmd[@]}"
done

if $PIN; then
    for entry in "${TAGS[@]}"; do
        IFS='|' read -r tag base constraints torch_constraints torch_index <<< "$entry"
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

if $BUILD_ONLY; then
    echo "==> Build complete. Skipping push and commit because --build-only was set."
    exit 0
fi

for entry in "${TAGS[@]}"; do
    IFS='|' read -r tag base constraints torch_constraints torch_index <<< "$entry"
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
