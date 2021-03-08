#!/bin/bash

# Copyright 2013 Rackspace, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

log() {
    echo "`basename $0`: $@"
}

usage() {
    [[ -z "$1" ]] || echo -e "USAGE ERROR: $@\n"
    echo "`basename $0`: IMAGEFILE DEVICE"
    echo "  - This script images DEVICE with IMAGEFILE"
    exit 1
}

IMAGEFILE="$1"
DEVICE="$2"

[[ -f $IMAGEFILE ]] || usage "$IMAGEFILE (IMAGEFILE) is not a file"
[[ -b $DEVICE ]] || usage "$DEVICE (DEVICE) is not a block device"

# In production this will be replaced with secure erasing the drives
# For now we need to ensure there aren't any old (GPT) partitions on the drive
log "Erasing existing GPT and MBR data structures from ${DEVICE}"

# NOTE(gfidente): GPT uses 33*512 sectors, this is an attempt to avoid bug:
# https://bugs.launchpad.net/ironic-python-agent/+bug/1737556
DEVICE_SECTORS_COUNT=`blockdev --getsz $DEVICE`
dd bs=512 if=/dev/zero of=$DEVICE count=33
dd bs=512 if=/dev/zero of=$DEVICE count=33 seek=$((${DEVICE_SECTORS_COUNT} - 33))
sgdisk -Z $DEVICE

log "Imaging $IMAGEFILE to $DEVICE"

# limit the memory usage for qemu-img to 2 GiB
ulimit -v 2097152
qemu-img convert -t directsync -O host_device $IMAGEFILE $DEVICE
sync

log "${DEVICE} imaged successfully!"
