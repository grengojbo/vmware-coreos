#!/bin/bash
TOOLS=${1}
if [[ ! -d /usr/share/oem/bin/vmtoolsd ]]; then
  echo "untar ${TOOLS}..."
  sudo tar xjf /home/core/${TOOLS}
  echo "Install ${TOOLS}..."
  sudo chown root.root -R {/home/core/etc,/home/core/usr}
  sudo cp -R /home/core/usr/share/oem/{bin,include,lib64,vmware-tools} /usr/share/oem/
  sudo rm -Rf {/home/core/etc,/home/core/usr}
  # sudo rm -f /home/core/${TOOLS}
  if [[ -f libdnet.so.1.0.1 ]]; then
    sudo mv /home/core/libdnet.so.1.0.1 /usr/share/oem/lib64/
    sudo ln -sf /usr/share/oem/lib64/libdnet.so.1.0.1 /usr/share/oem/lib64/libdnet.so.1
    sudo ln -sf /usr/share/oem/lib64/libdnet.so.1.0.1 /usr/share/oem/lib64/libdnet.so
  fi
else
  echo "VMware tools already installed."
fi