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
sleep 5
mount
echo "[>>>>>>>>>><<<<<<<<<<"
echo "GRUB_DISABLE_LINUX_UUID=true" >> ${ROOTFS}/etc/default/grub
echo "GRUB_ENABLE_LINUX_LABEL=true" >> ${ROOTFS}/etc/default/grub
echo "GRUB_DISABLE_RECOVERY=true" >> ${ROOTFS}/etc/default/grub
echo "GRUB_DISABLE_OS_PROBER=false" >> ${ROOTFS}/etc/default/grub
echo  "[>>> Move /etc/grub.d/30_os-prober"
mv ${ROOTFS}/etc/grub.d/30_os-prober ${ROOTFS}/etc/grub.d/.30_os-prober
chmod 444 ${ROOTFS}/etc/grub.d/.30_os-prober

echo "[>>> chroot ${ROOTFS} grub2-install --target i386-pc ${DEVICE}"
chroot "${ROOTFS}" grub2-install --target i386-pc "${DEVICE}"
echo "[>>> chroot ${ROOTFS} grub2-mkconfig -o /etc/grub2.cfg"
chroot "${ROOTFS}" grub2-mkconfig -o /etc/grub2.cfg

console=ttyS0,115200n8 no_timer_check crashkernel=auto net.ifnames=0 nvme_core.io_timeout=4294967295 nvme_core.max_retries=10 root=/dev/mapper/vol00-root ro rd.shell audit=off


echo "[>>>>>>>>>><<<<<<<<<<"
# Read-only/print command
echo "[>>> chroot ${ROOTFS} grubby --default-kernel"
chroot "${ROOTFS}" grubby --default-kernel
echo "[>>> chroot ${ROOTFS} grubby --update-kernel=ALL --args=audit=off selinux=0"
chroot "${ROOTFS}" grubby --update-kernel=ALL --args=audit=off selinux=0

# Grubby seems to be broken in kernel 5.14.????  
# This is the hack work around:
# Yes I am replacing the entire line in /etc/kernel/cmdline

echo "[>>> console=ttyS0,115200n8 no_timer_check crashkernel=auto net.ifnames=0 nvme_core.io_timeout=4294967295 nvme_core.max_retries=10 root=/dev/mapper/vol00-root ro rd.shell audit=off > /etc/kernel/cmdline"
echo "console=ttyS0,115200n8 no_timer_check crashkernel=auto net.ifnames=0 nvme_core.io_timeout=4294967295 nvme_core.max_retries=10 root=/dev/mapper/vol00-root ro rd.shell audit=off > /etc/kernel/cmdline"
# This seems to work now and updates /boot/loader/entries/*.conf and /etc/grub2.cfg
echo "[>>> chroot ${ROOTFS} grub2-mkconfig --update-bls-cmdline -o /etc/grub2.cfg"
chroot "${ROOTFS}" grub2-mkconfig --update-bls-cmdline -o /etc/grub2.cfg
echo "[>>> Check the changes"
echo "[>>> grep vol00-root /etc/kernel/cmdline"
grep vol00-root /etc/kernel/cmdline
echo "[>>> grep vol00-root /boot/loader/entries/*.conf"
grep vol00-root /boot/loader/entries/*.conf
echo "[>>> grep vol00-root /etc/grub2.cfg"
grep vol00-root /etc/grub2.cfg




#Make sure "root=/dev/mapper/vol00-root ro  rd.shell" is in /etc/kernel/cmdline
#grub2-mkconfig --update-bls-cmdline -o /etc/grub2.cfg

#This should update /etc/kernel/cmdline, /boot/loader/entries/*.conf, /etc/grub2.cfg
#grubby --info ALL

#Look at this too:
#
#yum update -y
#source /etc/default/grub
#NEWKER=$(grubby --default-kernel)
#grubby --args="root=/dev/mapper/vol00-root ${GRUB_CMDLINE_LINUX}" --update-kernel="${NEWKER}"
#grubby --remove-args="inst.repo inst.stage2 ip inst.ks" --update-kernel="${NEWKER}"

###
# see https://forums.rockylinux.org/t/rocky-9-kernel-5-14-0-70-17-1-el9-0-x86-64-system-falls-to-boot/6837/4
# see https://forums.rockylinux.org/t/switch-to-boot-by-label-with-grub2-in-rocky-9/15269/2
