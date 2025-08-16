

# homelab-iac

## Intro

Repo for managing all the underlying infrastructre in my homelab including Mikrotik, Junos, Kuberneties and Vultr cloud.

## tfencrypt.sh

Encrypts the decrypts the sensitive state file so it can be commited to Github.

## Router

Expands on the default configuration of the Mikrotik device. Only import required is the bridge.

'''
terraform import routeros_interface_bridge.bridge "*1"
'''