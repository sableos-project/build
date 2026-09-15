#!/usr/bin/env bash
set -euo pipefail

ADB="${ADB:-/usr/bin/adb}"
DEVICE1_SERIAL="${DEVICE1_SERIAL:-}"
PACKAGE="${PACKAGE:-org.sableos.start}"
EXPECTED_APK_SHA256="${EXPECTED_APK_SHA256:-d5ba8e1abdbbd8f32f513df149487ee1c6b80164d1fd4076e5a2dd97ff66b0a7}"
EXPECTED_LAUNCHER_COUNT="${EXPECTED_LAUNCHER_COUNT:-11}"
EXPECTED_HOME_COMPONENT="${EXPECTED_HOME_COMPONENT:-org.sableos.start/.SableStartActivity}"
SETTINGS_PACKAGE="${SETTINGS_PACKAGE:-com.android.settings}"
CALCULATOR_PACKAGE="${CALCULATOR_PACKAGE:-com.android.calculator2}"
STAMP="${STAMP:-$(date +%Y%m%d_%H%M%S)}"
EVIDENCE_DIR="${EVIDENCE_DIR:-/tmp/SABLE_R6_RUNTIME_INTERACTION_${STAMP}}"

DEVICE_CONTACT_AUTH="${SABLE_DEVICE_CONTACT_AUTHORIZED:-NO}"
UI_INPUT_AUTH="${SABLE_UI_INPUT_AUTHORIZED:-NO}"

mkdir -p "$EVIDENCE_DIR"
REPORT="$EVIDENCE_DIR/r6_sablestart_runtime_interaction.log"
RESULTS="$EVIDENCE_DIR/results.env"
exec > >(tee "$REPORT") 2>&1

AUTO_FAILURES=0
MANUAL_FAILURES=0

fail() {
    echo "R6_SABLESTART_RUNTIME_INTERACTION=FAIL"
    echo "FAIL_REASON=$*"
    echo "Evidence: $EVIDENCE_DIR"
    exit 1
}

mark_auto() {
    local key="$1"
    local value="$2"
    echo "${key}=${value}" | tee -a "$RESULTS"
    if [ "$value" != "PASS" ]; then
        AUTO_FAILURES=$((AUTO_FAILURES + 1))
    fi
}

manual_check() {
    local key="$1"
    local prompt="$2"
    local answer
    echo
    echo "===== USER CHECK: $key ====="
    echo "$prompt"
    printf 'Type PASS or FAIL, then press Enter: '
    read -r answer
    case "$answer" in
        PASS|FAIL) ;;
        *) answer="FAIL" ;;
    esac
    echo "${key}=${answer}" | tee -a "$RESULTS"
    if [ "$answer" != "PASS" ]; then
        MANUAL_FAILURES=$((MANUAL_FAILURES + 1))
    fi
}

adb_cmd() {
    "$ADB" -s "$DEVICE1_SERIAL" "$@"
}

capture_state() {
    local name="$1"
    echo
    echo "===== CAPTURE $name ====="
    adb_cmd exec-out screencap -p > "$EVIDENCE_DIR/${name}.png"
    adb_cmd shell dumpsys activity activities > "$EVIDENCE_DIR/${name}.activities.txt"
    adb_cmd shell dumpsys window windows > "$EVIDENCE_DIR/${name}.windows.txt"
    adb_cmd shell pidof "$PACKAGE" > "$EVIDENCE_DIR/${name}.pidof.txt" || true
    adb_cmd shell dumpsys package "$PACKAGE" > "$EVIDENCE_DIR/${name}.package.txt"
    sha256sum "$EVIDENCE_DIR/${name}.png" | tee -a "$EVIDENCE_DIR/screenshot_sha256.txt"
}

foreground_matches() {
    local package_prefix="$1"
    adb_cmd shell dumpsys activity activities 2>/dev/null \
        | grep -m1 -E 'topResumedActivity|mResumedActivity' \
        | grep -Fq "$package_prefix/"
}

