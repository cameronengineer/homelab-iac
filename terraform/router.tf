data "routeros_interfaces" "interfaces" {
  provider = routeros.router
}

resource "routeros_interface_bridge" "bridge" {
  provider = routeros.router
  name           = "bridge"
  vlan_filtering = true
}

resource "routeros_interface_ethernet" "ether_interfaces" {
  provider         = routeros.router
  for_each = {
    for interface in data.routeros_interfaces.interfaces.interfaces :
    interface.name => interface if interface.type == "ether"
  }

  factory_name     = each.value.default_name
  name             = each.value.name
  auto_negotiation = strcontains(each.value.name, "sfp") ? false : true
}

resource "routeros_system_identity" "identity" {
  provider = routeros.router
  name = "homelab_router"
}

resource "routeros_system_ntp_client" "ntp" {
  provider = routeros.router
  enabled = true
  mode    = "unicast"
  servers = [
    "0.au.pool.ntp.org", 
    "1.au.pool.ntp.org", 
    "2.au.pool.ntp.org", 
    "3.au.pool.ntp.org"]
}

resource "routeros_system_ntp_server" "test" {
  provider = routeros.router
  enabled             = true
  broadcast           = true
  multicast           = true
  manycast            = true
  use_local_clock     = true
  local_clock_stratum = 3
}

resource "routeros_ip_dns" "dns-server" {
  provider = routeros.router
  allow_remote_requests = true
  servers = [
    "1.1.1.2",
    "1.0.0.2",
    "2606:4700:4700::1112",
    "2606:4700:4700::1002",
  ]
}

## IPV6 DHCP


resource "routeros_ipv6_dhcp_client" "client" {
  provider = routeros.router
  pool_name          = "dhcp_v6"
  interface          = "ether1"
  add_default_route  = true
  use_peer_dns       = false
  pool_prefix_length = 64
  request            = ["address", "prefix"]
}

## IPv6 for default/bridge network

resource "routeros_ipv6_address" "bridge" {
  provider = routeros.router
  address   = "::/64"
  eui_64    = true
  advertise = true
  from_pool = routeros_ipv6_dhcp_client.client.pool_name
  interface = "bridge"

  lifecycle {
    ignore_changes = [
      address,
    ]
  }
}

## VLAN 10

resource "routeros_interface_vlan" "trusted_vpn_vlan_10" {
  provider = routeros.router
  interface = "bridge"
  name      = "trusted_vpn_vlan_10"
  vlan_id   = 10
}

resource "routeros_interface_list_member" "trusted_vpn_vlan_10" {
  provider = routeros.router
  interface = routeros_interface_vlan.trusted_vpn_vlan_10.name
  list      = "LAN"
}

resource "routeros_ipv6_address" "trusted_vpn_vlan_10" {
  provider = routeros.router
  address   = "::/64"
  eui_64    = true
  advertise = true
  from_pool = routeros_ipv6_dhcp_client.client.pool_name
  interface = routeros_interface_vlan.trusted_vpn_vlan_10.name

  lifecycle {
    ignore_changes = [
      address,
    ]
  }
}

resource "routeros_ip_address" "trusted_vpn_vlan_10" {
  provider  = routeros.router
  address   = "10.31.10.1/24"
  interface = routeros_interface_vlan.trusted_vpn_vlan_10.name
}

resource "routeros_ip_pool" "trusted_vpn_vlan_10" {
  provider = routeros.router
  name     = routeros_interface_vlan.trusted_vpn_vlan_10.name
  ranges   = ["10.31.10.10-10.31.10.200"]
}

resource "routeros_ip_dhcp_server" "trusted_vpn_vlan_10" {
  provider     = routeros.router
  address_pool = routeros_ip_pool.trusted_vpn_vlan_10.name
  interface    = routeros_interface_vlan.trusted_vpn_vlan_10.name
  name         = routeros_interface_vlan.trusted_vpn_vlan_10.name
}

