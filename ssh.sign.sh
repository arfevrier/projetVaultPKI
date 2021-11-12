#!/bin/bash

#-- Vault configuration
VAULT_URL="https://vault.4as:8200/v1"
AUTH_TYPE="ldap"

#-- Start Script
echo "-> SSH Signer <-"
read -p "Enter username: " USERNAME
read -p "Enter password: " -s PASSWORD
echo ""
echo "----------------"

TOKEN=$(curl $VAULT_URL/auth/$AUTH_TYPE/login/$USERNAME --request POST --data "{\"password\":\"$PASSWORD\"}" --insecure -s | jq -r '.auth.client_token')
if [ $TOKEN = "null" ]
then
      echo "Error password"
      exit
fi

#read -p "Enter the role needed [admin]: " ROLE
ROLE=${ROLE:-admin}
read -p "Requested SSH login user: " REQ_USER

#Get the public key of the current user
PUBLICKEY=$(cat ~/.ssh/id_rsa.pub)
#Sign it
SIGNEDKEY=$(curl $VAULT_URL/ssh-4as/sign/$REQ_USER -H "X-Vault-Token: $TOKEN" --request POST --data "{\"valid_principals\":\"$REQ_USER\", \"public_key\":\"$PUBLICKEY\"}" --insecure -s | jq -r '.data.signed_key')

if [ "$SIGNEDKEY" = "null" ]
then
      echo "Impossible to sign your ssh key [~/.ssh/id_rsa.pub] for $REQ_USER"
      exit
fi

echo $SIGNEDKEY > ~/.ssh/id_rsa-cert.pub
