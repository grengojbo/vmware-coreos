#!/usr/bin/vmware
.encoding = "UTF-8"
config.version = "8"
virtualHW.version = "9"
cleanShutdown = "TRUE"
displayName = "coreos09"
ethernet0.addressType = "static"
ethernet0.present = "TRUE"
guestOS = "other26xlinux-64"
memsize = "3072"
powerType.powerOff = "soft"
powerType.powerOn = "hard"
powerType.reset = "hard"
powerType.suspend = "hard"
scsi0.present = "TRUE"
scsi0.virtualDev = "lsilogic"
scsi0:0.fileName = "coreos.vmdk"
scsi0:0.present = "TRUE"
usb.generic.autoconnect = "FALSE"
usb.present = "TRUE"
rtc.diffFromUTC = 0
ethernet0.networkName = "vlan107"
ethernet0.virtualDev= "vmxnet3"
ethernet0.address = "00:50:56:aa:bb:35"
scsi0:0.deviceType = "scsi-hardDisk"
extendedConfigFile = "coreos_production_vmware_insecure.vmxf"
virtualHW.productCompatibility = "hosted"
floppy0.present = "FALSE"
sound.present = "FALSE"
hpet0.present = "TRUE"
usb.vbluetooth.startConnected = "TRUE"