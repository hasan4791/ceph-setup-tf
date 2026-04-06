#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  create_new_osd.sh \
    --device /dev/sdX \
    --device-class <device_class> \
    --osd-id <osd_id>

Description:
  Run this script on each Ceph node where a new local disk must be added as an OSD.

Arguments:
  --device         Block device path, for example /dev/sda
  --device-class   Ceph crush device class, for example ssd or hdd
  --osd-id         OSD id to start, for example 3
  --help           Show this help

Example:
  ./scripts/create_new_osd.sh \
    --device /dev/sda \
    --device-class ssd \
    --osd-id 3
EOF
}

DEVICE=""
DEVICE_CLASS=""
OSD_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device)
      DEVICE="$2"
      shift 2
      ;;
    --device-class)
      DEVICE_CLASS="$2"
      shift 2
      ;;
    --osd-id)
      OSD_ID="$2"
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

for var_name in DEVICE DEVICE_CLASS OSD_ID; do
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

echo "Rescanning SCSI bus"
run_cmd rescan-scsi-bus.sh -a -m -r

echo "Validating block device ${DEVICE}"
if [[ ! -b "${DEVICE}" ]]; then
  echo "Device does not exist or is not a block device: ${DEVICE}" >&2
  exit 1
fi

echo "Zapping existing Ceph metadata on ${DEVICE}"
run_cmd ceph-volume lvm zap --destroy "${DEVICE}"

echo "Preparing raw OSD on ${DEVICE} with device class ${DEVICE_CLASS}"
run_cmd ceph-volume raw prepare --objectstore bluestore --data "${DEVICE}" --crush-device-class "${DEVICE_CLASS}"

echo "Showing down OSDs tree state before starting requested OSD"
run_cmd ceph osd tree down

echo "Starting OSD service ceph@osd.${OSD_ID}"
run_cmd systemctl start "ceph@osd.${OSD_ID}"

echo "New OSD setup completed successfully"

# Made with Bob