resource "routeros_ip_dhcp_server_network" "trusted_vpn_vlan_10" {
  provider   = routeros.router
  comment    = routeros_interface_vlan.trusted_vpn_vlan_10.name
  address    = cidrsubnet(routeros_ip_address.trusted_vpn_vlan_10.address, 0, 0)
  gateway    = cidrhost(routeros_ip_address.trusted_vpn_vlan_10.address, 1)
  dns_server = [cidrhost(routeros_ip_address.trusted_vpn_vlan_10.address, 1)]
  ntp_server = [cidrhost(routeros_ip_address.trusted_vpn_vlan_10.address, 1)]
}

## VLAN 15

resource "routeros_interface_vlan" "trusted_novpn_vlan_15" {
  provider = routeros.router
  interface = "bridge"
  name      = "trusted_novpn_vlan_15"
  vlan_id   = 15
}

resource "routeros_interface_list_member" "trusted_novpn_vlan_15" {
  provider = routeros.router
  interface = routeros_interface_vlan.trusted_novpn_vlan_15.name
  list      = "LAN"
}

resource "routeros_ipv6_address" "trusted_novpn_vlan_15" {
  provider = routeros.router
  address   = "::/64"
  eui_64    = true
  advertise = true
  from_pool = routeros_ipv6_dhcp_client.client.pool_name
  interface = routeros_interface_vlan.trusted_novpn_vlan_15.name

  lifecycle {
    ignore_changes = [
      address,
    ]
  }
}

resource "routeros_ip_address" "trusted_novpn_vlan_15" {
  provider = routeros.router
  address   = "10.31.15.1/24"
  interface = routeros_interface_vlan.trusted_novpn_vlan_15.name
}

resource "routeros_ip_pool" "trusted_novpn_vlan_15" {
  provider = routeros.router
  name     = routeros_interface_vlan.trusted_novpn_vlan_15.name
  ranges   = ["10.31.15.10-10.31.15.200"]
}

resource "routeros_ip_dhcp_server" "trusted_novpn_vlan_15" {
  provider     = routeros.router
  address_pool = routeros_ip_pool.trusted_novpn_vlan_15.name
  interface    = routeros_interface_vlan.trusted_novpn_vlan_15.name
  name         = routeros_interface_vlan.trusted_novpn_vlan_15.name
}

resource "routeros_ip_dhcp_server_network" "trusted_novpn_vlan_15" {
  provider   = routeros.router
  comment    = routeros_interface_vlan.trusted_novpn_vlan_15.name
  address    = cidrsubnet(routeros_ip_address.trusted_novpn_vlan_15.address, 0, 0)
  gateway    = cidrhost(routeros_ip_address.trusted_novpn_vlan_15.address, 1)
  dns_server = [cidrhost(routeros_ip_address.trusted_novpn_vlan_15.address, 1)]
  ntp_server = [cidrhost(routeros_ip_address.trusted_novpn_vlan_15.address, 1)]
}

## VLAN 20

resource "routeros_interface_vlan" "untrusted_vpn_vlan_20" {
  provider = routeros.router
  interface = "bridge"
  name      = "untrusted_vpn_vlan_20"
  vlan_id   = 20
}

resource "routeros_interface_list_member" "untrusted_vpn_vlan_20" {
  provider = routeros.router
  interface = routeros_interface_vlan.untrusted_vpn_vlan_20.name
  list      = "LAN"
}


resource "routeros_ipv6_address" "untrusted_vpn_vlan_20" {
  provider = routeros.router
  address   = "::/64"
  eui_64    = true
  advertise = true
  from_pool = routeros_ipv6_dhcp_client.client.pool_name
  interface = routeros_interface_vlan.untrusted_vpn_vlan_20.name

  lifecycle {
    ignore_changes = [
      address,
    ]
  }
}

resource "routeros_ip_address" "untrusted_vpn_vlan_20" {
  provider = routeros.router
  address   = "10.31.20.1/24"
  interface = routeros_interface_vlan.untrusted_vpn_vlan_20.name
}

resource "routeros_ip_pool" "untrusted_vpn_vlan_20" {
  provider = routeros.router
  name     = routeros_interface_vlan.untrusted_vpn_vlan_20.name
  ranges   = ["10.31.20.10-10.31.20.200"]
}

