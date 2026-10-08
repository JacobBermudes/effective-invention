#!/bin/bash
set -e

CONFIG_FILE="yggdrasil.conf"
ENV_FILE=".env"

echo "Checking and generating Yggdrasil configuration..."
if [ -s "$CONFIG_FILE" ]; then
    echo "File $CONFIG_FILE already exists. Skipping generation."
else
    docker run --rm --entrypoint yggdrasil ghcr.io/yggdrasil-network/yggdrasil-go:latest -genconf > "$CONFIG_FILE"
    echo "$CONFIG_FILE generated."
fi

echo "Configuring parameters for Exit Node..."
sed -i -E 's/^[#[:space:]]*IfName:.*/  IfName: "octojet0"/' "$CONFIG_FILE"
sed -i -E 's/^[#[:space:]]*AdminListen:.*/  AdminListen: "unix:\/\/\/var\/run\/yggdrasil\/admin.sock"/' "$CONFIG_FILE"
sed -i -E 's/^[#[:space:]]*NodeInfoPrivacy:.*/  NodeInfoPrivacy: false/' "$CONFIG_FILE"
sed -i -E '/^[[:space:]]*Peers:[[:space:]]*\[\]/c\  Peers: [\n    "tcp://185.135.81.71:9952"\n    "tcp://87.249.44.53:18226"\n    "tcp://185.45.62.109:12631"\n  ]' "$CONFIG_FILE"

echo "Extracting Yggdrasil IPv6 address..."
# Ask the binary to read the file and calculate the IP based on the key
YGG_IP=$(docker run --rm -v "$(pwd)/$CONFIG_FILE:/ygg.conf" --entrypoint yggdrasil ghcr.io/yggdrasil-network/yggdrasil-go:latest -useconffile /ygg.conf -address 2>/dev/null)

if [ -n "$YGG_IP" ]; then
    echo "YGG_IP=[$YGG_IP]" > "$ENV_FILE"

    echo ""
    echo "========================================================="
    echo "Configuration setup completed successfully!"
    echo -e "Your Yggdrasil IP: \e[32m$YGG_IP\e[0m"
    echo "Saved to .env file for SOCKS5 container binding."
    echo "========================================================="
else
    echo "Failed to extract Yggdrasil IP."
fi