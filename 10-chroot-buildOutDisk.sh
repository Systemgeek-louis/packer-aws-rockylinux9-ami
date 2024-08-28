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
# Partition the Disk

# Wait for udev to create symlink for secondary disk
echo "[>>> Wait for udev to create symlink for secondary disk"
while [[ ! -e "${DEVICE}" ]]; do echo ">>> Waiting..."; sleep 1; done

# Read-only/print command
ls -ld /dev/nvme*

# Use an EFI partition for aarch64
echo "[>>> Use an EFI partition for aarch64"
if [[ ${arch} == "aarch64" ]]; then

  # On GPT disks, "esp" is an alias for "boot". (https://www.gnu.org/software/parted/manual/html_node/set.html)
  echo "[>>> On GPT disks, esp is an alias for boot"
  parted --script "${DEVICE}" -- \
    mklabel gpt \
    mkpart primary fat32 1 201MiB \
    mkpart primary xfs 201MiB -1 \
    set 1 esp on

  # With gpt disks, "primary" becomes the partition label, so we change or remove with the name command
  echo "[>>> With gpt disks, primary becomes the partition label, so we change or remove with the name command"
  env DEVICE="${DEVICE}" expect <<'EOS'
    set device $env(DEVICE)

    spawn parted "${DEVICE}"

    expect "(parted) "
    send "name 1 'EFI System Partition'\r"

    expect "(parted) "
    send "name 2\r"
    expect "Partition name? "
    send "''\r"

    expect "(parted) "
    send "print \r"

    expect "(parted) "
    send "quit\r"

    expect eof
EOS

  # Set the main partition as a variable
  echo "[>>> Set the main partition as a variable. After EOS"
  PARTITION="${DEVICE}p2"

  ls -l /dev/${DEVICE}*

  # Wait for device partition creation
  echo "[>>> Wait for device partition creation"
  while [[ ! -e "${DEVICE}p1" ]]; do sleep 1; done

  # /boot/efi
  echo "[>>> /boot/efi"
  mkfs.fat -F 16 "${DEVICE}p1"

else

# Must assume I am on a RHEL type host
echo "[>>> Install LVM2"
yum -y install lvm2 lvm2-libs

  #Try doing gpt
  parted ${DEVICE} mklabel msdos
  parted ${DEVICE} mkpart primary xfs 0% 1G
  parted ${DEVICE} set 1 boot on
  parted ${DEVICE} mkpart primary xfs 1G 100%
  parted ${DEVICE} print

  ls -l ${DEVICE}*

  BOOTPart="${DEVICE}p1"
  PARTITION="${DEVICE}p2"

fi

# Wait for device partition creation
echo "[>>> Wait for device partition creation"
while [[ ! -e "${PARTITION}" ]]; do sleep 1; done

################################################################################
# LVM Section
echo "[>>> Create the pv and the vg"
pvcreate "${DEVICE}p2"
vgcreate vol00 "${DEVICE}p2"

echo "[>>> Create root"
lvcreate -L 19G -n root vol00
echo "[>>> Create home"
lvcreate -L 2G -n home vol00
echo "[>>> Create var"
lvcreate -L 6G -n var vol00
echo "[>>> Create var_log"
lvcreate -L 4G -n var_log vol00
echo "[>>> Create var_log_audit"
lvcreate -L 4G -n var_log_audit vol00
echo "[>>> Create var_lib_aide"
lvcreate -L 200M -n var_lib_aide vol00
echo "[>>> Create swap"
lvcreate -L 4G -n swap vol00

# Make the file systems
echo "[>>> Make the file systems"
mkfs.xfs -f ${DEVICE}p1
mkfs.xfs -f "${LVM}/vol00-root"
mkfs.xfs -f  "${LVM}/vol00-var"
mkfs.xfs -f  "${LVM}/vol00-var_log"
mkfs.xfs -f  "${LVM}/vol00-var_log_audit"
mkfs.xfs -f  "${LVM}/vol00-var_lib_aide"
mkfs.xfs -f  "${LVM}/vol00-home"
mkswap "${LVM}/vol00-swap"

# Read-only/print commands
echo "[>>> Read-only/print commands"
ls -ld /dev/nvme*
parted "${DEVICE}" print
fdisk -l "${DEVICE}"
df -h

################################################################################
# Chroot Mount /
# Make and mount the dirs for the
echo "[>>> Make and mount the dirs"

echo "[>>> ${ROOTFS}"
mkdir -p "${ROOTFS}"
mount "${LVM}/vol00-root" "${ROOTFS}"

echo "[>>> ${ROOTFS}/var"
mkdir -p "${ROOTFS}/var"
mount "${LVM}/vol00-var" "${ROOTFS}/var"

echo "[>>> ${ROOTFS}/var/log"
mkdir -p "${ROOTFS}/var/log"
mount "${LVM}/vol00-var_log" "${ROOTFS}/var/log"

echo "[>>> ${ROOTFS}/var/log/audit"
mkdir -p "${ROOTFS}/var/log/audit"
mount "${LVM}/vol00-var_log_audit" "${ROOTFS}/var/log/audit"

echo "[>>> ${ROOTFS}/var/lib/aide"
mkdir -p "${ROOTFS}/var/lib/aide"
mount "${LVM}/vol00-var_lib_aide" "${ROOTFS}/var/lib/aide"

echo "[>>> ${ROOTFS}/home"
mkdir -p "${ROOTFS}/home"
mount "${LVM}/vol00-home" "${ROOTFS}/home"

echo "[>>> ${ROOTFS}/boot"
mkdir -p "${ROOTFS}/boot"
mount "${DEVICE}p1" "${ROOTFS}/boot"

if [[ ${arch} == "aarch64" ]]; then
  # Chroot Mount /boot/efi
  echo "[>>> Chroot Mount /boot/efi"
  mkdir -p "${ROOTFS}/boot/efi"
  mount "${DEVICE}p1" "${ROOTFS}/boot/efi"
fi

# Special filesystems
echo "[>>> Special filesystems"
mkdir -p "${ROOTFS}/dev" "${ROOTFS}/proc" "${ROOTFS}/sys"
mount -o bind          /dev     "${ROOTFS}/dev"
mount -t devpts        devpts   "${ROOTFS}/dev/pts"
mount --types tmpfs    tmpfs    "${ROOTFS}/dev/shm"
mount --types proc     proc     "${ROOTFS}/proc"
mount --types sysfs    sysfs    "${ROOTFS}/sys"
mount --types selinuxfs selinuxfs "${ROOTFS}/sys/fs/selinux"

# Read-only/print commands
echo "[>>> Read-only/print commands SECOND time"
mount
ls -ld /dev/nvme*
parted "${DEVICE}" print
fdisk -l "${DEVICE}"
df -h
