#!/bin/sh
# William Lam
# www.virtuallyghetto.com
# Simple script to pull down CoreOS image & run on ESXi
WF=${1}.sh
HF=${2}.sh

if [[ ! -f $WF ]]; then
 echo "Config file: ${WF} not exits..."
 exit 1
fi

if [[ -z $2 ]]; then
  echo "CoreOS Host is not set."
  exit 1
fi

source ${WF}
source ${HF}

mkdir -p ${DATASTORE_PATH}/iso
cd ${DATASTORE_PATH}/iso

# CoreOS ZIP URL
CORE_OS_DOWNLOAD_URL=http://${COREOS_CH}.release.core-os.net/amd64-usr/current/coreos_production_vmware_insecure.zip
# echo $CORE_OS_DOWNLOAD_URL

# Name of VM
VM_NAME=$2

# Creates CoreOS VM Directory and change into it
mkdir -p ${DATASTORE_PATH}/${VM_NAME}

if [[ ! -z $3 ]]; then
  echo "Cache image ${COREOS_CH} CoreOS enable."
  if [[ $3 == "clean" ]]; then
    if [[ -f ${COREOS_CH}_coreos.zip ]]; then
      echo "Delete ${COREOS_CH}_coreos.zip ..."
      rm ${COREOS_CH}_coreos.zip
    fi
  fi
  if [[ ! -f ${COREOS_CH}_coreos.zip ]]; then
    echo "Download CoreOS ..." 
    wget ${CORE_OS_DOWNLOAD_URL}
    mv coreos_production_vmware_insecure.zip ${COREOS_CH}_coreos.zip
  fi
  cp ${COREOS_CH}_coreos.zip ${DATASTORE_PATH}/${VM_NAME}/coreos_production_vmware_insecure.zip 
else
  cd ${DATASTORE_PATH}/${VM_NAME}
  echo "Cache image ${COREOS_CH} CoreOS disable."
  wget ${CORE_OS_DOWNLOAD_URL}
fi

cd ${DATASTORE_PATH}/${VM_NAME}

echo "Unzip CoreOS & remove file ..."
unzip coreos_production_vmware_insecure.zip
rm -f coreos_production_vmware_insecure.zip

# Convert VMDK from 2gbsparse from hosted products to Thin
vmkfstools -i coreos_production_vmware_insecure_image.vmdk -d thin coreos.vmdk

# Remove the original 2gbsparse VMDKs
rm coreos_production_vmware_insecure_image*.vmdk

# Update CoreOS VMX to reference new VMDK
sed -i 's/coreos_production_vmware_insecure_image.vmdk/coreos.vmdk/g' coreos_production_vmware_insecure.vmx

# Update CoreOS VMX w/new VM Name
sed -i "s/displayName.*/displayName = \"${VM_NAME}\"/g" coreos_production_vmware_insecure.vmx

# Update memory 2048 = 2Gb
if [[ ! -z ${H_RAM} ]]; then
sed -i "s/memSize.*/memSize = \"${H_RAM}\"/g" coreos_production_vmware_insecure.vmx
fi

# Update CoreOS VMX to map to VM Network
echo "ethernet0.networkName = \"${VM_NETWORK}\"" >> coreos_production_vmware_insecure.vmx
echo "ethernet0.virtualDev= \"${VM_INT}\"" >> coreos_production_vmware_insecure.vmx
if [[ ! -z ${H_MAC} ]]; then
  sed -i "s/ethernet0.addressType = \"generated\"/ethernet0.addressType = \"static\"/g" coreos_production_vmware_insecure.vmx
  echo "ethernet0.address = \"${H_MAC}\"" >> coreos_production_vmware_insecure.vmx
fi

# Register CoreOS VM which returns VM ID
VM_ID=$(vim-cmd solo/register ${DATASTORE_PATH}/${VM_NAME}/coreos_production_vmware_insecure.vmx)

# Guest Host Disk size
if [[ ! -z ${H_DISK} ]]; then
  vmkfstools -X ${H_DISK}g ${DATASTORE_PATH}/${VM_NAME}/coreos.vmdk
fi

# Upgrade CoreOS Virtual Hardware from 4 to 9
vim-cmd vmsvc/upgrade ${VM_ID} vmx-09

# PowerOn CoreOS VM
vim-cmd vmsvc/power.on ${VM_ID}

# # Reset CoreOS VM to quickly get DHCP address
# vim-cmd vmsvc/power.reset ${VM_ID}

# echo "Start ${VM_NAME} ID: ${VM_ID}"