Put variables in variables.tf, like:

variable "project" {
  type    = string
  default = "gcp_project_name"
}

variable "region" {
  type    = string
  default = "gcp_region"
}

variable "zone" {
  type    = string
  default = "gcp_zone"
}

This terraform project will setup small gcp environment with two instances.

Prerequisit is metadata with public key.

One instance will be accessible from internet via ssh over public ip address.
This instance will be able to ssh to nat instances with private key which will
be copyed with startup script.

Second instance will not be accessible from internet, but will be able to get
updates over nat from internet.

Both instances will have ssh access required for gui console enabled.

Resources whitch will be created:
  - network
  - one subnet for vm's with nat/internal ip address 
  - one subnet for vm's with external and internal ip addresses ( bastion )
  - one firewall rule for console access from Google cloud gui
  - one firewall rule for bastion hosts ssh access to nat subnet vm's
  - one firewall rule for ssh access from internet to bastion hosts
  - one cloud router for Cloud Nat
  - one nat gateway for Cloud Nat
  - one instance in bastion subnet
  - one instance in nat subnet

bastionKey.sh should look like:
$ cat ../../../vmBastionInternal/bastionKey.sh
#!/bin/bash
cat >/tmp/privateKey <<EOF
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAABlwAAAAdzc2gtcn
.....rest of private key......
N9+e1VeroVyIkAAAAVZXRva3JhbEB1YnVudHUyMjA0Z3VpAQIDBAUG
-----END OPENSSH PRIVATE KEY-----
EOF

Run to create environment:
$ terraform init
$ terraform validate
$ terraform fmt
$ terraform apply

Run to destroy environment:
$ terraform destroy