wait_foreground() {
    local package_prefix="$1"
    local attempts="${2:-30}"
    local i
    for i in $(seq 1 "$attempts"); do
        if foreground_matches "$package_prefix"; then
            return 0
        fi
        sleep 1
    done
    return 1
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
    local expected="$1"
    local attempts="${2:-90}"
    local i count
    for i in $(seq 1 "$attempts"); do
        count="$(launcher_count || true)"
        if [ "$count" = "$expected" ]; then
            return 0
        fi
        sleep 1
    done
    return 1
}

home_role_holder() {
    adb_cmd shell cmd role get-role-holders --user 0 android.app.role.HOME \
        | tr -d '\r' \
        | head -n1
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
    local expected="$1"
    local attempts="${2:-90}"
    local i value
    for i in $(seq 1 "$attempts"); do
        value="$(home_resolver || true)"
        if [ "$value" = "$expected" ]; then
            return 0
        fi
        sleep 1
    done
    return 1
}

seal_evidence() {
    (
        cd "$EVIDENCE_DIR"
        find . -maxdepth 1 -type f \
            ! -name 'r6_sablestart_runtime_interaction.log' \
            ! -name 'SHA256SUMS.txt' \
            ! -name 'SHA256SUMS.txt.sha256' \
            -printf '%P\0' \
            | sort -z \
            | xargs -0 -r sha256sum
    ) > "$EVIDENCE_DIR/SHA256SUMS.txt"
    sha256sum "$EVIDENCE_DIR/SHA256SUMS.txt" \
        | tee "$EVIDENCE_DIR/SHA256SUMS.txt.sha256"
}

echo "===== SABLESTART R6 RUNTIME INTERACTION GATE ====="
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
echo "UI_INPUT_AUTHORIZED=$UI_INPUT_AUTH"
echo "UI_INPUT_MODE=USER_MEDIATED_ONLY"
echo "ADB_COORDINATE_INPUT=NO"
echo "EVIDENCE_DIR=$EVIDENCE_DIR"

[ "$DEVICE_CONTACT_AUTH" = "YES" ] \
    || fail "set SABLE_DEVICE_CONTACT_AUTHORIZED=YES only under fresh Device1 authorization"
[ "$UI_INPUT_AUTH" = "YES_USER_MEDIATED" ] \
    || fail "set SABLE_UI_INPUT_AUTHORIZED=YES_USER_MEDIATED only under fresh UI-input authorization"
[ -n "$DEVICE1_SERIAL" ] || fail "DEVICE1_SERIAL is not set"
[ -x "$ADB" ] || fail "adb executable not found at $ADB"

DEVICE_LOGCAT_START="$(adb_cmd shell date '+%m-%d %H:%M:%S.000' | tr -d '\r')"
echo "DEVICE_LOGCAT_START=$DEVICE_LOGCAT_START"

adb_cmd get-state | tee "$EVIDENCE_DIR/adb_state.txt"
BOOT_COMPLETED="$(adb_cmd shell getprop sys.boot_completed | tr -d '\r')"
[ "$BOOT_COMPLETED" = "1" ] || fail "sys.boot_completed is not 1"
echo "SYS_BOOT_COMPLETED=1"

for prop in \
    ro.product.device \
    ro.build.id \
    ro.build.version.release \
    ro.build.version.security_patch \
    ro.build.type \
    ro.build.tags \
    ro.boot.slot_suffix
 do
    printf '%s=%s\n' "$prop" "$(adb_cmd shell getprop "$prop" | tr -d '\r')"
done | tee "$EVIDENCE_DIR/platform_identity.txt"

echo
echo "===== INSTALLED ARTIFACT BINDING ====="
SABLE_PATH="$(adb_cmd shell pm path "$PACKAGE" | tr -d '\r' | head -n1 | sed 's/^package://')"
[ -n "$SABLE_PATH" ] || fail "$PACKAGE is not installed"
DEVICE_APK_SHA256="$(adb_cmd shell sha256sum "$SABLE_PATH" | awk '{print $1}' | tr -d '\r')"
echo "SABLESTART_PM_PATH=$SABLE_PATH"
echo "DEVICE_SABLESTART_APK_SHA256=$DEVICE_APK_SHA256"
if [ "$DEVICE_APK_SHA256" = "$EXPECTED_APK_SHA256" ]; then
    mark_auto "INSTALLED_APK_BINDING" "PASS"
