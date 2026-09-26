#!/usr/bin/env bash
set -euo pipefail

artifact=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact)
      shift
      artifact="${1:-}"
      ;;
    --artifact=*)
      artifact="${1#--artifact=}"
      ;;
    *)
      echo "SABLE_VERIFY=FAIL"
      echo "ERROR=unknown verify argument: $1" >&2
      exit 2
      ;;
  esac
  shift || true
done

if [ -z "${artifact}" ]; then
  echo "SABLE_VERIFY=FAIL_CLOSED"
  echo "REASON=missing --artifact path"
  echo "REQUIRED=artifact_path,artifact_manifest,sha256,device_release_identity"
  exit 2
fi

if [ ! -f "${artifact}" ]; then
  echo "SABLE_VERIFY=FAIL"
  echo "ARTIFACT=${artifact}"
  echo "REASON=artifact_not_found"
  exit 1
fi

echo "SABLE_VERIFY=DOCUMENTED_ONLY"
echo "DEVICE=${DEVICE}"
echo "RELEASE=${RELEASE}"
echo "ARTIFACT=${artifact}"
echo "ARTIFACT_SHA256=$(sha256sum "${artifact}" | awk '{print $1}')"
echo "NEXT=Compare against release artifact manifest once public packaging is qualified."
