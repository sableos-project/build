#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADB="${ADB:-/usr/bin/adb}"
MAESTRO="${MAESTRO:-maestro}"
DEVICE1_SERIAL="${DEVICE1_SERIAL:-}"
PACKAGE="${PACKAGE:-org.sableos.start}"
EXPECTED_APK_SHA256="${EXPECTED_APK_SHA256:-d5ba8e1abdbbd8f32f513df149487ee1c6b80164d1fd4076e5a2dd97ff66b0a7}"
EXPECTED_LAUNCHER_COUNT="${EXPECTED_LAUNCHER_COUNT:-11}"
EXPECTED_HOME_COMPONENT="${EXPECTED_HOME_COMPONENT:-org.sableos.start/.SableStartActivity}"
EXPECTED_MAESTRO_VERSION="${EXPECTED_MAESTRO_VERSION:-}"
STAMP="${STAMP:-$(date +%Y%m%d_%H%M%S)}"
EVIDENCE_DIR="${EVIDENCE_DIR:-/tmp/SABLE_R6_MAESTRO_${STAMP}}"

DEVICE_CONTACT_AUTH="${SABLE_DEVICE_CONTACT_AUTHORIZED:-NO}"
MAESTRO_INPUT_AUTH="${SABLE_MAESTRO_UI_INPUT_AUTHORIZED:-NO}"

HOME_FLOW="$REPO_ROOT/maestro/r6_sablestart_home.yaml"
ALL_APPS_FLOW="$REPO_ROOT/maestro/r6_sablestart_all_apps.yaml"
SEARCH_FLOW="$REPO_ROOT/maestro/r6_sablestart_search.yaml"

mkdir -p "$EVIDENCE_DIR"
REPORT="$EVIDENCE_DIR/r6_sablestart_maestro.log"
RESULTS="$EVIDENCE_DIR/results.env"
exec > >(tee "$REPORT") 2>&1

fail() {
    echo "R6_SABLESTART_MAESTRO=FAIL"
    echo "FAIL_REASON=$*"
    echo "Evidence: $EVIDENCE_DIR"
    exit 1
}

mark() {
    echo "$1=$2" | tee -a "$RESULTS"
}

adb_cmd() {
    "$ADB" -s "$DEVICE1_SERIAL" "$@"
}

launcher_inventory() {
    adb_cmd shell cmd package query-activities \
        --brief \
        --user 0 \
        -a android.intent.action.MAIN \
        -c android.intent.category.LAUNCHER \
        2>&1 \
        | tr -d '\r' \
        | grep -E '^[[:space:]]+[A-Za-z0-9_.]+/' \
        | sed 's/^[[:space:]]*//' \
        | sort -u
}

launcher_count() {
    launcher_inventory | sed '/^[[:space:]]*$/d' | wc -l
}

wait_launcher_inventory() {
    local i count
    for i in $(seq 1 90); do
        count="$(launcher_count || true)"
        [ "$count" = "$EXPECTED_LAUNCHER_COUNT" ] && return 0
        sleep 1
    done
    return 1
}

home_resolver() {
    adb_cmd shell cmd package resolve-activity \
        --brief \
        --user 0 \
        -a android.intent.action.MAIN \
        -c android.intent.category.HOME \
        2>/dev/null \
        | tr -d '\r' \
        | tail -n1
}

wait_home_resolver() {
    local i value
    for i in $(seq 1 90); do
        value="$(home_resolver || true)"
        [ "$value" = "$EXPECTED_HOME_COMPONENT" ] && return 0
        sleep 1
    done
    return 1
}

run_flow() {
    local name="$1"
    local flow="$2"
    local log="$EVIDENCE_DIR/${name}.maestro.log"
    local rc

    echo
    echo "===== MAESTRO FLOW: $name ====="
    set +e
    "$MAESTRO_BIN" --device "$DEVICE1_SERIAL" test "$flow" 2>&1 | tee "$log"
    rc=${PIPESTATUS[0]}
    set -e
    echo "${name}_RC=$rc" | tee -a "$RESULTS"
    [ "$rc" -eq 0 ]
}

capture_final_state() {
    adb_cmd exec-out screencap -p > "$EVIDENCE_DIR/final.png"
    adb_cmd shell dumpsys activity activities > "$EVIDENCE_DIR/final.activities.txt"
    adb_cmd shell dumpsys window windows > "$EVIDENCE_DIR/final.windows.txt"
    adb_cmd shell dumpsys package "$PACKAGE" > "$EVIDENCE_DIR/final.package.txt"
    adb_cmd shell pidof "$PACKAGE" > "$EVIDENCE_DIR/final.pidof.txt" || true
    sha256sum "$EVIDENCE_DIR/final.png" > "$EVIDENCE_DIR/final.png.sha256"
}

