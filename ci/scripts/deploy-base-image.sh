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

  echo "waiting for machine to start"

  while :
  do
    count=$( ping -c 1 $VM_IP | grep icmp* | wc -l )

    if [ $count -eq 0 ]; then
      echo "host still down"
      sleep 5
    else
      echo "host up"
      break
    fi
  done

  echo "machine started"

  local govc_cdrom_name=$(govc device.info -vm $GOVC_VM_NAME -json | jq -r '.Devices | .[].Name' | grep cdrom)
  local govc_floppy_name=$(govc device.info -vm $GOVC_VM_NAME -json | jq -r '.Devices | .[].Name' | grep floppy)

  govc device.disconnect -vm $GOVC_VM_NAME $govc_cdrom_name
  govc device.disconnect -vm $GOVC_VM_NAME $govc_floppy_name

}

function install_vmware_tools() {
  echo "installing vmware tools"

  govc vm.guest.tools -mount $GOVC_VM_NAME
  sleep 10

  pwsh pipeline/powershell/install-vmware-tools.ps1

  govc vm.guest.tools -unmount $GOVC_VM_NAME
}

function customize_vm() {
  echo "customize vm"

  pwsh pipeline/powershell/customize-base-image.ps1
}

upload_files
create_vm
initial_boot_vm
install_vmware_tools
customize_vm

exit 1
