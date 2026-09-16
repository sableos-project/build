#!/usr/bin/env bash
set -euo pipefail

# Host-only self-test for r8_app_artifact_audit.sh. It validates the read-only
# artifact hashing/inventory path without requiring Android SDK/NDK tools.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/apk/lib/arm64-v8a"
printf 'dex-fixture\n' > "$TMP/apk/classes.dex"
printf 'not-an-elf-fixture\n' > "$TMP/apk/lib/arm64-v8a/libfixture.so"
(
  cd "$TMP/apk"
  zip -q -0 "$TMP/fixture.apk" classes.dex lib/arm64-v8a/libfixture.so
)

APK="$TMP/fixture.apk" \
EVIDENCE_DIR="$TMP/evidence" \
"$ROOT/gates/r8_app_artifact_audit.sh" > "$TMP/run.log" 2>&1

grep -Fx 'R8_APP_ARTIFACT_NATIVE_ABIS=arm64-v8a' "$TMP/run.log" >/dev/null
grep -Fx 'R8_APP_ARTIFACT_ELF_16K_COMPATIBILITY=NOT_TESTED' "$TMP/run.log" >/dev/null
grep -Fx 'R8_APP_ARTIFACT_APK_16K_ZIPALIGN=NOT_TESTED' "$TMP/run.log" >/dev/null
grep -Fx 'R8_APP_ARTIFACT_AUDIT=PASS' "$TMP/run.log" >/dev/null
[ -s "$TMP/evidence/inner_content.json" ]
[ -s "$TMP/evidence/SHA256SUMS.txt" ]
[ -s "$TMP/evidence/SHA256SUMS.txt.sha256" ]

echo 'R8_APP_ARTIFACT_AUDIT_SELFTEST=PASS'
