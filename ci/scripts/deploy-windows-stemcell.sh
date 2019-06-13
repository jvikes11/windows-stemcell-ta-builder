#!/usr/bin/env bash

exec >&2
set -e

source pipeline/ci/scripts/common.sh

echo "Deploy stemcell for $OS_NAME"

stembuild_file_name=$(basename $(cat stembuild/metadata.json | jq -r '.ProductFiles | .[].AWSObjectKey' | grep linux))
chmod +x stembuild/$stembuild_file_name

cp lgpo-zip/LGPO.zip .

function construct_stemcell() {

  echo "creating stemcell"

  ./stembuild/$stembuild_file_name construct -vm-ip $VM_IP -vm-username $VM_ADMIN_USERNAME -vm-password $VM_ADMIN_PASSWORD -vcenter-url $GOVC_URL -vcenter-username $GOVC_USERNAME -vcenter-password $GOVC_PASSWORD -vm-inventory-path $GOVC_FOLDER/$GOVC_VM_NAME

}

function package_stemcell() {

  echo "packaging stemcell"

  ./stembuild/$stembuild_file_name package -vcenter-url $GOVC_URL -vcenter-username $GOVC_USERNAME -vcenter-password $GOVC_PASSWORD -vm-inventory-path $GOVC_FOLDER/$GOVC_VM_NAME

}

function upload_stemcell() {

  echo "uploading stemcell"

  stemcell_tgz=$(ls bosh-stemcell*.tgz)

  curl -u $ARTIFACTORY_USERNAME:$ARTIFACTORY_PASSWORD -i -k -X PUT -# -T $stemcell_tgz $ARTIFACTORY_URL/$stemcell_tgz

}

construct_stemcell
package_stemcell
upload_stemcell

exit 1
