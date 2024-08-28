################################################################################
################################################################################
################################################################################
#!/bin/bash
#set -euo pipefail
IFS=$'\n\t'

ROOTFS=/rootfs
DEVICE="/dev/nvme1n1"
efiDEVICE="/boot/efi"
biosDEVICE="/boot"
LVM="/dev/mapper"

arch="$( uname --machine )"

################################################################################
# Run to complete bootloader setup and create /boot/grub2/grubenv
echo "[>>> Run to complete bootloader setup and create /boot/grub2/grubenv"
#if [[ ${arch} == "aarch64" ]]; then
#  chroot "${ROOTFS}" grub2-mkconfig -o /etc/grub2-efi.cfg
#else
umount ${efiDEVICE}
umount ${biosDEVICE}
echo "[>>> Mount points after the unmount"
mount
echo "[>>>>>>>>>><<<<<<<<<<"
 echo "GRUB_DISABLE_LINUX_UUID=true" >> ${ROOTFS}/etc/default/grub
 echo "GRUB_ENABLE_BLSCFG=true" >> ${ROOTFS}/etc/default/grub
 echo "GRUB_ENABLE_LINUX_LABEL=true" >> ${ROOTFS}/etc/default/grub
echo "[>>> chroot ${ROOTFS} grub2-install --target i386-pc ${DEVICE}"
  chroot "${ROOTFS}" grub2-install --target i386-pc "${DEVICE}"
echo "[>>> chroot ${ROOTFS} grub2-mkconfig -o /etc/grub2.cfg"
  chroot "${ROOTFS}" grub2-mkconfig -o /etc/grub2.cfg
#fi

# Read-only/print command
echo "[>>> chroot ${ROOTFS} grubby --default-kernel"
chroot "${ROOTFS}" grubby --default-kernel
echo "[>>> chroot ${ROOTFS} grubby --update-kernel=ALL --args=audit=off selinux=0"
chroot "${ROOTFS}" grubby --update-kernel=ALL --args=audit=off selinux=0
