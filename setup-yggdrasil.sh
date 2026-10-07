#!/bin/bash
set -e

CONFIG_FILE="yggdrasil.conf"

echo "Check and generate Yggdrasil configuration..."
if [ -f "$CONFIG_FILE" ]; then
    echo "File $CONFIG_FILE already exists. Skipping generation to preserve keys and IP address."
else
    docker run --rm yggdrasilnetwork/yggdrasil-go:latest -genconf > "$CONFIG_FILE"
    echo "$CONFIG_FILE generated."
fi

echo "2. Configuring parameters for Exit Node..."

sed -i -E 's/^[#[:space:]]*IfName:.*/  IfName: "octojet0"/' "$CONFIG_FILE"

sed -i -E 's/^[#[:space:]]*AdminListen:.*/  AdminListen: "unix:\/\/\/var\/run\/yggdrasil\/admin.sock"/' "$CONFIG_FILE"

sed -i -E 's/^[#[:space:]]*NodeInfoPrivacy:.*/  NodeInfoPrivacy: false/' "$CONFIG_FILE"

# (Optional) Enable TunnelRouting for forwarding, if needed in your version of ygg
sed -i -E '/TunnelRouting: \{/,/\}/ s/^[#[:space:]]*Enable:.*/    Enable: true/' "$CONFIG_FILE"

echo "3. Extracting Yggdrasil IPv6 address..."
YGG_IP=$(grep -i "IPv6 address:" "$CONFIG_FILE" | awk '{print $NF}')

if [ -z "$YGG_IP" ]; then
    echo "Failed to automatically parse IP from file $CONFIG_FILE"
else
    echo ""
    echo "========================================================="
    echo "Setup completed successfully!"
    echo -e "IP address of your Yggdrasil Exit Node: \e[32m$YGG_IP\e[0m"
    echo "This address you will use in the Go-sidecar (listen address)"
    echo "and in the clients (as default route / exit node)."
    echo "========================================================="
fi
