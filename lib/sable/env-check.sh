#!/usr/bin/env bash
set -euo pipefail

missing=0

required_tools=(
  bash
  git
  python3
  java
  repo
  make
  zip
  unzip
  rsync
  curl
  openssl
)

optional_tools=(
  ccache
  ninja
  fastboot
  adb
)

echo "SABLE_ENV_CHECK=START"
echo "DEVICE=${DEVICE}"
echo "RELEASE=${RELEASE}"
echo "DEVICE_STATUS=${DEVICE_STATUS}"
echo "REPRODUCIBILITY_STATUS=${REPRODUCIBILITY_STATUS}"

echo "HOST_UNAME=$(uname -a | tr ' ' '_')"

if command -v nproc >/dev/null 2>&1; then
  echo "HOST_CPU_COUNT=$(nproc)"
fi

if [ -r /proc/meminfo ]; then
  awk '/MemTotal:/ { printf "HOST_RAM_KIB=%s\n", $2 }' /proc/meminfo
fi

if command -v df >/dev/null 2>&1; then
  df -Pk . | awk 'NR==2 { printf "HOST_CWD_AVAILABLE_KIB=%s\n", $4 }'
fi

echo "===== REQUIRED TOOLS ====="
for tool in "${required_tools[@]}"; do
  if command -v "${tool}" >/dev/null 2>&1; then
    path="$(command -v "${tool}")"
    echo "TOOL_${tool}=PASS path=${path}"
  else
    echo "TOOL_${tool}=FAIL"
    missing=1
  fi
done

echo "===== OPTIONAL TOOLS ====="
for tool in "${optional_tools[@]}"; do
  if command -v "${tool}" >/dev/null 2>&1; then
    path="$(command -v "${tool}")"
    echo "OPTIONAL_TOOL_${tool}=PRESENT path=${path}"
  else
    echo "OPTIONAL_TOOL_${tool}=ABSENT"
  fi
done

if [ "${missing}" -ne 0 ]; then
  echo "SABLE_ENV_CHECK=FAIL"
  exit 1
fi

echo "SABLE_ENV_CHECK=PASS"