resource "routeros_ip_dhcp_server" "untrusted_vpn_vlan_20" {
  provider = routeros.router
  address_pool = routeros_ip_pool.untrusted_vpn_vlan_20.name
  interface    = routeros_interface_vlan.untrusted_vpn_vlan_20.name
  name         = routeros_interface_vlan.untrusted_vpn_vlan_20.name
}

resource "routeros_ip_dhcp_server_network" "untrusted_vpn_vlan_20" {
  provider   = routeros.router
  comment    = routeros_interface_vlan.untrusted_vpn_vlan_20.name
  address    = cidrsubnet(routeros_ip_address.untrusted_vpn_vlan_20.address, 0, 0)
  gateway    = cidrhost(routeros_ip_address.untrusted_vpn_vlan_20.address, 1)
  dns_server = [cidrhost(routeros_ip_address.untrusted_vpn_vlan_20.address, 1)]
  ntp_server = [cidrhost(routeros_ip_address.untrusted_vpn_vlan_20.address, 1)]
}

## VLAN 25

resource "routeros_interface_vlan" "untrusted_novpn_vlan_25" {
  provider = routeros.router
  interface = "bridge"
  name      = "untrusted_novpn_vlan_25"
  vlan_id   = 25
}

resource "routeros_interface_list_member" "untrusted_novpn_vlan_25" {
  provider = routeros.router
  interface = routeros_interface_vlan.untrusted_novpn_vlan_25.name
  list      = "LAN"
}


resource "routeros_ipv6_address" "untrusted_novpn_vlan_25" {
  provider = routeros.router
  address   = "::/64"
  eui_64    = true
  advertise = true
  from_pool = routeros_ipv6_dhcp_client.client.pool_name
  interface = routeros_interface_vlan.untrusted_novpn_vlan_25.name

  lifecycle {
    ignore_changes = [
      address,
    ]
  }
}

resource "routeros_ip_address" "untrusted_novpn_vlan_25" {
  provider = routeros.router
  address   = "10.31.25.1/24"
  interface = routeros_interface_vlan.untrusted_novpn_vlan_25.name
}

resource "routeros_ip_pool" "untrusted_novpn_vlan_25" {
  provider = routeros.router
  name     = routeros_interface_vlan.untrusted_novpn_vlan_25.name
  ranges   = ["10.31.25.10-10.31.25.200"]
}

resource "routeros_ip_dhcp_server" "untrusted_novpn_vlan_25" {
  provider = routeros.router
  address_pool = routeros_ip_pool.untrusted_novpn_vlan_25.name
  interface    = routeros_interface_vlan.untrusted_novpn_vlan_25.name
  name         = routeros_interface_vlan.untrusted_novpn_vlan_25.name
}

resource "routeros_ip_dhcp_server_network" "untrusted_novpn_vlan_25" {
  provider   = routeros.router
  comment    = routeros_interface_vlan.untrusted_novpn_vlan_25.name
  address    = cidrsubnet(routeros_ip_address.untrusted_novpn_vlan_25.address, 0, 0)
  gateway    = cidrhost(routeros_ip_address.untrusted_novpn_vlan_25.address, 1)
  dns_server = [cidrhost(routeros_ip_address.untrusted_novpn_vlan_25.address, 1)]
  ntp_server = [cidrhost(routeros_ip_address.untrusted_novpn_vlan_25.address, 1)]
}

## 

resource "routeros_interface_bridge_vlan" "bridge_vlan" {
  provider = routeros.router
  bridge   = "bridge"
  vlan_ids = [
    routeros_interface_vlan.trusted_vpn_vlan_10.vlan_id,
    routeros_interface_vlan.trusted_novpn_vlan_15.vlan_id,
    routeros_interface_vlan.untrusted_vpn_vlan_20.vlan_id,
    routeros_interface_vlan.untrusted_novpn_vlan_25.vlan_id
  ]
  tagged   = [for interface in data.routeros_interfaces.interfaces.interfaces : interface.name if interface.slave != false]
}

resource "routeros_interface_wireguard" "nz-akl-wg-301" {
  provider    = routeros.router
  name        = "nz-akl-wg-301"
  listen_port = "13231"
}

resource "routeros_interface_wireguard" "nz-akl-wg-302" {
  provider    = routeros.router
  name        = "nz-akl-wg-3012"
  listen_port = "13232"
}