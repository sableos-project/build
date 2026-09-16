#!/usr/bin/env bash
set -euo pipefail

# Host-only self-test for r8_app_artifact_audit.sh.
# It validates APK hashing/inventory plus positive and negative ELF-alignment
# behavior without requiring an Android SDK/NDK installation.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Baseline fixture: exercise inventory/sealing when Android-native tools are not supplied.
mkdir -p "$TMP/apk/lib/arm64-v8a"
printf 'dex-fixture\n' > "$TMP/apk/classes.dex"
printf 'not-an-elf-fixture\n' > "$TMP/apk/lib/arm64-v8a/libfixture.so"
(
  cd "$TMP/apk"
  zip -q -0 "$TMP/fixture.apk" classes.dex lib/arm64-v8a/libfixture.so
)

APK="$TMP/fixture.apk" \
EVIDENCE_DIR="$TMP/evidence" \
bash "$ROOT/gates/r8_app_artifact_audit.sh" > "$TMP/run.log" 2>&1

grep -Fx 'R8_APP_ARTIFACT_NATIVE_ABIS=arm64-v8a' "$TMP/run.log" >/dev/null
grep -Fx 'R8_APP_ARTIFACT_ELF_16K_COMPATIBILITY=NOT_TESTED' "$TMP/run.log" >/dev/null
grep -Fx 'R8_APP_ARTIFACT_DYNAMIC_DEPENDENCY_INVENTORY=NOT_TESTED' "$TMP/run.log" >/dev/null
grep -Fx 'R8_APP_ARTIFACT_APK_16K_ZIPALIGN=NOT_TESTED' "$TMP/run.log" >/dev/null
grep -Fx 'R8_APP_ARTIFACT_AUDIT=PASS' "$TMP/run.log" >/dev/null
[ -s "$TMP/evidence/inner_content.json" ]
[ -s "$TMP/evidence/SHA256SUMS.txt" ]
[ -s "$TMP/evidence/SHA256SUMS.txt.sha256" ]

# Alignment parser self-test: use host ELF files only to verify the gate logic.
# Real R8 acceptance still requires Android arm64-v8a binaries built with the pinned toolchain.
if command -v cc >/dev/null 2>&1 && command -v readelf >/dev/null 2>&1; then
  mkdir -p "$TMP/good/lib/arm64-v8a" "$TMP/bad/lib/arm64-v8a"
  printf 'int sable_fixture(void) { return 7; }\n' > "$TMP/fixture.c"
  printf 'dex-fixture\n' > "$TMP/good/classes.dex"
  printf 'dex-fixture\n' > "$TMP/bad/classes.dex"

  cc -shared -fPIC -Wl,-z,max-page-size=16384 \
    -o "$TMP/good/lib/arm64-v8a/libfixture.so" "$TMP/fixture.c"
  cc -shared -fPIC -Wl,-z,max-page-size=4096 \
    -o "$TMP/bad/lib/arm64-v8a/libfixture.so" "$TMP/fixture.c"

  (
    cd "$TMP/good"
    zip -q -0 "$TMP/good.apk" classes.dex lib/arm64-v8a/libfixture.so
  )
  (
    cd "$TMP/bad"
    zip -q -0 "$TMP/bad.apk" classes.dex lib/arm64-v8a/libfixture.so
  )

  APK="$TMP/good.apk" \
  EVIDENCE_DIR="$TMP/good_evidence" \
  LLVM_READELF="$(command -v readelf)" \
  bash "$ROOT/gates/r8_app_artifact_audit.sh" > "$TMP/good.log" 2>&1
  grep -Fx 'R8_APP_ARTIFACT_ELF_16K_COMPATIBILITY=PASS' "$TMP/good.log" >/dev/null
  grep -Fx 'R8_APP_ARTIFACT_DYNAMIC_DEPENDENCY_INVENTORY=PASS' "$TMP/good.log" >/dev/null
  grep -Fx 'R8_APP_ARTIFACT_AUDIT=PASS' "$TMP/good.log" >/dev/null

  if APK="$TMP/bad.apk" \
    EVIDENCE_DIR="$TMP/bad_evidence" \
    LLVM_READELF="$(command -v readelf)" \
    bash "$ROOT/gates/r8_app_artifact_audit.sh" > "$TMP/bad.log" 2>&1; then
    echo 'R8_APP_ARTIFACT_AUDIT_NEGATIVE_16K_TEST=FAIL'
    exit 1
  fi
  grep -Fx 'R8_APP_ARTIFACT_AUDIT=FAIL' "$TMP/bad.log" >/dev/null
  grep -F 'not 16 KiB PT_LOAD aligned' "$TMP/bad.log" >/dev/null
  echo 'R8_APP_ARTIFACT_AUDIT_NEGATIVE_16K_TEST=PASS'
else
  echo 'R8_APP_ARTIFACT_AUDIT_NEGATIVE_16K_TEST=NOT_TESTED'
fi

echo 'R8_APP_ARTIFACT_AUDIT_SELFTEST=PASS'
