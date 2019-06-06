#!/usr/bin/env bash

exec >&2
set -e

source pipeline/ci/scripts/common.sh

echo "Deploy iso for $OS_NAME"


govc_iso_path="ISO/$OS_NAME.iso"


govc datastore.upload \
  -ds $GOVC_DATASTORE \
  iso/os.iso \
  $govc_iso_path

govc -dc $GOVC_DATACENTER vm.create \
  -m $GOVC_MEMORY_MB \
  -c $GOVC_NUM_CPU \
  -disk $GOVC_DISK_GB \
  -datastore-cluster $GOVC_CLUSTER \
  -ds $GOVC_DATASTORE \
  -folder $GOVC_FOLDER \
  -g $GOVC_GUEST_OS \
  -net $GOVC_NETWORK \
  -iso-datastore $GOVC_DATASTORE \
  -pool $GOVC_RESOURCE_POOL \
  -host $GOVC_HOST \
  -iso $govc_iso_path \
  $GOVC_VM_NAME

exit 1
