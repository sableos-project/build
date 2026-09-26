#!/usr/bin/env bash
set -euo pipefail

mode=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --mode)
      shift
      mode="${1:-}"
      ;;
    --mode=*)
      mode="${1#--mode=}"
      ;;
    *)
      echo "SABLE_SIGN=FAIL"
      echo "ERROR=unknown signing argument: $1" >&2
      exit 2
      ;;
  esac
  shift || true
done

case "${mode}" in
  ""|dev|release-candidate|production) ;;
  *)
    echo "SABLE_SIGN=FAIL"
    echo "ERROR=unknown signing mode: ${mode}" >&2
    exit 2
    ;;
esac

echo "SABLE_SIGN=FAIL_CLOSED"
echo "DEVICE=${DEVICE}"
echo "RELEASE=${RELEASE}"
echo "REQUESTED_SIGNING_MODE=${mode:-unspecified}"
echo "SIGNING_PUBLIC=${SIGNING_PUBLIC}"
echo "REASON=public_signing_flow_not_yet_qualified_no_keys_or_credentials_are_published"
exit 3
