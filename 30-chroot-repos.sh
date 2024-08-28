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
# Grab the latest release and repos packages.
echo "[>>> Grab the latest release and repos packages"
release_pkg_latest="$( curl --silent https://dl.rockylinux.org/pub/rocky/9/BaseOS/${arch}/os/Packages/r/ | grep 'rocky-release-9[^"]*.rpm' | sort --unique --version-sort | tail -1 | awk -F'\"' '{print $2}' )"
release_pkg_url="https://dl.rockylinux.org/pub/rocky/9/BaseOS/${arch}/os/Packages/r/${release_pkg_latest}"

repos_pkg_latest="$( curl --silent https://dl.rockylinux.org/pub/rocky/9/BaseOS/${arch}/os/Packages/r/ | grep 'rocky-repos-9[^"]*.rpm' | sort --unique --version-sort | tail -1 | awk -F'\"' '{print $2}' )"
repos_pkg_url="https://dl.rockylinux.org/pub/rocky/9/BaseOS/${arch}/os/Packages/r/${repos_pkg_latest}"

echo "[>>> release_pkg_latest = ${release_pkg_latest}"
echo "[>>> release_pkg_url = ${release_pkg_url}"
echo "[>>> repos_pkg_latest = ${repos_pkg_latest}"
echo "[>>> repos_pkg_url = ${repos_pkg_url}"

rpm --root="${ROOTFS}" --initdb
rpm --root="${ROOTFS}" --nodeps -ivh "${release_pkg_url}"
rpm --root="${ROOTFS}" --nodeps -ivh "${repos_pkg_url}"

echo "[>> Run an update with nogpgcheck"
# Note: using "--nogpgcheck" so users of the resulting AMI still need to confirm GPG key usage
dnf --installroot="${ROOTFS}" --nogpgcheck -y update
