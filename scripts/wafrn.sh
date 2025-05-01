#!/usr/bin/env bash

set -e

# Edit this if you have more than one stack to point to the one you want
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
  connect_sudo)
    ssh ubuntu@$IP_ADDRESS
    ;;
  update|backup|restore)
    ssh ubuntu@$IP_ADDRESS "sudo -u wafrn bash -c 'cd; /home/wafrn/wafrn/install/manage.sh $@'"
    ;;
  pdsadmin)
    shift
    COMMAND=$1
    shift
    ssh ubuntu@$IP_ADDRESS "sudo -u wafrn bash -c 'cd; /home/wafrn/wafrn/install/bsky/$COMMAND.sh $@'"
    ;;
  *)
    echo "Valid options:"
    echo "  init: Set up your private key to connect to WAFRN from the Stack"
    echo "  connect: Connect to the WAFRN instance through SSH as the wafrn user"
    echo "  connect_sudo: Connect to the WAFRN instance through SSH as a user with sudo access"
    echo "  update: Download latest wafrn from repository, update and restart"
    echo "  backup: Create backup of the current wafrn files"
    echo "  pdsadmin: Allows running some bluesky management scripts. Valid options: add-insert-code create-admin delete-user list-users takedown-user untakedown-user user-reset-password"
    echo "  restore: Restore a specific backup"
    exit 1
    ;;
esac
