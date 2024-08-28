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
# Cleanup before creating AMI.
echo "[>>> Cleanup before creating AMI"

# SELinux, also cleans up /tmp
if ! getenforce | grep --quiet --extended-regexp '^Disabled$' ; then
  # Prevent relabel on boot (b/c next command will do it manually)
  rm --verbose --force "${ROOTFS}"/.autorelabel

  # Manually "restore" SELinux contexts ("relabel" clears /tmp and then runs "restore"). Requires '/sys/fs/selinux' to be mounted in the chroot.
  chroot "${ROOTFS}" /sbin/fixfiles -f -F relabel

  # Packages from https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html-single/using_selinux/index
  # that contain RPM scripts. Reinstall for the postinstall scriptlets.
  dnf --installroot="${ROOTFS}" --nogpgcheck -y reinstall selinux-policy-targeted policycoreutils
fi

# Repo cleanup
echo "[>>> Repo cleanup"
dnf --installroot="${ROOTFS}" --cacheonly --assumeyes clean all
rm --recursive --verbose --force "${ROOTFS}"/var/cache/dnf/*

# Clean up systemd machine ID file
echo "[>>> Clean up systemd machine ID file"
truncate --size=0 "${ROOTFS}"/etc/machine-id
chmod --changes 0444 "${ROOTFS}"/etc/machine-id

# Clean up /etc/resolv.conf
echo "[>>> Clean up /etc/resolv.conf"
truncate --size=0 "${ROOTFS}"/etc/resolv.conf

# Delete any logs
echo "[>>> Delete any logs"
find "${ROOTFS}"/var/log -type f -print -delete

# Cleanup cloud-init (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)
echo "[>>> Cleanup cloud-init"
rm --recursive --verbose "${ROOTFS}"/var/lib/cloud/

# Clean up temporary directories
echo "[>>> Clean up temporary directories"
find "${ROOTFS}"/run \! -type d -print -delete
find "${ROOTFS}"/run -mindepth 1 -type d -empty -print -delete
find "${ROOTFS}"/tmp \! -type d -print -delete
find "${ROOTFS}"/tmp -mindepth 1 -type d -empty -print -delete
find "${ROOTFS}"/var/tmp \! -type d -print -delete
find "${ROOTFS}"/var/tmp -mindepth 1 -type d -empty -print -delete

################################################################################
#Activate the VG and LV
echo "[>>> Activate the VG and LV for the second time"
vgchange -aay vol00
lvchange -aay /dev/mapper/vol00-root
lvchange -aay /dev/mapper/vol00-var
lvchange -aay /dev/mapper/vol00-var_lib_aide
lvchange -aay /dev/mapper/vol00-var_log
lvchange -aay /dev/mapper/vol00-var_log_audit
lvchange -aay /dev/mapper/vol00-home
lvchange -aay /dev/mapper/vol00-swap

# Don't /need/ this for packer because the instance is shut down before the volume is snapshotted, but it doesn't hurt...
umount --all-targets --recursive "${ROOTFS}"

################################################################################
echo "[>>> >>>>> All Done <<<<<"
exit 0
