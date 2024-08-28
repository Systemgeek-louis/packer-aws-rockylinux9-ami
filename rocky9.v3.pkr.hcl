locals {
  timestamp = timestamp()
}

packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

# Thx to https://github.com/jen20/packer-ubuntu-zfs/blob/master/focal/template.pkr.hcl

source "amazon-ebssurrogate" "x86_64" {
  # Unable to use "source_ami_filter" with the correct wildcards for getting x86_64 without potentially matching a beta
  # Use https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Images:visibility=public-images;ownerAlias=309956199498;architecture=x86_64;name=RHEL-8;sort=name
  # when ready to bump to a newer AMI.
  source_ami = "ami-01ed6e3767aa5ab34"

  instance_type = "t3.small"
  region        = "us-east-1"
  vpc_id        = "vpc-2fcda356"
  subnet_id     = "subnet-c9c69981"

  launch_block_device_mappings {
    device_name           = "/dev/sdf"
    delete_on_termination = true
    volume_size           = 50
    volume_type           = "gp3"
  }

  run_tags = {
    Name = "Packer EL9 Builder (x86_64)"
  }
  run_volume_tags = {
    Name = "Packer EL9 Builder"
  }

  communicator = "ssh"
  ssh_pty      = true
  ssh_username = "rocky"
  ssh_timeout  = "5m"

  ami_name                = "Base-Rocky-9-(x86_64)-{{timestamp}}"
  ami_description         = "Base-Rocky-9-(x86_64)-{{timestamp}}"
  ami_virtualization_type = "hvm"
  ami_architecture        = "x86_64"
  ena_support             = true
  sriov_support           = true
  ami_regions             = []
  ami_root_device {
    source_device_name    = "/dev/sdf"
    device_name           = "/dev/sda1"
    delete_on_termination = true
    volume_size           = 8
    volume_type           = "gp3"
  }

  tags = {
    Name      = "Base Rocky 9 (x86_64) ${local.timestamp}"
    BuildTime = timestamp()
  }
}

build {
  sources = [
    "source.amazon-ebssurrogate.x86_64",
  ]
  provisioner "shell" {
    script          = "10-chroot-buildOutDisk.sh"
    execute_command = "sudo -S sh -c '{{ .Vars }} {{ .Path }}'"

    start_retry_timeout = "5m"
    skip_clean          = true
  }
  provisioner "shell" {
    script          = "20-chroot-updateSystemBuilder.sh"
    execute_command = "sudo -S sh -c '{{ .Vars }} {{ .Path }}'"

    start_retry_timeout = "5m"
    skip_clean          = true
  }
  provisioner "shell" {
    script          = "30-chroot-repos.sh"
    execute_command = "sudo -S sh -c '{{ .Vars }} {{ .Path }}'"

    start_retry_timeout = "5m"
    skip_clean          = true
  }
  provisioner "shell" {
    script          = "40-chroot-fstab.sh"
    execute_command = "sudo -S sh -c '{{ .Vars }} {{ .Path }}'"

    start_retry_timeout = "5m"
    skip_clean          = true
  }
  provisioner "shell" {
    script          = "50-chroot-activateLVM.sh"
    execute_command = "sudo -S sh -c '{{ .Vars }} {{ .Path }}'"

    start_retry_timeout = "5m"
    skip_clean          = true
  }
  provisioner "shell" {
    script          = "60-chroot-installSoftware.sh"
    execute_command = "sudo -S sh -c '{{ .Vars }} {{ .Path }}'"

    start_retry_timeout = "5m"
    skip_clean          = true
  }
  provisioner "shell" {
    script          = "70-chroot-grub.sh"
    execute_command = "sudo -S sh -c '{{ .Vars }} {{ .Path }}'"

    start_retry_timeout = "5m"
    skip_clean          = true
  }
  provisioner "shell" {
    script          = "80-chroot-servicesPrep.sh"
    execute_command = "sudo -S sh -c '{{ .Vars }} {{ .Path }}'"

    start_retry_timeout = "5m"
    skip_clean          = true
  }
  #provisioner "shell" {
  #  script          = "90-chroot-createUsers.sh"
  #  execute_command = "sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
#
#    start_retry_timeout = "5m"
#    skip_clean          = true
#  }
  provisioner "shell" {
    script          = "100-chroot-lockdownCIS.sh"
    execute_command = "sudo -S sh -c '{{ .Vars }} {{ .Path }}'"

    start_retry_timeout = "5m"
    skip_clean          = true
  }
  #    provisioner "shell" {
  #    script          = "200-chroot-miscCISCAT.sh"
  #    execute_command = "sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
  ##
  #    start_retry_timeout = "5m"
  #    skip_clean          = true
  #  }
  provisioner "shell" {
    script          = "300-chroot-finalCleanup.sh"
    execute_command = "sudo -S sh -c '{{ .Vars }} {{ .Path }}'"

    start_retry_timeout = "5m"
    skip_clean          = true
  }
}
