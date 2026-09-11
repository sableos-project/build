#!/usr/bin/env bash
set -euo pipefail

WS="${WS:-/srv/data/sableos_panther_graphene_2026081300_workspace}"
STAMP="${STAMP:-$(date +%Y%m%d_%H%M%S)}"
EVIDENCE_DIR="${EVIDENCE_DIR:-/tmp/SABLESTART_R5_R3A_MANIFEST_AUDIT_${STAMP}}"
TARGET_PATH="packages/apps/SableStart"
EXPECTED_UPSTREAM_TAG="2026081300"

mkdir -p "$EVIDENCE_DIR"
REPORT="$EVIDENCE_DIR/r5_r3a_manifest_audit.log"
exec > >(tee "$REPORT") 2>&1

echo "===== SABLESTART R5-R3A READ-ONLY MANIFEST AUDIT ====="
echo "SOURCE_MUTATION_AUTHORIZED=NO"
echo "WORKSPACE_OUTPUT_MUTATION_AUTHORIZED=NO"
echo "BUILD_AUTHORIZED=NO"
echo "NETWORK_ACCESS_AUTHORIZED=NO"
echo "DEVICE_CONTACT_AUTHORIZED=NO"
echo "PACKAGE_INSTALL_AUTHORIZED=NO"
echo "CLEAN_CLOBBER_AUTHORIZED=NO"
echo "DELETE_AUTHORIZED=NO"
echo "GIT_HISTORY_MUTATION_AUTHORIZED=NO"
echo "TMP_EVIDENCE_MUTATION=YES_EVIDENCE_DIR_ONLY"
echo "WS=$WS"
echo "EVIDENCE_DIR=$EVIDENCE_DIR"
echo "TARGET_PATH=$TARGET_PATH"

fail() {
  echo "SABLESTART_R5_R3A_AUDIT=FAIL"
  echo "FAIL_REASON=$*"
  exit 1
}

[ -d "$WS" ] || fail "workspace missing"
[ -d "$WS/.repo" ] || fail ".repo metadata missing"
[ -d "$WS/.repo/manifests" ] || fail ".repo/manifests missing"
echo "SABLESTART_R5_R3A_WS_PRESENT=PASS"
echo "SABLESTART_R5_R3A_REPO_METADATA_PRESENT=PASS"

if command -v repo >/dev/null 2>&1; then
  REPO_BIN="$(command -v repo)"
elif [ -x "$WS/.repo/repo/repo" ]; then
  REPO_BIN="$WS/.repo/repo/repo"
else
  fail "repo executable not found"
fi

echo "REPO_BIN=$REPO_BIN"
"$REPO_BIN" --version | tee "$EVIDENCE_DIR/repo_version.txt" || fail "repo --version failed"

echo
printf '%s\n' "===== MANIFEST POINTER ====="
ls -ld "$WS/.repo/manifest.xml" | tee "$EVIDENCE_DIR/manifest_pointer_ls.txt" || fail "manifest.xml missing"
readlink "$WS/.repo/manifest.xml" | tee "$EVIDENCE_DIR/manifest_pointer_raw.txt" || true
ACTIVE_MANIFEST="$(readlink -f "$WS/.repo/manifest.xml")"
[ -n "$ACTIVE_MANIFEST" ] || fail "cannot resolve manifest.xml"
printf '%s\n' "$ACTIVE_MANIFEST" | tee "$EVIDENCE_DIR/manifest_pointer_resolved.txt"
sha256sum "$ACTIVE_MANIFEST" | tee "$EVIDENCE_DIR/active_manifest_sha256.txt"

echo
printf '%s\n' "===== MANIFEST REPOSITORY IDENTITY ====="
MANIFEST_GIT="$WS/.repo/manifests"
git -C "$MANIFEST_GIT" status --short --branch | tee "$EVIDENCE_DIR/manifest_git_status.txt"
git -C "$MANIFEST_GIT" rev-parse HEAD | tee "$EVIDENCE_DIR/manifest_git_head.txt"
git -C "$MANIFEST_GIT" remote -v | tee "$EVIDENCE_DIR/manifest_git_remotes.txt"
git -C "$MANIFEST_GIT" branch --show-current | tee "$EVIDENCE_DIR/manifest_git_branch.txt"
git -C "$MANIFEST_GIT" describe --tags --exact-match HEAD 2>/dev/null | tee "$EVIDENCE_DIR/manifest_git_exact_tag.txt" || true

