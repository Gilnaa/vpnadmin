#!/bin/bash

set -e

if [ $# -ne 4 ] ; then
	echo "Usage $0 <server-name> <server-address> <server-port> <vpn-subnet>"
	exit 1
fi

SCRIPT_ROOT=$(realpath $(dirname $0))
EASYRSA="$SCRIPT_ROOT/EasyRSA-3.0.4/easyrsa --use-algo=ec --curve=secp521r1 --batch "

NAME=$1
ADDR=$2
export PORT=$3
export SUBNET=$4

mkdir ca server
touch .vpn_admin

# Server
printf "\x1b[32m\x1b[1mServer\x1b[0m\n"
pushd server
$EASYRSA init-pki
$EASYRSA --req-cn="${NAME}-server" gen-req "${NAME}-server" nopass
$EASYRSA gen-dh
openvpn --genkey --secret ta.key
echo "$ADDR" > external_address
echo "$PORT" > external_port
popd

# CA
printf "\x1b[32m\x1b[1mCA\x1b[0m\n"
pushd ca
$EASYRSA init-pki
$EASYRSA --req-cn="${NAME}-ca" build-ca nopass

$EASYRSA import-req ../server/pki/reqs/"${NAME}-server.req" "${NAME}-server"
$EASYRSA --req-cn="${NAME}-server" sign-req server "${NAME}-server"
popd


printf "\x1b[32m\x1b[1mGenerating OpenVPN configurations\x1b[0m\n"

envsubst < ${SCRIPT_ROOT}/base-server.conf > ${NAME}-server.ovpn

cat <(echo -e '<ca>') \
    ca/pki/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    ca/pki/issued/${NAME}-server.crt \
    <(echo -e '</cert>\n<key>') \
    server/pki/private/${NAME}-server.key \
    <(echo -e '</key>\n<tls-auth>') \
    server/ta.key \
    <(echo -e '</tls-auth>\n<dh>') \
    server/pki/dh.pem \
    <(echo -e '</dh>') \
    >> ${NAME}-server.ovpn