seal_evidence() {
    (
        cd "$EVIDENCE_DIR"
        find . -maxdepth 1 -type f \
            ! -name 'r6_sablestart_maestro.log' \
            ! -name 'SHA256SUMS.txt' \
            ! -name 'SHA256SUMS.txt.sha256' \
            -printf '%P\0' \
            | sort -z \
            | xargs -0 -r sha256sum
    ) > "$EVIDENCE_DIR/SHA256SUMS.txt"
    sha256sum "$EVIDENCE_DIR/SHA256SUMS.txt" \
        | tee "$EVIDENCE_DIR/SHA256SUMS.txt.sha256"
}

echo "===== SABLESTART R6 MAESTRO GATE ====="
echo "SOURCE_MUTATION_AUTHORIZED=NO"
echo "BUILD_AUTHORIZED=NO"
echo "PACKAGE_INSTALL_AUTHORIZED=NO"
echo "FASTBOOT_AUTHORIZED=NO"
echo "HOME_ROLE_MUTATION_AUTHORIZED=NO"
echo "SETTINGS_MUTATION_AUTHORIZED=NO"
echo "PERMISSION_MUTATION_AUTHORIZED=NO"
echo "DEVICE_REBOOT_AUTHORIZED=NO"
echo "DEVICE_ROOT_AUTHORIZED=NO"
echo "DEVICE_REMOUNT_AUTHORIZED=NO"
echo "USERDATA_OR_METADATA_WIPE_AUTHORIZED=NO"
echo "DEVICE2_CONTACT_AUTHORIZED=NO"
echo "DEVICE1_CONTACT_AUTHORIZED=$DEVICE_CONTACT_AUTH"
echo "MAESTRO_UI_INPUT_AUTHORIZED=$MAESTRO_INPUT_AUTH"
echo "EVIDENCE_DIR=$EVIDENCE_DIR"

[ "$DEVICE_CONTACT_AUTH" = "YES" ] \
    || fail "set SABLE_DEVICE_CONTACT_AUTHORIZED=YES only under fresh Device1 authorization"
[ "$MAESTRO_INPUT_AUTH" = "YES_MAESTRO" ] \
    || fail "set SABLE_MAESTRO_UI_INPUT_AUTHORIZED=YES_MAESTRO only under fresh UI-automation authorization"
[ -n "$DEVICE1_SERIAL" ] || fail "DEVICE1_SERIAL is not set"
[ -x "$ADB" ] || fail "adb executable not found at $ADB"

MAESTRO_BIN="$(command -v "$MAESTRO" 2>/dev/null || true)"
[ -n "$MAESTRO_BIN" ] || fail "Maestro CLI is not installed or not on PATH"

for flow in "$HOME_FLOW" "$ALL_APPS_FLOW" "$SEARCH_FLOW"; do
    [ -f "$flow" ] || fail "missing Maestro flow: $flow"
done

"$MAESTRO_BIN" --version | tee "$EVIDENCE_DIR/maestro_version.txt"
MAESTRO_VERSION="$(head -n1 "$EVIDENCE_DIR/maestro_version.txt" | tr -d '\r')"
echo "MAESTRO_VERSION=$MAESTRO_VERSION" | tee -a "$RESULTS"
if [ -n "$EXPECTED_MAESTRO_VERSION" ]; then
    [ "$MAESTRO_VERSION" = "$EXPECTED_MAESTRO_VERSION" ] \
        || fail "Maestro version does not match EXPECTED_MAESTRO_VERSION"
    mark "MAESTRO_VERSION_BINDING" "PASS"
else
    mark "MAESTRO_VERSION_BINDING" "UNPINNED_COMPATIBILITY_PROBE"
fi

adb_cmd get-state | tee "$EVIDENCE_DIR/adb_state.txt"
BOOT_COMPLETED="$(adb_cmd shell getprop sys.boot_completed | tr -d '\r')"
[ "$BOOT_COMPLETED" = "1" ] || fail "sys.boot_completed is not 1"
mark "BOOT_COMPLETED" "PASS"

DEVICE_LOGCAT_START="$(adb_cmd shell date '+%m-%d %H:%M:%S.000' | tr -d '\r')"
echo "DEVICE_LOGCAT_START=$DEVICE_LOGCAT_START" | tee -a "$RESULTS"

SABLE_PATH="$(adb_cmd shell pm path "$PACKAGE" | tr -d '\r' | head -n1 | sed 's/^package://')"
[ -n "$SABLE_PATH" ] || fail "$PACKAGE is not installed"
DEVICE_APK_SHA256="$(adb_cmd shell sha256sum "$SABLE_PATH" | awk '{print $1}' | tr -d '\r')"
echo "DEVICE_SABLESTART_APK_SHA256=$DEVICE_APK_SHA256" | tee -a "$RESULTS"
[ "$DEVICE_APK_SHA256" = "$EXPECTED_APK_SHA256" ] \
    || fail "installed APK does not match EXPECTED_APK_SHA256"
mark "INSTALLED_APK_BINDING" "PASS"

if wait_launcher_inventory; then
    mark "LAUNCHER_INVENTORY_STABLE" "PASS"
