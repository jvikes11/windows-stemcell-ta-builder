#!/usr/bin/env bash

echo "Deploy iso for $OS_NAME"


govc_iso_path="ISO/$OS_NAME.iso"


govc datastore.upload \
  -ds $GOVC_DATASTORE \
  iso/os.iso \
  $govc_iso_path

govc create.vm \
  -m $GOVC_MEMORY_MB \
  -c $GOVC_NUM_CPU \
  -disk $GOVC_DISK_GB \
  -datastore-cluster $GOVC_CLUSTER \
  -ds $GOVC_DATASTORE \
  -g $GOVC_GUEST_OS \
  -n $GOVC_NETWORK \
  -iso-datastore $GOVC_DATASTORE \
  -pool $GOVC_RESOURCE_POOL \
  -host $GOVC_HOST \
  -iso $govc_iso_path

exit 1