MANIFEST_HEAD="$(git -C "$MANIFEST_GIT" rev-parse HEAD)"
MANIFEST_TAG="$(git -C "$MANIFEST_GIT" describe --tags --exact-match HEAD 2>/dev/null || true)"
echo "MANIFEST_HEAD=$MANIFEST_HEAD"
echo "MANIFEST_EXACT_TAG=${MANIFEST_TAG:-NONE}"

if [ "$MANIFEST_TAG" = "$EXPECTED_UPSTREAM_TAG" ] || [ "$MANIFEST_TAG" = "refs/tags/$EXPECTED_UPSTREAM_TAG" ]; then
  echo "SABLESTART_R5_R3A_EXPECTED_UPSTREAM_TAG_AT_HEAD=PASS"
else
  echo "SABLESTART_R5_R3A_EXPECTED_UPSTREAM_TAG_AT_HEAD=NOT_OBSERVED"
fi

echo
printf '%s\n' "===== LOCAL MANIFEST INVENTORY ====="
LOCAL_DIR="$WS/.repo/local_manifests"
: > "$EVIDENCE_DIR/local_manifest_inventory.txt"
LOCAL_COUNT=0
if [ -d "$LOCAL_DIR" ]; then
  while IFS= read -r -d '' f; do
    LOCAL_COUNT=$((LOCAL_COUNT + 1))
    printf '%s  %s\n' "$(sha256sum "$f" | awk '{print $1}')" "${f#$WS/}" \
      | tee -a "$EVIDENCE_DIR/local_manifest_inventory.txt"
  done < <(find "$LOCAL_DIR" -maxdepth 1 -type f -print0 | sort -z)
else
  echo "NONE" | tee "$EVIDENCE_DIR/local_manifest_inventory.txt"
fi
cat "$EVIDENCE_DIR/local_manifest_inventory.txt"
echo "SABLESTART_R5_R3A_LOCAL_MANIFEST_FILE_COUNT=$LOCAL_COUNT"

# Capture local manifest contents as evidence because they affect composition.
if [ -d "$LOCAL_DIR" ]; then
  while IFS= read -r -d '' f; do
    base="$(basename "$f")"
    cp -- "$f" "$EVIDENCE_DIR/local_manifest_${base}"
  done < <(find "$LOCAL_DIR" -maxdepth 1 -type f -print0 | sort -z)
fi

echo
printf '%s\n' "===== RESOLVED MANIFEST ====="
(
  cd "$WS"
  "$REPO_BIN" manifest -r
) > "$EVIDENCE_DIR/resolved_manifest.xml"
[ -s "$EVIDENCE_DIR/resolved_manifest.xml" ] || fail "repo manifest -r produced empty output"
sha256sum "$EVIDENCE_DIR/resolved_manifest.xml" | tee "$EVIDENCE_DIR/resolved_manifest_sha256.txt"
echo "SABLESTART_R5_R3A_RESOLVED_MANIFEST_CAPTURE=PASS"

python3 - "$EVIDENCE_DIR/resolved_manifest.xml" "$TARGET_PATH" "$EVIDENCE_DIR/project_path_inventory.txt" <<'PY'
import sys
import xml.etree.ElementTree as ET

manifest_path, target_path, out_path = sys.argv[1:]
root = ET.parse(manifest_path).getroot()
projects = []
for p in root.findall('project'):
    name = p.get('name', '')
    path = p.get('path') or name
    if path == target_path or name == 'packages_apps_SableStart':
        projects.append({
            'name': name,
            'path': path,
            'remote': p.get('remote', ''),
            'revision': p.get('revision', ''),
            'upstream': p.get('upstream', ''),
        })

with open(out_path, 'w', encoding='utf-8') as fh:
    if not projects:
        fh.write('NONE\n')
    for idx, p in enumerate(projects, 1):
        fh.write(
            f"[{idx}] name={p['name']} path={p['path']} remote={p['remote']} "
            f"revision={p['revision']} upstream={p['upstream']}\n"
        )

