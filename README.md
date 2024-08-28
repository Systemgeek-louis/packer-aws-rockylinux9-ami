# packer-aws-rockylinux9-ami
Using Packer I am creating a RockyLinux9 AMI that boots with BIOS and uses LVM for the OS. 

Please note that I have commented out some of the provisioners in rocky9.v3.pkr.hcl becasue they
contained company info.

To run this code:
1. Install Packer on your machine
2. Create IAM role in AWS
3. Run the script runpacker.sh
