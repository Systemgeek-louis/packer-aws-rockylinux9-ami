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
# Other misc tasks from official CentOS 7 kickstart
echo "[>>> Other misc tasks from official CentOS 7 kickstart"
chroot "${ROOTFS}" sed -e '/^#NAutoVTs=.*/ a\
NAutoVTs=0' -i /etc/systemd/logind.conf

sed -r -e 's/ec2-user/rocky/g' -e 's/(groups: \[)(adm)/\1wheel, \2/' /etc/cloud/cloud.cfg > "${ROOTFS}/etc/cloud/cloud.cfg"

echo "[>> Start some services"
chroot "${ROOTFS}" systemctl enable sshd.service
chroot "${ROOTFS}" systemctl enable systemd-hostnamed.service
chroot "${ROOTFS}" systemctl enable cloud-init.service
chroot "${ROOTFS}" systemctl mask tmp.mount
chroot "${ROOTFS}" systemctl set-default multi-user.target
chroot "${ROOTFS}" systemctl disable auditd

echo "[>> Disabling SELinux"
sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' ${ROOTFS}/etc/selinux/config

echo "[>> enable tmp.mount"
chroot "${ROOTFS}" systemctl unmask tmp.mount
cp ${ROOTFS}/usr/lib/systemd/system/tmp.mount ${ROOTFS}/etc/systemd/system/
chroot "${ROOTFS}" systemctl daemon-reload

################################################################################
#Set some default files
cat > "${ROOTFS}/etc/hosts" <<'EOF'
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

EOF

touch "${ROOTFS}/etc/resolv.conf"

echo 'RUN_FIRSTBOOT=NO' > "${ROOTFS}/etc/sysconfig/firstboot"

cat > "${ROOTFS}/etc/sysconfig/network" <<'EOF'
NETWORKING=yes
NOZEROCONF=yes
EOF

################################################################################
# Optional: install Amazon Linux 2 package ec2-utils to the image.

rpm --root="${ROOTFS}" --import /tmp/tmp.ec2utils/RPM-GPG-KEY-amazon-linux-2
find /tmp/tmp.ec2utils -mindepth 1 -maxdepth 1 -name 'ec2-utils-*.rpm' -exec yum --installroot="${ROOTFS}" -y install '{}' \;
