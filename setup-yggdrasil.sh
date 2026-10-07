#!/bin/bash
set -e

CONFIG_FILE="yggdrasil.conf"

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
# (Optional) Enable TunnelRouting for forwarding, if needed in your version of ygg
sed -i -E '/TunnelRouting: \{/,/\}/ s/^[#[:space:]]*Enable:.*/    Enable: true/' "$CONFIG_FILE"

echo "Extracting Yggdrasil IPv6 address..."
# Ask the binary to read the file and calculate the IP based on the key
YGG_IP=$(docker run --rm -v "$(pwd)/$CONFIG_FILE:/ygg.conf" --entrypoint yggdrasil ghcr.io/yggdrasil-network/yggdrasil-go:latest -useconffile /ygg.conf -address 2>/dev/null)

if [ -z "$YGG_IP" ]; then
    echo ""
    echo "========================================================="
    echo "Configuration setup completed successfully!"
    echo "Your Yggdrasil IP will be assigned to the octojet0 interface when the container starts."
    echo "You can view it using the command: ip -6 addr show octojet0"
    echo "========================================================="
else
    echo ""
    echo "========================================================="
    echo "Configuration setup completed successfully!"
    echo -e "Your Yggdrasil IP: \e[32m$YGG_IP\e[0m"
    echo "========================================================="
fi
