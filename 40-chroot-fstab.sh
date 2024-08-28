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
#Prep and make the fstab
echo "[>> Get the UUID of /boot"
BootUUID=`blkid |grep /dev/nvme0n1p1|awk '{print $2}'|tr -d 'UUID="'`
echo "[>> UUID = ${BootUUID}"

# Similar to RHEL8 (but, without a separate partition for /boot)
echo "[>>> Create the FSTab file"
cat > "${ROOTFS}/etc/fstab" <<EOF
#
# /etc/fstab
#
/dev/mapper/vol00-root	/	xfs	defaults	0 0
/dev/mapper/vol00-var	/var	xfs	defaults,nodev,nosuid	0 0
/dev/mapper/vol00-var_lib_aide	/var/lib/aide	xfs	defaults	0 0
/dev/mapper/vol00-var_log	/var/log	xfs	defaults,nodev,noexec,nosuid	0 0
/dev/mapper/vol00-var_log_audit	/var/log/audit	xfs	defaults,nodev,noexec,nosuid	0 0
/dev/mapper/vol00-swap	none	swap	defaults	0 0
tmpfs	/tmp	tmpfs	defaults,rw,nosuid,nodev,noexec,relatime,size=2G	0 0
tmpfs	/var/tmp	tmpfs	defaults,rw,nosuid,nodev,noexec,relatime,size=2G	0 0
none	/dev/shm	tmpfs	defaults,nodev,noexec,nosuid	0 0
/dev/mapper/vol00-home	/home	xfs	defaults,nodev,noexec,nosuid	0 0
EOF

cat >> "${ROOTFS}/etc/fstab" <<EOF
UUID=$( lsblk "${DEVICE}p1" --noheadings --output uuid ) /boot xfs	defaults	0 0
EOF

cat "${ROOTFS}/etc/fstab"
