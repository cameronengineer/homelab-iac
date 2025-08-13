

# homelab-iac

## Intro

Repo for managing all the underlying infrastructre in my homelab including Mikrotik, Junos, Kuberneties and Vultr cloud.

## tfencrypt.sh

Encrypts the decrypts the sensitive state file so it can be commited to Github.

'''
[INFO] Terraform State Encryption Wrapper
========================================
[INFO] No unencrypted state files found
[INFO] Decrypting state files...
[INFO] Decrypting terraform.tfstate.gpg to terraform.tfstate...
[INFO] Successfully decrypted terraform.tfstate.gpg
[INFO] Running terraform with arguments: plan
----------------------------------------
routeros_ip_address.address: Refreshing state... [id=*E]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.
----------------------------------------
[INFO] Terraform command completed with exit code: 0
[INFO] Preparing to re-encrypt state files...

[INFO] Cleaning up and ensuring encryption...
[INFO] Re-encrypting terraform.tfstate...
[INFO] Successfully encrypted terraform.tfstate to terraform.tfstate.gpg
[INFO] Cleanup complete
'''