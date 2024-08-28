/usr/bin/packer init .
/usr/bin/packer fmt .
/usr/bin/packer validate .
echo ">>> Running Build"
/usr/bin/packer build .
