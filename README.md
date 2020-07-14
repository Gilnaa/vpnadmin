# VPN Admin #
Scripts to automate creation of VPN configurations.

## Creating a server ##

Create an empty directory and `cd` into it.
Run:
```bash
/path/to/vpn/admin/genserver.sh SERVER_NAME SERVER_ADDRESS PORT VPN_SUBNET
```

Where:
    - SERVER_NAME: An arbitrary name for this VPN server
    - SERVER_ADDRESS: The external, non-VPN, address of the server. This address needs to be accessible for the clients to establish a connection.
    - PORT: The UDP port that the server will listen on.
    - VPN_SUBNET: The subnet to use for for addresses inside the VPN. The mask is hardcoded to `/24`.

For example:
```bash
/path/to/vpn/admin/genserver.sh foo vpn.example.com 1194 10.8.0.0
```

An ovpn file named `foo-server.ovpn` should be created in the current directory.

## Creating a client ##
`cd` into the server directory and run:
```bash
/path/to/vpn/admin/genclient.sh my_name
```

This will create a new configuration file named `my_name-client.ovpn`.