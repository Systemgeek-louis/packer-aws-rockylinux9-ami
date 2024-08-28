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
# Update builder system on the local host
dnf -y update

# Install missing packages for building on the local host
dnf -y install expect podman python2

# Download and install the ec2-utils package from the Amazon Linux 2 core repository.
# This is optional. If skipped, you might need to use a different value for ${DEVICE}.

echo "[>>> mkdir /tmp/tmp.ec2utils"
mkdir /tmp/tmp.ec2utils

cat <<'EOS' | podman run --rm -v '/tmp/tmp.ec2utils:/work:Z' --workdir='/work' -i 'docker.io/library/amazonlinux:2'
yum -y install yum-utils
yumdownloader --enablerepo=amzn2-core ec2-utils
rpm2cpio "$( yumdownloader --enablerepo=amzn2-core --urls system-release | grep -E '^https' | sort --field-separator='/' --key=6 --version-sort | tail -1 )" | cpio --quiet --extract --to-stdout ./etc/pki/rpm-gpg/RPM-GPG-KEY-amazon-linux-2 > RPM-GPG-KEY-amazon-linux-2
EOS

rpm --import /tmp/tmp.ec2utils/RPM-GPG-KEY-amazon-linux-2
find /tmp/tmp.ec2utils -mindepth 1 -maxdepth 1 -name 'ec2-utils-*.rpm' -exec yum -y install '{}' \;

echo "[>>> udevadm control and trigger"
udevadm control --reload-rules
udevadm trigger