else
    mark_auto "INSTALLED_APK_BINDING" "FAIL"
    fail "installed APK does not match EXPECTED_APK_SHA256"
fi

echo
echo "===== PACKAGE-MANAGER STABILIZATION ====="
if wait_launcher_inventory "$EXPECTED_LAUNCHER_COUNT" 90; then
    mark_auto "LAUNCHER_INVENTORY_STABLE" "PASS"
else
    mark_auto "LAUNCHER_INVENTORY_STABLE" "FAIL"
fi
launcher_inventory | tee "$EVIDENCE_DIR/launcher_inventory.txt"
ANDROID_LAUNCHER_VISIBLE_COUNT="$(launcher_count || true)"
echo "ANDROID_LAUNCHER_VISIBLE_COUNT=$ANDROID_LAUNCHER_VISIBLE_COUNT" | tee -a "$RESULTS"

if [ "$ANDROID_LAUNCHER_VISIBLE_COUNT" = "$EXPECTED_LAUNCHER_COUNT" ]; then
    mark_auto "LAUNCHER_COUNT_MATCH" "PASS"
else
    mark_auto "LAUNCHER_COUNT_MATCH" "FAIL"
fi

ROLE_HOLDER="$(home_role_holder || true)"
echo "HOME_ROLE_HOLDER=$ROLE_HOLDER" | tee "$EVIDENCE_DIR/home_role.txt"
if [ "$ROLE_HOLDER" = "$PACKAGE" ]; then
    mark_auto "HOME_ROLE_HOLDER" "PASS"
else
    mark_auto "HOME_ROLE_HOLDER" "FAIL"
fi

if wait_home_resolver "$EXPECTED_HOME_COMPONENT" 90; then
    mark_auto "HOME_RESOLVER_STABLE" "PASS"
else
    mark_auto "HOME_RESOLVER_STABLE" "FAIL"
fi
HOME_RESOLVED="$(home_resolver || true)"
echo "HOME_RESOLVER=$HOME_RESOLVED" | tee "$EVIDENCE_DIR/home_resolver.txt"

manual_check \
    "BASELINE_HOME_VISUAL" \
    "Unlock Device1 and use the physical Home gesture/button. Confirm the production Sable Start screen is visible and shows ${EXPECTED_LAUNCHER_COUNT} available apps."

if wait_foreground "$PACKAGE" 30; then
    mark_auto "BASELINE_HOME_FOREGROUND" "PASS"
else
    mark_auto "BASELINE_HOME_FOREGROUND" "FAIL"
fi
BASELINE_PID="$(adb_cmd shell pidof "$PACKAGE" | tr -d '\r' || true)"
echo "BASELINE_PID=$BASELINE_PID" | tee -a "$RESULTS"
capture_state "00_home_baseline"

manual_check \
    "ALL_APPS_COUNT_VISUAL" \
    "Tap 'all apps'. Confirm the heading reports 'all apps · ${EXPECTED_LAUNCHER_COUNT}' and ${EXPECTED_LAUNCHER_COUNT} launcher-visible rows can be reviewed by scrolling. Leave All Apps open."
manual_check \
    "ALL_APPS_LABELS_VISUAL" \
    "Confirm the rows use real installed application labels rather than demo/hard-coded names."
manual_check \
    "ALL_APPS_REAL_ICONS_VISUAL" \
    "Confirm each row shows the real installed application icon. Mark FAIL if Sable Start shows generated initials/letters instead of the actual icons."

if wait_foreground "$PACKAGE" 10; then
    mark_auto "ALL_APPS_SABLESTART_FOREGROUND" "PASS"
else
    mark_auto "ALL_APPS_SABLESTART_FOREGROUND" "FAIL"
fi
capture_state "01_all_apps"

manual_check \
    "SETTINGS_LAUNCH_ACTION" \
    "From All Apps, tap Settings. After Settings is visibly open, enter PASS."
