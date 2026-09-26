#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF_USAGE'
Usage:
  build/sable.sh <device> <release> <function> [options]

Examples:
  build/sable.sh panther R9 env-check
  build/sable.sh panther R9 source-sync
  build/sable.sh panther R9 flash-plan
  build/sable.sh panther R9 self-test
  build/sable.sh titan2 N0 build-image

Functions:
  env-check
  source-sync
  source-verify
  build-image
  build-apps
  sign
  verify
  package
  flash-plan
  self-test
EOF_USAGE
}

fail() {
  echo "SABLE_BUILD_FOUNDATION=FAIL"
  echo "ERROR=$*" >&2
  exit 2
}

if [ "$#" -lt 3 ]; then
  usage >&2
  fail "missing required device, release or function"
fi

DEVICE="$1"
RELEASE="$2"
FUNCTION="$3"
shift 3

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${SCRIPT_DIR}/devices/${DEVICE}/${RELEASE}.env"

case "${DEVICE}" in
  panther|titan2|titan2-elite|q27) ;;
  *) fail "unknown device: ${DEVICE}" ;;
esac

case "${FUNCTION}" in
  env-check|source-sync|source-verify|build-image|build-apps|sign|verify|package|flash-plan|self-test) ;;
  *) fail "unknown function: ${FUNCTION}" ;;
esac

if [ ! -f "${CONFIG}" ]; then
  fail "unsupported device/release pair: ${DEVICE}/${RELEASE}"
fi

# shellcheck disable=SC1090
source "${CONFIG}"

export DEVICE RELEASE FUNCTION SCRIPT_DIR CONFIG
export DEVICE_STATUS ARTIFACT_KIND BUILD_IMAGE_PUBLIC SIGNING_PUBLIC FLASH_PUBLIC
export REPRODUCIBILITY_STATUS FAIL_CLOSED_REASON

case "${FUNCTION}" in
  env-check)
    exec bash "${SCRIPT_DIR}/lib/sable/env-check.sh" "$@"
    ;;
  source-sync)
    exec bash "${SCRIPT_DIR}/lib/sable/source.sh" sync "$@"
    ;;
  source-verify)
    exec bash "${SCRIPT_DIR}/lib/sable/source.sh" verify "$@"
    ;;
  build-image)
    if [ "${BUILD_IMAGE_PUBLIC}" != "YES" ]; then
      echo "SABLE_BUILD_IMAGE=FAIL_CLOSED"
      echo "DEVICE=${DEVICE}"
      echo "RELEASE=${RELEASE}"
      echo "REASON=${FAIL_CLOSED_REASON}"
      exit 3
    fi
    exec bash "${SCRIPT_DIR}/lib/sable/source.sh" build-image "$@"
    ;;
  build-apps)
    echo "SABLE_BUILD_APPS=FAIL_CLOSED"
    echo "REASON=public_app_build_wiring_not_yet_qualified"
    exit 3
    ;;
  sign)
    exec bash "${SCRIPT_DIR}/lib/sable/signing.sh" "$@"
    ;;
  verify)
    exec bash "${SCRIPT_DIR}/lib/sable/verify.sh" "$@"
    ;;
  package)
    echo "SABLE_PACKAGE=FAIL_CLOSED"
    echo "REASON=public_artifact_registry_packaging_not_yet_qualified"
    exit 3
    ;;
  flash-plan)
    echo "SABLE_FLASH_PLAN=INFO"
    echo "DEVICE=${DEVICE}"
    echo "RELEASE=${RELEASE}"
    echo "DEVICE_STATUS=${DEVICE_STATUS}"
    echo "ARTIFACT_KIND=${ARTIFACT_KIND}"
    echo "FLASH_PUBLIC=${FLASH_PUBLIC}"
    echo "REASON=${FAIL_CLOSED_REASON}"
    ;;
  self-test)
    exec bash "${SCRIPT_DIR}/lib/sable/self-test.sh" "$@"
    ;;
esac
