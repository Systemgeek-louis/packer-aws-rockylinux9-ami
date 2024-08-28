################################################################################
################################################################################
################################################################################
#!/bin/bash
#set -euo pipefail
IFS=$'\n\t'

ROOTFS=/rootfs
DEVICE="/dev/nvme1n1"
LVM="/dev/mapper"

arch="$( uname --machine )"

################################################################################
#Activate the VG and LV
echo "[>>> Activate the VG and LV"
vgchange -aay vol00
lvchange -aay /dev/mapper/vol00-root
lvchange -aay /dev/mapper/vol00-var
lvchange -aay /dev/mapper/vol00-var_lib_aide
lvchange -aay /dev/mapper/vol00-var_log
lvchange -aay /dev/mapper/vol00-var_log_audit
lvchange -aay /dev/mapper/vol00-home
lvchange -aay /dev/mapper/vol00-swap

if [[ ${arch} == "aarch64" ]]; then
  cat >> "${ROOTFS}/etc/fstab" <<EOF
UUID=$( lsblk "${DEVICE}p1" --noheadings --output uuid )          /boot/efi               vfat    defaults,uid=0,gid=0,umask=077,shortname=winnt 0 2
EOF
fi