if wait_foreground "$SETTINGS_PACKAGE" 30; then
    mark_auto "ALL_APPS_SETTINGS_LAUNCH" "PASS"
else
    mark_auto "ALL_APPS_SETTINGS_LAUNCH" "FAIL"
fi
capture_state "02_settings_from_all_apps"

manual_check \
    "RETURN_HOME_AFTER_SETTINGS_ACTION" \
    "Use the physical Home gesture/button. Confirm Sable Start returns, then enter PASS."
if wait_foreground "$PACKAGE" 30; then
    mark_auto "RETURN_HOME_AFTER_SETTINGS" "PASS"
else
    mark_auto "RETURN_HOME_AFTER_SETTINGS" "FAIL"
fi
capture_state "03_home_after_settings"

manual_check \
    "CALCULATOR_LAUNCH_ACTION" \
    "Open All Apps again and tap Calculator. After Calculator is visibly open, enter PASS."
if wait_foreground "$CALCULATOR_PACKAGE" 30; then
    mark_auto "ALL_APPS_CALCULATOR_LAUNCH" "PASS"
else
    mark_auto "ALL_APPS_CALCULATOR_LAUNCH" "FAIL"
fi
capture_state "04_calculator_from_all_apps"

manual_check \
    "RETURN_HOME_AFTER_CALCULATOR_ACTION" \
    "Use the physical Home gesture/button. Confirm Sable Start returns, then enter PASS."
if wait_foreground "$PACKAGE" 30; then
    mark_auto "RETURN_HOME_AFTER_CALCULATOR" "PASS"
else
    mark_auto "RETURN_HOME_AFTER_CALCULATOR" "FAIL"
fi
capture_state "05_home_after_calculator"

manual_check \
    "SEARCH_EMPTY_INVENTORY_VISUAL" \
    "Tap Search. With the search field empty, confirm it reports '${EXPECTED_LAUNCHER_COUNT} results'. Leave Search open."
if wait_foreground "$PACKAGE" 10; then
    mark_auto "SEARCH_SABLESTART_FOREGROUND" "PASS"
else
    mark_auto "SEARCH_SABLESTART_FOREGROUND" "FAIL"
fi
capture_state "06_search_empty"

manual_check \
    "SEARCH_CALCULATOR_RESULT_VISUAL" \
    "Type 'calculator' into the Sable Start search field. Confirm Calculator is shown as a matching result and the result count is appropriate. Leave the filtered result visible."
capture_state "07_search_calculator"

manual_check \
    "SEARCH_CALCULATOR_LAUNCH_ACTION" \
    "Tap the Calculator search result. After Calculator is visibly open, enter PASS."
if wait_foreground "$CALCULATOR_PACKAGE" 30; then
    mark_auto "SEARCH_CALCULATOR_LAUNCH" "PASS"
else
    mark_auto "SEARCH_CALCULATOR_LAUNCH" "FAIL"
fi
capture_state "08_calculator_from_search"

manual_check \
    "FINAL_RETURN_HOME_ACTION" \
    "Use the physical Home gesture/button one final time. Confirm Sable Start returns, then enter PASS."
if wait_foreground "$PACKAGE" 30; then
    mark_auto "FINAL_HOME_FOREGROUND" "PASS"
else
    mark_auto "FINAL_HOME_FOREGROUND" "FAIL"
fi
capture_state "09_final_home"

echo
echo "===== FINAL INVARIANTS ====="
FINAL_PID="$(adb_cmd shell pidof "$PACKAGE" | tr -d '\r' || true)"
echo "FINAL_PID=$FINAL_PID" | tee -a "$RESULTS"
if [ -n "$FINAL_PID" ]; then
    mark_auto "SABLESTART_PROCESS_ALIVE" "PASS"
else
    mark_auto "SABLESTART_PROCESS_ALIVE" "FAIL"
fi
if [ -n "$BASELINE_PID" ] && [ "$FINAL_PID" = "$BASELINE_PID" ]; then
    echo "SABLESTART_PROCESS_PID_STABLE=PASS" | tee -a "$RESULTS"
else
    echo "SABLESTART_PROCESS_PID_STABLE=OBSERVED_RESTART_OR_PID_CHANGE" | tee -a "$RESULTS"
