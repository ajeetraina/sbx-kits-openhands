#!/usr/bin/env bash
set -euo pipefail

namespace="${DOCKERHUB_NAMESPACE:-${DOCKER_NAMESPACE:-ajeetraina777}}"
tag="${TAG:-latest}"
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
image="docker.io/$namespace/sbx-openhands-kits"

# publish SPEC_DIR IMAGE_TAG README_FILE
# Stages the kit (spec.yaml + README + LICENSE), validates it, and pushes one tag.
publish() {
  local spec_dir="$1" image_tag="$2" readme="$3"
  local stage
  stage="$(mktemp -d /tmp/openhands-kits-push.XXXXXX)"
  mkdir -p "$stage/openhands"
  cp "$spec_dir/spec.yaml" "$stage/openhands/spec.yaml"
  cp "$readme" "$stage/openhands/README.md"
  cp "$repo_root/LICENSE" "$stage/openhands/LICENSE"
  sbx kit validate "$stage/openhands"
  sbx kit push "$stage/openhands" "$image:$image_tag"
  rm -rf "$stage"
  echo "Pushed $image:$image_tag"
}

# Single kind: sandbox kit at the repo root -> :$tag (default :latest).
publish "$repo_root" "$tag" "$repo_root/README.md"
