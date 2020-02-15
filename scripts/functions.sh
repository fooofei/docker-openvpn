#!/bin/bash

function datef() {
    # Output:
    # Sat Jun  8 20:29:08 2019
    date "+%a %b %-d %T %Y"
}

function createConfig() {
    # Redirect stderr to the black hole
    /usr/share/easy-rsa/easyrsa build-client-full client nopass &> /dev/null
    # Writing new private key to '/usr/share/easy-rsa/pki/private/client.key
    # Client sertificate /usr/share/easy-rsa/pki/issued/client.crt
    # CA is by the path /usr/share/easy-rsa/pki/ca.crt

    CLIENT_ID="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
    CLIENT_PATH="clients/$CLIENT_ID"

    mkdir -p $CLIENT_PATH

    cp pki/private/client.key pki/issued/client.crt pki/ca.crt /etc/openvpn/ta.key $CLIENT_PATH

    # Set default value to HOST_ADDR if it was not set from environment
    if [ -z "$HOST_ADDR" ]
    then
        HOST_ADDR='localhost'
    fi

    cd $APP_INSTALL_PATH
    cp config/client.ovpn $CLIENT_PATH

    echo -e "\nremote $HOST_ADDR 1194" >> "$CLIENT_PATH/client.ovpn"

    # Embed client authentication files into config file
    cat <(echo -e '<ca>') \
        "$CLIENT_PATH/ca.crt" <(echo -e '</ca>\n<cert>') \
        "$CLIENT_PATH/client.crt" <(echo -e '</cert>\n<key>') \
        "$CLIENT_PATH/client.key" <(echo -e '</key>\n<tls-auth>') \
        "$CLIENT_PATH/ta.key" <(echo -e '</tls-auth>') \
        >> "$CLIENT_PATH/client.ovpn"

    echo $CLIENT_PATH
}

function zipFiles() {
    CLIENT_PATH="$1"
    # -q to silence zip output
    zip -q client.zip "$CLIENT_PATH/client.ovpn"
    cp client.zip "$CLIENT_PATH"

    echo "$(datef) $CLIENT_PATH/client.zip file has been generated"
}

function zipFilesWithPassword() {
    CLIENT_PATH="$1"
    ZIP_PASSWORD="$2"
    # -q to silence zip output
    zip -q -P "$ZIP_PASSWORD" client.zip "$CLIENT_PATH/client.ovpn"
    cp client.zip "$CLIENT_PATH"

    echo "$(datef) $CLIENT_PATH/client.zip with password protection has been generated"
}