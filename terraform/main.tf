terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
    }
    unifi = {
      source = "ubiquiti-community/unifi"
    }
  }
}

variable "router_username" {
  description = "RouterOS username"
  type        = string
}

variable "router_password" {
  description = "RouterOS password"
  type        = string
  sensitive   = true
}

variable "router_url" {
  description = "RouterOS URL"
  type        = string
}

provider "routeros" {
  alias    = "router"
  hosturl  = var.router_url
  username = var.router_username
  password = var.router_password
}

variable "unifi_username" {
  description = "Unifi username"
  type        = string
}

variable "unifi_password" {
  description = "Unifi password"
  type        = string
  sensitive   = true
}

variable "unifi_url" {
  description = "Unifi URL"
  type        = string
}

variable "unifi_insecure" {
  description = "Unifi allow insecure"
  type        = bool
}

provider "unifi" {
  username       = var.unifi_username
  password       = var.unifi_password
  api_url        = var.unifi_url
  allow_insecure = var.unifi_insecure
}