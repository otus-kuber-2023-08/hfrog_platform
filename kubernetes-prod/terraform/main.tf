terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"

  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    region = "ru-central1"
    key    = "terraform/main.tfstate"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

provider "yandex" {
  zone = "ru-central1-b"
}

variable "image_id" {
  default = "fd85an6q1o26nf37i2nl" # ubuntu-20-04-lts-v20231218
#  default = "fd866d9q7rcg6h4udadk" # ubuntu-22-04-lts-v20231225
}

variable "ssh-keys" {
#  default = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
}

variable "master_count" {
  default = 3
}

variable "worker_count" {
  default = 2
}

variable "lb_count" {
  default = 1
}

locals {
  lb_names = toset([for i in range(1, var.lb_count + 1) : "lb-${i}"])
  names = toset(concat(
    [for i in range(1, var.master_count + 1) : "master-${i}"],
    [for i in range(1, var.worker_count + 1) : "worker-${i}"],
    tolist(local.lb_names)
  ))
}

# reserve static external IP for load balancers
resource "yandex_vpc_address" "lb" {
  for_each = local.lb_names
  name     = each.value

  external_ipv4_address {
    zone_id = "ru-central1-b"
  }
}

resource "yandex_compute_instance" "instance" {
  for_each = local.names
  name     = each.value
  hostname = each.value

  resources {
    cores         = 2
    core_fraction = 20
    memory        = startswith(each.value, "lb") ? 2 : 8
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = startswith(each.value, "lb") ? 5 : 20
    }
  }

  network_interface {
    subnet_id      = yandex_vpc_subnet.subnet-1.id
    nat            = true
    nat_ip_address = startswith(each.value, "lb") ? yandex_vpc_address.lb[each.value].external_ipv4_address[0].address : null
  }

  metadata = {
    ssh-keys = var.ssh-keys
  }
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

output "internal_ip" {
  value = { for name in local.names : name => yandex_compute_instance.instance[name].network_interface[0].ip_address }
}

output "external_ip" {
  value = { for name in local.names : name => yandex_compute_instance.instance[name].network_interface[0].nat_ip_address }
}
