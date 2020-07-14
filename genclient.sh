#!/bin/bash

set -e

if [[ $# < 1 || ($# > 2 && "$2" != "--cbc") ]] ; then
	echo "Usage $0 <client-name> [--cbc]"
	exit 1
fi

if [[ ! -f .vpn_admin ]] ; then
    echo "This is not a VPN-Admin directory!"
    exit 1
fi

if [[ "$2" == "--cbc" ]] ; then
    export CIPHER="AES-256-CBC"
else
    export CIPHER="AES-256-GCM"
fi

SCRIPT_ROOT=$(realpath $(dirname $0))
EASYRSA="$SCRIPT_ROOT/EasyRSA-3.0.4/easyrsa --use-algo=ec --curve=secp521r1 --batch "

NAME="$1"
export ADDRESS="$(cat server/external_address)"
export PORT="$(cat server/external_port)"

mkdir "client_$NAME"

# Station = Client
printf "\x1b[32m\x1b[1mClient\x1b[0m\n"
pushd "client_$NAME"
$EASYRSA init-pki
$EASYRSA --req-cn="$NAME" gen-req "${NAME}-client" nopass
popd

# CA
printf "\x1b[32m\x1b[1mCA\x1b[0m\n"
pushd ca
$EASYRSA import-req "../client_$NAME/pki/reqs/${NAME}-client.req" "${NAME}-client"
$EASYRSA --req-cn="${NAME}-client" sign-req client "${NAME}-client"
popd


printf "\x1b[32m\x1b[1mGenerating OpenVPN configurations\x1b[0m\n"
envsubst < ${SCRIPT_ROOT}/base-client.conf > "${NAME}-client.ovpn"

cat <(echo -e '<ca>') \
    ca/pki/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    ca/pki/issued/${NAME}-client.crt \
    <(echo -e '</cert>\n<key>') \
    "client_$NAME/pki/private/${NAME}-client.key" \
    <(echo -e '</key>\n<tls-auth>') \
    server/ta.key \
    <(echo -e '</tls-auth>') \
    >> "${NAME}-client.ovpn"
