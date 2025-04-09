
variable "region" {
  type    = string
  default = "eu-central-1"
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

source "amazon-ebs" "ubuntu-x86_64" {
  ami_name        = "aiwc-librechat-${local.version_tag}"
  ami_description = "LibreChat running on Amazon Linux for AICW project"
  instance_type   = "t3.large"
  region          = var.region
  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name                = "ubuntu-minimal/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-minimal-*"
      root-device-type    = "ebs"
    }
    owners = [
      local.amazon_account
    ]
    most_recent = true
  }
  ssh_username = "ubuntu"

  run_tags = local.default_tags

  tags = local.default_tags
}

build {
  sources = [
    "source.amazon-ebs.ubuntu-x86_64"
  ]

  provisioner "shell" {
    scripts = [
      "${path.root}/scripts/01_setup_machine.sh",
    ]
  }

  provisioner "shell-local" {
    inline = [
      "mkdir -p build",
      "git ls-files --cached -z | tar --null -czf build/libre-chat.tar.gz --files-from=-",
      "docker save libre-chat:latest | gzip > build/libre-chat.image.tar.gz"
    ]
  }

  provisioner "file" {
    destination = "/var/tmp/libre-chat.tar.gz"
    source      = "build/libre-chat.tar.gz"
    generated   = true
  }

  provisioner "file" {
    destination = "/var/tmp/libre-chat.image.tar.gz"
    source      = "build/libre-chat.image.tar.gz"
    generated   = true
  }

  provisioner "file" {
    destination = "/var/tmp/001-firstrun.sh"
    source      = "${path.root}/files/001-firstrun.sh"
  }

  provisioner "file" {
    destination = "/var/tmp/libre-chat.service"
    source      = "${path.root}/files/libre-chat.service"
  }

  provisioner "shell" {
    scripts = [
      "${path.root}/scripts/02_build.sh",
    ]
  }
}
