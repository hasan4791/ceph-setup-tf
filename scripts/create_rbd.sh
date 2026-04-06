#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  create_rbd.sh \
    --device-class <device_class> \
    --rbd-pool <rbd_pool_name> \
    --rbd-name <rbd_name> \
    [--rbd-size 100G]

Description:
  Run this script on any one Ceph node after the required device class
  is available in the cluster. The crush rule is generated automatically
  as rule-<device_class> and created only if it does not already exist.

Arguments:
  --device-class   Ceph device class used while creating the pool
  --rbd-pool       RBD pool name
  --rbd-name       RBD image name
  --rbd-size       RBD image size, default: 100G
  --help           Show this help

Example:
  ./scripts/create_rbd.sh \
    --device-class ssd \
    --rbd-pool rbd_ssd \
    --rbd-name rbd01 \
    --rbd-size 100G
EOF
}

DEVICE_CLASS=""
RBD_POOL=""
RBD_NAME=""
RBD_SIZE="100G"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device-class)
      DEVICE_CLASS="$2"
      shift 2
      ;;
    --rbd-pool)
      RBD_POOL="$2"
      shift 2
      ;;
    --rbd-name)
      RBD_NAME="$2"
      shift 2
      ;;
    --rbd-size)
      RBD_SIZE="$2"
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

for var_name in DEVICE_CLASS RBD_POOL RBD_NAME; do
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

echo "Creating RBD pool ${RBD_POOL}"
run_cmd ceph osd pool create "${RBD_POOL}" 32 "${DEVICE_CLASS}"

echo "Enabling PG autoscaling on ${RBD_POOL}"
run_cmd ceph osd pool set "${RBD_POOL}" pg_autoscale_mode on

echo "Initializing RBD pool ${RBD_POOL}"
run_cmd rbd pool init "${RBD_POOL}"

echo "Creating RBD image ${RBD_NAME} with size ${RBD_SIZE}"
run_cmd rbd create --size "${RBD_SIZE}" --pool "${RBD_POOL}" "${RBD_NAME}"

echo "Listing RBD images"
run_cmd rbd ls -l

echo "RBD setup completed successfully"

# Made with Bob