fi

FINAL_ROLE="$(home_role_holder || true)"
FINAL_HOME="$(home_resolver || true)"
echo "FINAL_HOME_ROLE_HOLDER=$FINAL_ROLE" | tee -a "$RESULTS"
echo "FINAL_HOME_RESOLVER=$FINAL_HOME" | tee -a "$RESULTS"
if [ "$FINAL_ROLE" = "$PACKAGE" ]; then
    mark_auto "FINAL_HOME_ROLE" "PASS"
else
    mark_auto "FINAL_HOME_ROLE" "FAIL"
fi
if [ "$FINAL_HOME" = "$EXPECTED_HOME_COMPONENT" ]; then
    mark_auto "FINAL_HOME_RESOLVER" "PASS"
else
    mark_auto "FINAL_HOME_RESOLVER" "FAIL"
fi

FINAL_LAUNCHER_COUNT="$(launcher_count || true)"
echo "FINAL_ANDROID_LAUNCHER_VISIBLE_COUNT=$FINAL_LAUNCHER_COUNT" | tee -a "$RESULTS"
if [ "$FINAL_LAUNCHER_COUNT" = "$EXPECTED_LAUNCHER_COUNT" ]; then
    mark_auto "FINAL_LAUNCHER_COUNT_MATCH" "PASS"
else
    mark_auto "FINAL_LAUNCHER_COUNT_MATCH" "FAIL"
fi

adb_cmd shell dumpsys package "$PACKAGE" > "$EVIDENCE_DIR/final_package.txt"
adb_cmd shell cmd role get-role-holders --user 0 android.app.role.HOME > "$EVIDENCE_DIR/final_home_role.txt"
adb_cmd shell cmd package resolve-activity --brief --user 0 -a android.intent.action.MAIN -c android.intent.category.HOME > "$EVIDENCE_DIR/final_home_resolver.txt" 2>&1 || true
launcher_inventory > "$EVIDENCE_DIR/final_launcher_inventory.txt"

if ! adb_cmd logcat -d -T "$DEVICE_LOGCAT_START" > "$EVIDENCE_DIR/final_logcat.txt" 2>&1; then
    adb_cmd logcat -d > "$EVIDENCE_DIR/final_logcat.txt" 2>&1 || true
fi
grep -E 'org\.sableos\.start|SableStart|AndroidRuntime|FATAL EXCEPTION' \
    "$EVIDENCE_DIR/final_logcat.txt" \
    > "$EVIDENCE_DIR/final_logcat_focus.txt" || true

if grep -A8 -B3 'FATAL EXCEPTION' "$EVIDENCE_DIR/final_logcat.txt" 2>/dev/null \
    | grep -q 'org\.sableos\.start'; then
    mark_auto "SABLESTART_FATAL_EXCEPTION" "FAIL"
else
    mark_auto "SABLESTART_FATAL_EXCEPTION" "PASS"
fi

echo "AUTO_FAILURES=$AUTO_FAILURES" | tee -a "$RESULTS"
echo "MANUAL_FAILURES=$MANUAL_FAILURES" | tee -a "$RESULTS"

seal_evidence

echo
echo "===== FINAL ====="
if [ "$AUTO_FAILURES" -eq 0 ] && [ "$MANUAL_FAILURES" -eq 0 ]; then
    echo "R6_SABLESTART_RUNTIME_INTERACTION=PASS"
    RC=0
else
    echo "R6_SABLESTART_RUNTIME_INTERACTION=FAIL"
    RC=1
fi

echo "CLAIM_BOUNDARY=exact installed artifact, stable launcher inventory, production HOME return, All Apps/Search user-mediated visual checks, representative Settings/Calculator launches, process/crash stability; no install, role mutation, settings mutation, permission mutation, reboot, root/remount, wipe, source mutation, build, fastboot, or Device2 contact"
echo "Evidence: $EVIDENCE_DIR"
echo "SHA256SUMS_SHA256=$(awk '{print $1}' "$EVIDENCE_DIR/SHA256SUMS.txt.sha256")"
exit "$RC"
