
variable "region" {
  type    = string
  default = "us-east-1"
}

variable "env" {
  type = string
}

packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

locals {
  amazon_account = "099720109477"
  version_tag    = formatdate("YYYYMMDDhhmmss", timestamp())
  default_tags = {
    "mediasci:provisioner"        = "packer"
    "mediasci:version-tag"        = local.version_tag
    "mediasci:project"            = "aicw"
    "mediasci:env:${var.env}"     = "true"
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name        = "aiwc-librechat-${local.version_tag}"
  ami_description = "LibreChat running on Amazon Linux for AICW project"
  instance_type   = "t4g.2xlarge"
    region          = var.region
  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name                = "ubuntu-minimal/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-minimal-*"
      root-device-type    = "ebs"
    }
    owners = [
      local.amazon_account
    ]
    most_recent = true
  }

  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 30
    volume_type = "gp3"
    delete_on_termination = true
  }

  ssh_username = "ubuntu"

  run_tags = local.default_tags

  tags = local.default_tags
}

build {
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "shell" {
    scripts = [
      "${path.root}/scripts/01_setup_machine.sh",
    ]
    environment_vars = [
      "LIBRE_CHAT_ENV=${var.env}",
    ]
  }

  provisioner "shell-local" {
    inline = [
      "mkdir -p build",
      "git ls-files --cached -z | tar --null -czf build/libre-chat.tar.gz --files-from=-",
    ]
  }

  provisioner "file" {
    destination = "/var/tmp/libre-chat.tar.gz"
    source      = "build/libre-chat.tar.gz"
    generated   = true
  }

  provisioner "file" {
    destination = "/var/tmp/firstrun.sh"
    source      = "${path.root}/files/firstrun.sh"
  }

  provisioner "file" {
    destination = "/var/tmp/fetch-secrets.sh"
    source      = "${path.root}/files/fetch-secrets.sh"
  }

  provisioner "file" {
    destination = "/var/tmp/libre-chat.service"
    source      = "${path.root}/files/libre-chat.service"
  }

  provisioner "file" {
    destination = "/var/tmp/librechat.mediasci.yaml"
    source      = "${path.root}/files/librechat.mediasci.yaml"
  }

  provisioner "shell" {
    scripts = [
      "${path.root}/scripts/02_build.sh",
    ]
  }
}
