terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
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

resource "routeros_ip_address" "address" {
  provider  = routeros.router
  address   = "10.0.0.3/24"
  interface = "default"
  network   = "10.0.0.0"
}