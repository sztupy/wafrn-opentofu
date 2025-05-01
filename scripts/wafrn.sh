#!/usr/bin/env bash

set -e

STACK_ID=`oci resource-manager stack list -c $OCI_TENANCY | jq -r ".data[0].id"`
IP_ADDRESS=`oci resource-manager stack get-stack-tf-state --stack-id $STACK_ID --file - | jq -r '.outputs.lb_public_ip.value'`

echo "Stack ID: $STACK_ID"
echo "IP Address: $IP_ADDRESS"

case $1 in
  init)
    echo "Initiating SSH keys from OCI"
    echo "Note: this will only work if you have not been providing your own private key during setup"
    echo
    oci resource-manager stack get-stack-tf-state --stack-id $STACK_ID --file - | jq -r '.outputs.generated_private_key_pem.value' > ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa
    ;;
  connect)
    ssh ubuntu@$IP_ADDRESS -t 'sudo su -l wafrn'
    ;;
  update|backup|restore)
    ssh ubuntu@$IP_ADDRESS "sudo -u wafrn /home/wafrn/wafrn/install/manage.sh $@"
    ;;
  *)
    echo "Valid options:"
    echo "  init: Set up your private key to connect to WAFRN from the Stack"
    echo "  connect: Connect to the WAFRN instance through SSH"
    echo "  update: Download latest wafrn from repository, update and restart"
    echo "  backup: Create backup of the current wafrn files"
    echo "  restore: Restore a specific backup"
    exit 1
    ;;
esac
