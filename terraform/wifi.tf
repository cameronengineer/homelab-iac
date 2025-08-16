
data "unifi_ap_group" "default" {
}

data "unifi_user_group" "default" {
}

## VLAN 10

resource "unifi_network" "trusted_vpn_vlan_10" {
  name    = routeros_interface_vlan.trusted_vpn_vlan_10.name
  purpose = "corporate"
  vlan_id = routeros_interface_vlan.trusted_vpn_vlan_10.vlan_id
}

variable "trusted_vpn_vlan_10_wifi_password" {
  description = "CC-HOME-TRUSTED-VPN Password"
  type        = string
}

resource "unifi_wlan" "trusted_vpn_vlan_10" {
  name            = "CC-HOME-TRUSTED-VPN"
  passphrase      = var.trusted_vpn_vlan_10_wifi_password
  security        = "wpapsk"
  wlan_band       = "both"
  wpa3_support    = true
  wpa3_transition = true
  pmf_mode        = "optional"
  network_id      = unifi_network.trusted_vpn_vlan_10.id
  ap_group_ids    = [data.unifi_ap_group.default.id]
  user_group_id   = data.unifi_user_group.default.id
}

## VLAN 15

resource "unifi_network" "trusted_novpn_vlan_15" {
  name    = routeros_interface_vlan.trusted_novpn_vlan_15.name
  purpose = "corporate"
  vlan_id = routeros_interface_vlan.trusted_novpn_vlan_15.vlan_id
}

variable "trusted_novpn_vlan_15_wifi_password" {
  description = "CC-HOME-TRUSTED-NOVPN Password"
  type        = string
}

resource "unifi_wlan" "trusted_novpn_vlan_15" {
  name            = "CC-HOME-TRUSTED-NOVPN"
  passphrase      = var.trusted_novpn_vlan_15_wifi_password
  security        = "wpapsk"
  wlan_band       = "both"
  wpa3_support    = true
  wpa3_transition = true
  pmf_mode        = "optional"
  network_id      = unifi_network.trusted_novpn_vlan_15.id
  ap_group_ids    = [data.unifi_ap_group.default.id]
  user_group_id   = data.unifi_user_group.default.id
}

## VLAN 20

resource "unifi_network" "untrusted_vpn_vlan_20" {
  name    = routeros_interface_vlan.untrusted_vpn_vlan_20.name
  purpose = "corporate"
  vlan_id = routeros_interface_vlan.untrusted_vpn_vlan_20.vlan_id
}

variable "untrusted_vpn_vlan_20_wifi_password" {
  description = "CC-HOME-TRUSTED-NOVPN Password"
  type        = string
}

resource "unifi_wlan" "untrusted_vpn_vlan_20" {
  name            = "CC-HOME-UNTRUSTED-VPN"
  passphrase      = var.untrusted_vpn_vlan_20_wifi_password
  security        = "wpapsk"
  wlan_band       = "both"
  wpa3_support    = true
  wpa3_transition = true
  pmf_mode        = "optional"
  network_id      = unifi_network.untrusted_vpn_vlan_20.id
  ap_group_ids    = [data.unifi_ap_group.default.id]
  user_group_id   = data.unifi_user_group.default.id
}


## VLAN 25

# resource "unifi_network" "untrusted_novpn_vlan_25" {
#   name    = routeros_interface_vlan.untrusted_novpn_vlan_25.name
#   purpose = "corporate"
#   vlan_id = routeros_interface_vlan.untrusted_novpn_vlan_25.vlan_id
# }

# variable "untrusted_novpn_vlan_25_wifi_password" {
#   description = "CC-HOME-UNTRUSTED-NOVPN Password"
#   type        = string
# }

# resource "unifi_wlan" "untrusted_novpn_vlan_25" {
#   name            = "CC-HOME-UNTRUSTED-NOVPN"
#   passphrase      = var.untrusted_novpn_vlan_25_wifi_password
#   security        = "wpapsk"
#   wlan_band       = "both"
#   wpa3_support    = true
#   wpa3_transition = true
#   pmf_mode        = "optional"
#   network_id      = unifi_network.untrusted_novpn_vlan_25.id
#   ap_group_ids    = [data.unifi_ap_group.default.id]
#   user_group_id   = data.unifi_user_group.default.id
# }
