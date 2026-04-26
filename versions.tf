terraform {
  required_version = ">= 1.3.0"

  required_providers {
    vngcloud = {
      source  = "vngcloud/vngcloud"
      version = ">= 1.2.7"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">= 2.3.0"
    }
  }
}