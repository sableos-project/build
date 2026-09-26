#!/usr/bin/env bash
set -euo pipefail

strict_env=0
evidence_dir=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --strict-env)
      strict_env=1
      ;;
    --evidence-dir)
      shift
      evidence_dir="${1:-}"
      ;;
    --evidence-dir=*)
      evidence_dir="${1#--evidence-dir=}"
      ;;
    *)
      echo "SABLE_SELF_TEST=FAIL"
      echo "ERROR=unknown self-test argument: $1" >&2
      exit 2
      ;;
  esac
  shift || true
done

if [ -z "${evidence_dir}" ]; then
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  evidence_dir="${SCRIPT_DIR}/out/sable-public-build-evidence/${DEVICE}-${RELEASE}-${stamp}"
fi

mkdir -p "${evidence_dir}/samples"
summary_json="${evidence_dir}/summary.json"
self_log="${evidence_dir}/self-test.log"
env_report="${evidence_dir}/env-check.txt"
failures=0
samples=0

log() {
  echo "$*" | tee -a "${self_log}"
}

run_expect() {
  name="$1"
  expected_rc="$2"
  shift 2
  samples=$((samples + 1))
  out_file="${evidence_dir}/samples/${name}.txt"

  set +e
  "$@" >"${out_file}" 2>&1
  rc="$?"
  set -e

  if [ "${rc}" -eq "${expected_rc}" ]; then
    log "${name}=PASS rc=${rc}"
  else
    log "${name}=FAIL expected=${expected_rc} actual=${rc} output=${out_file}"
    failures=$((failures + 1))
  fi
}

: >"${self_log}"
log "SABLE_SELF_TEST=START"
log "DEVICE=${DEVICE}"
log "RELEASE=${RELEASE}"
log "EVIDENCE_DIR=${evidence_dir}"

log "===== SYNTAX CHECKS ====="
for script in \
  "${SCRIPT_DIR}/sable.sh" \
  "${SCRIPT_DIR}/lib/sable/env-check.sh" \
  "${SCRIPT_DIR}/lib/sable/source.sh" \
  "${SCRIPT_DIR}/lib/sable/signing.sh" \
  "${SCRIPT_DIR}/lib/sable/verify.sh" \
  "${SCRIPT_DIR}/lib/sable/self-test.sh"; do
  samples=$((samples + 1))
  if bash -n "${script}"; then
    log "BASH_N_$(basename "${script}" | tr '.-' '__')=PASS"
  else
    log "BASH_N_$(basename "${script}" | tr '.-' '__')=FAIL"
    failures=$((failures + 1))
  fi
done

log "===== HOST ENV CHECK ====="
set +e
bash "${SCRIPT_DIR}/sable.sh" "${DEVICE}" "${RELEASE}" env-check >"${env_report}" 2>&1
env_rc="$?"
set -e
log "ENV_CHECK_REPORT=${env_report}"
log "ENV_CHECK_RC=${env_rc}"
if [ "${strict_env}" -eq 1 ] && [ "${env_rc}" -ne 0 ]; then
  log "STRICT_ENV_CHECK=FAIL"
  failures=$((failures + 1))
else
  log "STRICT_ENV_CHECK=NOT_REQUESTED_OR_PASS"
fi

log "===== ROUTER SAMPLE CHECKS ====="
run_expect sample_source_sync 0 \
  bash "${SCRIPT_DIR}/sable.sh" panther R9 source-sync
run_expect sample_source_verify 0 \
  bash "${SCRIPT_DIR}/sable.sh" panther R9 source-verify
run_expect sample_flash_plan 0 \
  bash "${SCRIPT_DIR}/sable.sh" panther R9 flash-plan
run_expect sample_titan2_build_image_fail_closed 3 \
  bash "${SCRIPT_DIR}/sable.sh" titan2 N0 build-image
run_expect sample_sign_dev_fail_closed 3 \
  bash "${SCRIPT_DIR}/sable.sh" panther R9 sign --mode dev
run_expect sample_unknown_device_fail_closed 2 \
  bash "${SCRIPT_DIR}/sable.sh" unknown R9 env-check
run_expect sample_unknown_release_fail_closed 2 \
  bash "${SCRIPT_DIR}/sable.sh" panther UNKNOWN env-check
run_expect sample_unknown_function_fail_closed 2 \
  bash "${SCRIPT_DIR}/sable.sh" panther R9 unknown-function
run_expect sample_verify_missing_artifact_fail_closed 2 \
  bash "${SCRIPT_DIR}/sable.sh" panther R9 verify

status="PASS"
if [ "${failures}" -ne 0 ]; then
  status="FAIL"
fi

cat >"${summary_json}" <<EOF_JSON
{
  "schema": "sable-public-build-self-test-v1",
  "device": "${DEVICE}",
  "release": "${RELEASE}",
  "status": "${status}",
  "failures": ${failures},
  "samples": ${samples},
  "env_check_rc": ${env_rc},
  "strict_env": ${strict_env},
  "evidence_dir": "${evidence_dir}"
}
EOF_JSON

log "SUMMARY_JSON=${summary_json}"
log "SAMPLES=${samples}"
log "FAILURES=${failures}"

if [ "${failures}" -ne 0 ]; then
  log "SABLE_SELF_TEST=FAIL"
  exit 1
fi

log "SABLE_SELF_TEST=PASS"
