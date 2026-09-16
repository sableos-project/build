#!/usr/bin/env bash
set -euo pipefail

# Read-only audit of one trusted standalone APK before Android product integration.
# The caller supplies the exact APK and optional Android/NDK tools. This script
# creates evidence only under EVIDENCE_DIR and does not mutate source, build
# outputs, devices, signing state, or the APK under test.

APK="${APK:-}"
STAMP="${STAMP:-$(date +%Y%m%d_%H%M%S)}"
EVIDENCE_DIR="${EVIDENCE_DIR:-/tmp/SABLE_R8_APP_ARTIFACT_AUDIT_${STAMP}}"
LLVM_READELF="${LLVM_READELF:-}"
LLVM_NM="${LLVM_NM:-}"
ZIPALIGN="${ZIPALIGN:-}"
EXPECTED_PACKAGE="${EXPECTED_PACKAGE:-}"

mkdir -p "$EVIDENCE_DIR"
REPORT="$EVIDENCE_DIR/r8_app_artifact_audit.log"
exec > >(tee "$REPORT") 2>&1

fail() {
  echo "R8_APP_ARTIFACT_AUDIT=FAIL"
  echo "FAIL_REASON=$*"
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

printf '%s\n' "===== SABLE R8 TRUSTED APP ARTIFACT AUDIT ====="
printf '%s\n' "SOURCE_MUTATION_AUTHORIZED=NO"
printf '%s\n' "WORKSPACE_OUTPUT_MUTATION_AUTHORIZED=NO"
printf '%s\n' "BUILD_AUTHORIZED=NO"
printf '%s\n' "NETWORK_ACCESS_AUTHORIZED=NO"
printf '%s\n' "DEVICE_CONTACT_AUTHORIZED=NO"
printf '%s\n' "SIGNING_AUTHORIZED=NO"
printf '%s\n' "CLEAN_CLOBBER_DELETE_AUTHORIZED=NO"
printf '%s\n' "TMP_EVIDENCE_MUTATION=YES_EVIDENCE_DIR_ONLY"
printf 'APK=%s\n' "$APK"
printf 'EVIDENCE_DIR=%s\n' "$EVIDENCE_DIR"

[ -n "$APK" ] || fail "APK must be supplied"
[ -f "$APK" ] || fail "APK not found: $APK"
need_cmd sha256sum
need_cmd unzip
need_cmd python3

printf '%s\n' "===== WHOLE APK IDENTITY ====="
sha256sum "$APK" | tee "$EVIDENCE_DIR/apk_sha256.txt"
stat --printf='size=%s\nmode=%a\nmtime=%y\n' "$APK" | tee "$EVIDENCE_DIR/apk_stat.txt"

printf '%s\n' "===== ZIP INVENTORY ====="
unzip -Z1 "$APK" | LC_ALL=C sort | tee "$EVIDENCE_DIR/zip_inventory.txt"

python3 - "$APK" "$EVIDENCE_DIR" <<'PY'
import hashlib
import json
import pathlib
import sys
import zipfile

apk = pathlib.Path(sys.argv[1])
out = pathlib.Path(sys.argv[2])
records = []
with zipfile.ZipFile(apk, 'r') as zf:
    for info in sorted(zf.infolist(), key=lambda i: i.filename):
        if info.is_dir():
            continue
        is_dex = info.filename.startswith('classes') and info.filename.endswith('.dex')
        is_so = info.filename.startswith('lib/') and info.filename.endswith('.so')
        if not (is_dex or is_so):
            continue
        data = zf.read(info.filename)
        records.append({
            'path': info.filename,
            'sha256': hashlib.sha256(data).hexdigest(),
            'size': len(data),
            'compress_type': info.compress_type,
            'compressed_size': info.compress_size,
        })

(out / 'inner_content.json').write_text(json.dumps(records, indent=2) + '\n', encoding='utf-8')
with (out / 'inner_content_sha256.txt').open('w', encoding='utf-8') as fh:
    for r in records:
        fh.write(f"{r['sha256']}  {r['path']}\n")

abis = sorted({r['path'].split('/')[1] for r in records if r['path'].startswith('lib/')})
(out / 'native_abis.txt').write_text(('\n'.join(abis) + '\n') if abis else 'NONE\n', encoding='utf-8')
print(f"R8_APP_ARTIFACT_INNER_MEMBER_COUNT={len(records)}")
print(f"R8_APP_ARTIFACT_NATIVE_ABIS={','.join(abis) if abis else 'NONE'}")
PY

cat "$EVIDENCE_DIR/inner_content_sha256.txt"
cat "$EVIDENCE_DIR/native_abis.txt"

printf '%s\n' "===== NATIVE ELF 16K COMPATIBILITY ====="
SO_COUNT=0
ELF_CHECKED=0
ELF_16K_PASS=0
DYNAMIC_INSPECTED=0
TMP_EXTRACT="$EVIDENCE_DIR/native_extract"
mkdir -p "$TMP_EXTRACT"
while IFS= read -r member; do
  case "$member" in
    lib/*.so)
      SO_COUNT=$((SO_COUNT + 1))
      out="$TMP_EXTRACT/${member//\//__}"
      unzip -p "$APK" "$member" > "$out"
      if [ -n "$LLVM_READELF" ]; then
        [ -x "$LLVM_READELF" ] || fail "LLVM_READELF is not executable: $LLVM_READELF"
        ELF_CHECKED=$((ELF_CHECKED + 1))
        dump="$EVIDENCE_DIR/readelf_${SO_COUNT}.txt"
        "$LLVM_READELF" -lW "$out" | tee "$dump" || fail "readelf failed for $member"
        if ! python3 - "$dump" <<'PY'
import sys

ok = True
seen = False
for line in open(sys.argv[1], encoding='utf-8', errors='replace'):
    if not line.lstrip().startswith('LOAD'):
        continue
    seen = True
    fields = line.split()
    try:
        align = int(fields[-1], 0)
    except Exception:
        ok = False
        continue
    if align < 0x4000:
        ok = False
if not seen or not ok:
    raise SystemExit(1)
PY
        then
          fail "native library is not 16 KiB PT_LOAD aligned: $member"
        fi
        ELF_16K_PASS=$((ELF_16K_PASS + 1))

        "$LLVM_READELF" -dW "$out" > "$EVIDENCE_DIR/dynamic_${SO_COUNT}.txt" \
          || fail "dynamic-section inspection failed for $member"
        DYNAMIC_INSPECTED=$((DYNAMIC_INSPECTED + 1))
      fi

      if [ -n "$LLVM_NM" ]; then
        [ -x "$LLVM_NM" ] || fail "LLVM_NM is not executable: $LLVM_NM"
        "$LLVM_NM" -u "$out" > "$EVIDENCE_DIR/undefined_symbols_${SO_COUNT}.txt" \
          || fail "undefined-symbol inventory failed for $member"
      fi
      ;;
  esac
done < "$EVIDENCE_DIR/zip_inventory.txt"

echo "R8_APP_ARTIFACT_NATIVE_SO_COUNT=$SO_COUNT"
if [ "$SO_COUNT" -eq 0 ]; then
  echo "R8_APP_ARTIFACT_ELF_16K_COMPATIBILITY=NOT_APPLICABLE"
  echo "R8_APP_ARTIFACT_DYNAMIC_DEPENDENCY_INVENTORY=NOT_APPLICABLE"
elif [ -z "$LLVM_READELF" ]; then
  echo "R8_APP_ARTIFACT_ELF_16K_COMPATIBILITY=NOT_TESTED"
  echo "R8_APP_ARTIFACT_DYNAMIC_DEPENDENCY_INVENTORY=NOT_TESTED"
else
  [ "$ELF_CHECKED" -eq "$SO_COUNT" ] || fail "not all native libraries were checked"
  [ "$ELF_16K_PASS" -eq "$SO_COUNT" ] || fail "one or more native libraries are not 16 KiB compatible"
  [ "$DYNAMIC_INSPECTED" -eq "$SO_COUNT" ] || fail "not all native dynamic sections were inspected"
  echo "R8_APP_ARTIFACT_ELF_16K_COMPATIBILITY=PASS"
  echo "R8_APP_ARTIFACT_DYNAMIC_DEPENDENCY_INVENTORY=PASS"
fi

if [ "$SO_COUNT" -eq 0 ]; then
  echo "R8_APP_ARTIFACT_UNDEFINED_SYMBOL_INVENTORY=NOT_APPLICABLE"
elif [ -z "$LLVM_NM" ]; then
  echo "R8_APP_ARTIFACT_UNDEFINED_SYMBOL_INVENTORY=NOT_TESTED"
else
  echo "R8_APP_ARTIFACT_UNDEFINED_SYMBOL_INVENTORY=PASS"
fi

printf '%s\n' "===== APK ZIPALIGN 16K CHECK ====="
if [ "$SO_COUNT" -eq 0 ]; then
  echo "R8_APP_ARTIFACT_APK_16K_ZIPALIGN=NOT_APPLICABLE"
elif [ -z "$ZIPALIGN" ]; then
  echo "R8_APP_ARTIFACT_APK_16K_ZIPALIGN=NOT_TESTED"
else
  [ -x "$ZIPALIGN" ] || fail "ZIPALIGN is not executable: $ZIPALIGN"
  "$ZIPALIGN" -c -P 16 -v 4 "$APK" | tee "$EVIDENCE_DIR/zipalign_16k.txt" \
    || fail "APK failed 16 KiB zipalign verification"
  echo "R8_APP_ARTIFACT_APK_16K_ZIPALIGN=PASS"
fi

printf '%s\n' "===== OPTIONAL PACKAGE IDENTITY ====="
if [ -n "$EXPECTED_PACKAGE" ]; then
  echo "EXPECTED_PACKAGE=$EXPECTED_PACKAGE"
  echo "R8_APP_ARTIFACT_PACKAGE_NAME=UNPROVEN_BY_THIS_SCRIPT"
fi

printf '%s\n' "===== FINAL EVIDENCE SEAL ====="
(
  cd "$EVIDENCE_DIR"
  find . -type f \
    ! -name 'r8_app_artifact_audit.log' \
    ! -name 'SHA256SUMS.txt' \
    ! -name 'SHA256SUMS.txt.sha256' \
    -printf '%P\0' \
    | sort -z \
    | xargs -0 -r sha256sum
) > "$EVIDENCE_DIR/SHA256SUMS.txt"
sha256sum "$EVIDENCE_DIR/SHA256SUMS.txt" | tee "$EVIDENCE_DIR/SHA256SUMS.txt.sha256"

echo "R8_APP_ARTIFACT_AUDIT=PASS"
echo "CLAIM_BOUNDARY=read-only APK/container/content/native-alignment/dynamic-dependency audit; package manifest semantics, Soong import, product selection, target-files, image membership and runtime remain separate gates"
echo "Evidence: $EVIDENCE_DIR"
