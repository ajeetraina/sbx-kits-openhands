#!/usr/bin/env bash
set -euo pipefail

namespace="${DOCKERHUB_NAMESPACE:-${DOCKER_NAMESPACE:-ajeetraina777}}"
tag="${TAG:-latest}"
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
image="docker.io/$namespace/sbx-openhands-kits"

# publish SPEC_DIR IMAGE_TAG README_FILE [FILES_DIR]
# Stages a kit (spec.yaml + README + LICENSE), validates it, and pushes one tag.
# If FILES_DIR is given, its whole tree is staged as the kit's files/ dir - the
# sbx-kits-contrib convention where everything under files/home is mirrored into
# /home/agent/ in the sandbox. That's how the runbooks ship without being
# hard-coded into spec.yaml: drop a file in files/home/runbooks/, no spec edit.
#
# The canonical files/ tree lives at the repo root, so `sbx run --kit ./` picks
# it up directly for local testing. Every tag ships the same runbooks since they
# read their target from the env the kit sets up.
publish() {
  local spec_dir="$1" image_tag="$2" readme="$3" files_dir="${4:-}"
  local stage
  stage="$(mktemp -d /tmp/openhands-kits-push.XXXXXX)"
  mkdir -p "$stage/openhands"
  cp "$spec_dir/spec.yaml" "$stage/openhands/spec.yaml"
  cp "$readme" "$stage/openhands/README.md"
  cp "$repo_root/LICENSE" "$stage/openhands/LICENSE"
  if [ -n "$files_dir" ] && [ -d "$files_dir" ]; then
    cp -R "$files_dir" "$stage/openhands/files"
  fi
  sbx kit validate "$stage/openhands"
  sbx kit push "$stage/openhands" "$image:$image_tag"
  rm -rf "$stage"
  echo "Pushed $image:$image_tag"
}

# Default kit (anthropic) at the repo root -> :$tag (default :latest), with the
# canonical files/ tree (runbooks).
publish "$repo_root" "$tag" "$repo_root/README.md" "$repo_root/files"

# Per-provider kits under kits/ -> :<provider> (e.g. :anthropic, :openai, :dmr).
# Each tag uses its provider doc as the image README. Those docs use repo-relative
# links; fine on GitHub, cosmetic-only on the Hub page.
for dir in "$repo_root"/kits/*/; do
  target="$(basename "$dir")"
  readme="$repo_root/providers/$target.md"
  [ -f "$readme" ] || readme="$repo_root/README.md"
  publish "$dir" "$target" "$readme" "$repo_root/files"
done
