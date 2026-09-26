#!/usr/bin/env bash
set -euo pipefail

mode="${1:-}"
shift || true

case "${mode}" in
  sync)
    echo "SABLE_SOURCE_SYNC=DOCUMENTED_ONLY"
    echo "DEVICE=${DEVICE}"
    echo "RELEASE=${RELEASE}"
    echo "ARTIFACT_KIND=${ARTIFACT_KIND}"
    echo "REPRODUCIBILITY_STATUS=${REPRODUCIBILITY_STATUS}"
    echo "NEXT=Use docs/BUILD.md and platform_manifest pins before claiming reproducibility."
    ;;
  verify)
    echo "SABLE_SOURCE_VERIFY=DOCUMENTED_ONLY"
    echo "DEVICE=${DEVICE}"
    echo "RELEASE=${RELEASE}"
    echo "REQUIRED=manifest_revision_checks,upstream_source_provenance,proprietary_input_inventory"
    echo "NEXT=Implement exact revision checks when public manifests are fully pinned."
    ;;
  build-image)
    echo "SABLE_BUILD_IMAGE=UNREACHABLE_WITH_CURRENT_CONFIG"
    echo "REASON=BUILD_IMAGE_PUBLIC must be YES before this path is active"
    exit 3
    ;;
  *)
    echo "SABLE_SOURCE=FAIL"
    echo "ERROR=unknown source mode: ${mode}" >&2
    exit 2
    ;;
esac
