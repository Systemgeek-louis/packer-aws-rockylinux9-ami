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
# Copy from RHEL8
echo "[>>> Copy from RHEL8"
mkdir "${ROOTFS}/etc/default"
cp -av /etc/default/grub "${ROOTFS}/etc/default/grub"

################################################################################
# Refer to https://github.com/CentOS/sig-cloud-instance-build/blob/master/cloudimg/CentOS-7-x86_64-hvm.ks
# for rationale for most excludes and removes.

ARM_PKGS=()
if [[ ${arch} == "aarch64" ]]; then
  ARM_PKGS+=('efibootmgr' 'shim')
fi

echo "[>>> Install the base os"
set +u
dnf --installroot="${ROOTFS}" --nogpgcheck -y install \
  --exclude="iwl*firmware" \
  --exclude="libertas*firmware" \
  --exclude="firewalld*" \
  "@Minimal Install" \
  "@standard" \
  kexec-tools \
  rocky-gpg-keys \
  chrony \
  cloud-init \
  cloud-utils-growpart \
  dracut-config-generic \
  grub2-tools-minimal \
  grub2-tools-efi \
  grub2-tools \
  grub2-tools-extra \
  grub2-common \
  grub2-pc \
  grub2-pc-modules \
  grubby \
  kernel \
  python3 \
  yum-utils \
  python3-pip \
  curl \
  ethtool \
  git \
  lvm2 \
  hostname 

set -u

if [ -f "${ROOTFS}"/etc/selinux/config ]; then
    echo "Permissive SELinux..."
	sudo sed -i "s/enforcing/permissive/" "${ROOTFS}"/etc/selinux/config
fi
