#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  create_cephfs.sh \
    --device-class <device_class> \
    --metadata-pool <metadata_pool_name> \
    --data-pool <data_pool_name> \
    --fs-name <fs_name>

Description:
  Run this script on any one Ceph node after all required OSDs have been created.

Arguments:
  --device-class   Ceph crush device class, for example ssd or hdd
  --metadata-pool  CephFS metadata pool name
  --data-pool      CephFS data pool name
  --fs-name        CephFS filesystem name
  --help           Show this help

Example:
  ./scripts/create_cephfs.sh \
    --device-class ssd \
    --metadata-pool cephfs_metadata_ssd \
    --data-pool cephfs_data_ssd \
    --fs-name cephfs-ssd
EOF
}

DEVICE_CLASS=""
METADATA_POOL=""
DATA_POOL=""
FS_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device-class)
      DEVICE_CLASS="$2"
      shift 2
      ;;
    --metadata-pool)
      METADATA_POOL="$2"
      shift 2
      ;;
    --data-pool)
      DATA_POOL="$2"
      shift 2
      ;;
    --fs-name)
      FS_NAME="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

for var_name in DEVICE_CLASS METADATA_POOL DATA_POOL FS_NAME; do
  if [[ -z "${!var_name}" ]]; then
    echo "Missing required argument for ${var_name}" >&2
    usage
    exit 1
  fi
done

run_cmd() {
  echo "+ $*"
  "$@"
}

RULE_NAME="rule-${DEVICE_CLASS}"

echo "Using auto-generated crush rule ${RULE_NAME}"

if ceph osd crush rule ls | grep -Fxq "${RULE_NAME}"; then
  echo "Crush rule ${RULE_NAME} already exists, reusing it"
else
  echo "Creating crush rule ${RULE_NAME}"
  run_cmd ceph osd crush rule create-replicated "${RULE_NAME}" default host "${DEVICE_CLASS}"
fi

echo "Creating CephFS metadata pool ${METADATA_POOL}"
run_cmd ceph osd pool create "${METADATA_POOL}" 32 replicated "${RULE_NAME}"

echo "Creating CephFS data pool ${DATA_POOL}"
run_cmd ceph osd pool create "${DATA_POOL}" 32 replicated "${RULE_NAME}"

echo "Enabling CephFS application on ${METADATA_POOL}"
run_cmd ceph osd pool application enable "${METADATA_POOL}" cephfs

echo "Enabling CephFS application on ${DATA_POOL}"
run_cmd ceph osd pool application enable "${DATA_POOL}" cephfs

echo "Creating CephFS filesystem ${FS_NAME}"
run_cmd ceph fs new "${FS_NAME}" "${METADATA_POOL}" "${DATA_POOL}"

echo "CephFS setup completed successfully"

# Made with Bob
