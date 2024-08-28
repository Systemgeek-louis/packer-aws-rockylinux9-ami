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
# Misc CIS-CAT Settings
#echo "[>> Run lockdown from CIS-CAT"
#chroot "${ROOTFS}" curl --insecure https://gp2us1opsfm01-main01a.example.net/pulp/content/Library/custom/Ops_-_Custom_-_noarch/Ops_Custom_noarch/rocky_linux_8.CIS-LBK.tar.gz -o /root/rocky_linux_8.CIS-LBK.tar.gz

#chroot "${ROOTFS}"  tar zxvf /root/rocky_linux_8.CIS-LBK.tar.gz 
#mv "${ROOTFS}"/CIS-LBK "${ROOTFS}"/root/CIS-LBK
#chroot "${ROOTFS}" chmod 755 /root/CIS-LBK/cis_lbk_rocky_linux_8/rocky_linux_8.sh
chroot "${ROOTFS}" 
dnf --installroot="${ROOTFS}" --nogpgcheck -y install expect

env ROOTFS="${ROOTFS}" expect <<'EOS'
    set ROOTFS $env(ROOTFS)

    spawn /root/CIS-LBK/cis_lbk_rocky_linux_8/rocky_linux_8.sh

    expect "Do you want to continue?"
    send -- "y\r"

    expect "Please enter the number for the desired profile:"
    send -- "3\r"

    expect eof
EOS
exit
