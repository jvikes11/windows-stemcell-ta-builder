#!/usr/bin/env bash

exec >&2
set -e

source pipeline/ci/scripts/common.sh

echo "Deploy iso for $OS_NAME"


govc_iso_path="ISO/$OS_NAME.iso"
govc_img_path="ISO/Unattended-$OS_NAME.img"

function upload_files() {
  if echo `govc datastore.ls $govc_iso_path` | grep -q "not found" ; then
    govc datastore.upload \
      -ds $GOVC_DATASTORE \
      iso/windows.iso $govc_iso_path
  else
    echo "Skipping uploading core windows, found: $govc_iso_path"
  fi

  govc datastore.upload \
    -ds $GOVC_DATASTORE \
    base-floppy-img/base-floppy.img \
    $govc_img_path
}

function create_vm() {

  govc vm.create \
    -m $GOVC_MEMORY_MB \
    -c $GOVC_NUM_CPU \
    -disk $GOVC_DISK_GB \
    -dc $GOVC_DATACENTER \
    -ds $GOVC_DATASTORE \
    -folder $GOVC_FOLDER \
    -g $GOVC_GUEST_OS \
    -net $GOVC_NETWORK \
    -iso-datastore $GOVC_DATASTORE \
    -pool $GOVC_RESOURCE_POOL \
    -host $GOVC_HOST \
    $GOVC_VM_NAME

  govc vm.power -off $GOVC_VM_NAME

}

function initial_boot_vm() {
  local govc_hd_disk_name=$(govc device.info -vm $GOVC_VM_NAME -json | jq -r '.Devices | .[].Name' | grep disk)
  local govc_disk_controller_name=$(govc device.info -vm $GOVC_VM_NAME -json | jq -r '.Devices | .[].Name' | grep lsilogic)

  govc device.boot -vm $GOVC_VM_NAME -delay 1000 -order -
  govc device.remove -vm $GOVC_VM_NAME $govc_hd_disk_name
  govc device.remove -vm $GOVC_VM_NAME $govc_disk_controller_name
  govc device.scsi.add -vm $GOVC_VM_NAME -type lsilogic-sas
  govc vm.disk.create -vm $GOVC_VM_NAME -name $govc_hd_disk_name/disk1 -size $GOVC_DISK_GB -thick

  govc device.cdrom.add -vm $GOVC_VM_NAME
  govc device.cdrom.insert -vm $GOVC_VM_NAME $govc_iso_path

  govc device.floppy.add -vm $GOVC_VM_NAME
  govc device.floppy.insert -vm $GOVC_VM_NAME $govc_img_path

  govc device.boot -vm $GOVC_VM_NAME -delay 1000 -order cdrom,disk,ethernet,floppy

  govc vm.power -on $GOVC_VM_NAME

#  govc vm.info -json $GOVC_VM_NAME | jq -r '.VirtualMachines | .[].Summary.Runtime.PowerState'
#
  echo "waiting for machine to start"

  while :; do
    ping -q -c1 $VM_IP >/dev/null 2>&1
    if [ $? -ne 0 ]; then
      break
    else
      printf "\r."
    fi
    sleep 5
  done

  echo "machine started"
}

function customize_vm() {
  echo "customize vm"

  pwsh config/default/windows_stemcell_builder/test.ps1
}

upload_files
create_vm
initial_boot_vm
customize_vm

#govc vm.guest.tools -mount $GOVC_VM_NAME

exit 1