print(f"SABLESTART_R5_R3A_TARGET_PROJECT_COUNT={len(projects)}")
if len(projects) == 0:
    print('SABLESTART_R5_R3A_CANONICAL_MAPPING_PRESENT=NO')
    print('SABLESTART_R5_R3A_PATH_COLLISION=NONE_OBSERVED')
elif len(projects) == 1:
    p = projects[0]
    expected = (
        p['name'] == 'packages_apps_SableStart' and
        p['path'] == target_path and
        p['revision'] == '059d5d23e4186bbd3119180433a5e6206b7d95bd'
    )
    print(f"SABLESTART_R5_R3A_CANONICAL_MAPPING_PRESENT={'YES' if expected else 'OTHER_MAPPING_PRESENT'}")
    print('SABLESTART_R5_R3A_PATH_COLLISION=NONE_OBSERVED')
else:
    print('SABLESTART_R5_R3A_CANONICAL_MAPPING_PRESENT=AMBIGUOUS')
    print('SABLESTART_R5_R3A_PATH_COLLISION=DETECTED')
    raise SystemExit(2)
PY

cat "$EVIDENCE_DIR/project_path_inventory.txt"

echo
printf '%s\n' "===== CURRENT WORKSPACE PATH STATE ====="
if [ -e "$WS/$TARGET_PATH" ]; then
  ls -ld "$WS/$TARGET_PATH" | tee "$EVIDENCE_DIR/sablestart_path_ls.txt"
  if [ -L "$WS/$TARGET_PATH" ]; then
    echo "SABLESTART_R5_R3A_WORKSPACE_PATH_SYMLINK=YES"
    readlink -f "$WS/$TARGET_PATH" | tee "$EVIDENCE_DIR/sablestart_path_resolved.txt"
  else
    echo "SABLESTART_R5_R3A_WORKSPACE_PATH_SYMLINK=NO"
  fi
  if git -C "$WS/$TARGET_PATH" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$WS/$TARGET_PATH" rev-parse HEAD | tee "$EVIDENCE_DIR/sablestart_workspace_git_head.txt"
    git -C "$WS/$TARGET_PATH" status --short --branch | tee "$EVIDENCE_DIR/sablestart_workspace_git_status.txt"
    git -C "$WS/$TARGET_PATH" remote -v | tee "$EVIDENCE_DIR/sablestart_workspace_git_remotes.txt"
  else
    echo "NOT_A_GIT_WORKTREE" | tee "$EVIDENCE_DIR/sablestart_workspace_git_status.txt"
  fi
else
  echo "ABSENT" | tee "$EVIDENCE_DIR/sablestart_path_ls.txt"
fi

echo
printf '%s\n' "===== REPO PROJECT VIEW ====="
(
  cd "$WS"
  "$REPO_BIN" list -p
) > "$EVIDENCE_DIR/repo_project_paths.txt"

grep -Fx "$TARGET_PATH" "$EVIDENCE_DIR/repo_project_paths.txt" >/dev/null 2>&1 \
  && echo "SABLESTART_R5_R3A_REPO_LIST_TARGET_PRESENT=YES" \
  || echo "SABLESTART_R5_R3A_REPO_LIST_TARGET_PRESENT=NO"

echo
printf '%s\n' "===== FINAL EVIDENCE SEAL ====="
(
  cd "$EVIDENCE_DIR"
  find . -maxdepth 1 -type f \
    ! -name 'r5_r3a_manifest_audit.log' \
    ! -name 'SHA256SUMS.txt' \
    ! -name 'SHA256SUMS.txt.sha256' \
    -printf '%P\0' \
    | sort -z \
    | xargs -0 -r sha256sum
) > "$EVIDENCE_DIR/SHA256SUMS.txt"
sha256sum "$EVIDENCE_DIR/SHA256SUMS.txt" | tee "$EVIDENCE_DIR/SHA256SUMS.txt.sha256"

echo "SABLESTART_R5_R3A_AUDIT=PASS"
echo "CLAIM_BOUNDARY=read-only capture of historical workspace repo/manifest/local-manifest/project-path state; no manifest integration, sync, build, device contact, clean, delete, or source mutation performed"
echo "Evidence: $EVIDENCE_DIR"
