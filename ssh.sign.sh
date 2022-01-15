#!/bin/bash

#-- Vault configuration
VAULT_NAME="vault.4as"
VAULT_URL="https://vault.4as:8200/v1"
AUTH_TYPE="ldap"

#-- Start Script
echo "-> SSH Signer | $VAULT_NAME <-"
read -p "Enter username: " USERNAME
read -p "Enter password: " -s PASSWORD
echo ""
echo "----------------"

TOKEN=$(curl $VAULT_URL/auth/$AUTH_TYPE/login/$USERNAME --request POST --data "{\"password\":\"$PASSWORD\"}" -s | jq -r '.auth.client_token')
if [ $TOKEN = "null" ]
then
      echo "/!\ Incorrect username or password"
      exit
fi

read -p "Access needed [opsi/reseau]: " REQ_PRINCP

#Get the public key of the current user
PUBLICKEY=$(cat ~/.ssh/id_rsa.pub)
#Sign it
SIGNEDKEY=$(curl $VAULT_URL/ssh-4as/sign/$REQ_PRINCP -H "X-Vault-Token: $TOKEN" --request POST --data "{\"valid_principals\":\"$REQ_PRINCP\", \"public_key\":\"$PUBLICKEY\"}" -s | jq -r '.data.signed_key')

if [ "$SIGNEDKEY" = "null" ]
then
      echo "/!\ Impossible to sign your ssh key [~/.ssh/id_rsa.pub] for $REQ_PRINCP principal"
      echo "    Requested access not authorized for your account"
      exit
fi

echo $SIGNEDKEY > ~/.ssh/id_rsa-cert.pub

#Update the known_hosts file
SSH_HOST_PUBLIC_KEY=$(curl $VAULT_URL/ssh-4as-host/public_key -s)
touch ~/.ssh/known_hosts
if [[ -z `cat ~/.ssh/known_hosts | grep "@cert-authority \*\.4as"` ]]; then
	echo "@cert-authority *.4as $SSH_HOST_PUBLIC_KEY\n" >> ~/.ssh/known_hosts
else
	sed -i "/\@cert-authority \*\.4as/c @cert-authority \*\.4as $SSH_HOST_PUBLIC_KEY" ~/.ssh/known_hosts
fi