else
    launcher_inventory | tee "$EVIDENCE_DIR/launcher_inventory_unstable.txt" || true
    fail "launcher inventory did not stabilize at $EXPECTED_LAUNCHER_COUNT"
fi
launcher_inventory | tee "$EVIDENCE_DIR/launcher_inventory.txt"
mark "ANDROID_LAUNCHER_VISIBLE_COUNT" "$(launcher_count)"

HOME_ROLE="$(adb_cmd shell cmd role get-role-holders --user 0 android.app.role.HOME | tr -d '\r' | head -n1)"
echo "HOME_ROLE_HOLDER=$HOME_ROLE" | tee "$EVIDENCE_DIR/home_role.txt"
[ "$HOME_ROLE" = "$PACKAGE" ] || fail "HOME role holder is not $PACKAGE"
mark "HOME_ROLE_HOLDER" "PASS"

if wait_home_resolver; then
    mark "HOME_RESOLVER_STABLE" "PASS"
else
    echo "HOME_RESOLVER=$(home_resolver || true)" | tee "$EVIDENCE_DIR/home_resolver_unstable.txt"
    fail "HOME resolver did not stabilize at $EXPECTED_HOME_COMPONENT"
fi
echo "HOME_RESOLVER=$(home_resolver)" | tee "$EVIDENCE_DIR/home_resolver.txt"

if ! run_flow "home" "$HOME_FLOW"; then
    capture_final_state || true
    seal_evidence
    fail "home Maestro flow failed"
fi
mark "MAESTRO_HOME_FLOW" "PASS"

set +e
"$MAESTRO_BIN" --device "$DEVICE1_SERIAL" hierarchy > "$EVIDENCE_DIR/home.hierarchy.txt" 2>&1
HIERARCHY_RC=$?
set -e
echo "HIERARCHY_RC=$HIERARCHY_RC" | tee -a "$RESULTS"
[ "$HIERARCHY_RC" -eq 0 ] || fail "maestro hierarchy failed"
if grep -Fq "Sable Start" "$EVIDENCE_DIR/home.hierarchy.txt" \
    && grep -Fq "11 available" "$EVIDENCE_DIR/home.hierarchy.txt"; then
    mark "MAESTRO_HOME_SEMANTICS" "PASS"
else
    fail "Maestro hierarchy does not expose expected Sable Start text semantics"
fi

if ! run_flow "all_apps" "$ALL_APPS_FLOW"; then
    capture_final_state || true
    seal_evidence
    fail "all-apps Maestro flow failed"
fi
mark "MAESTRO_ALL_APPS_FLOW" "PASS"

if ! run_flow "search" "$SEARCH_FLOW"; then
    capture_final_state || true
    seal_evidence
    fail "search Maestro flow failed"
fi
mark "MAESTRO_SEARCH_FLOW" "PASS"

capture_final_state

adb_cmd logcat -d -v threadtime -T "$DEVICE_LOGCAT_START" \
    > "$EVIDENCE_DIR/logcat_since_start.txt" 2>&1 || true

grep -E 'FATAL EXCEPTION|AndroidRuntime|Process: org\.sableos\.start' \
    "$EVIDENCE_DIR/logcat_since_start.txt" \
    > "$EVIDENCE_DIR/logcat_crash_focus.txt" || true

if grep -Fq 'Process: org.sableos.start' "$EVIDENCE_DIR/logcat_crash_focus.txt"; then
    mark "SABLESTART_FATAL_EXCEPTION" "FAIL"
    seal_evidence
    fail "SableStart fatal exception observed during Maestro run"
else
    mark "SABLESTART_FATAL_EXCEPTION" "NOT_OBSERVED"
fi

FINAL_ROLE="$(adb_cmd shell cmd role get-role-holders --user 0 android.app.role.HOME | tr -d '\r' | head -n1)"
FINAL_HOME="$(home_resolver || true)"
echo "FINAL_HOME_ROLE_HOLDER=$FINAL_ROLE" | tee -a "$RESULTS"
echo "FINAL_HOME_RESOLVER=$FINAL_HOME" | tee -a "$RESULTS"
[ "$FINAL_ROLE" = "$PACKAGE" ] || fail "HOME role changed during Maestro run"
[ "$FINAL_HOME" = "$EXPECTED_HOME_COMPONENT" ] || fail "HOME resolver changed during Maestro run"
mark "FINAL_HOME_INVARIANT" "PASS"

seal_evidence

echo "R6_SABLESTART_MAESTRO=PASS"
echo "CLAIM_BOUNDARY=Maestro-driven Device1 UI automation for production SableStart home, all-apps, Settings/Calculator launch, and search flows; exact installed APK, launcher count, HOME role/resolver, hierarchy semantics, final activity state and crash evidence captured; no build, package install, HOME-role mutation, reboot, root/remount, wipe or Device2 contact"
echo "Evidence: $EVIDENCE_DIR"
