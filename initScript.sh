#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run the script with sudo"
  exit 1
fi

echo "Changing sshd port 2222..."
sed -i -E 's/^#?Port .*/Port 2222/' /etc/ssh/sshd_config
if ! grep -q "^Port 2222" /etc/ssh/sshd_config; then
    echo "Port 2222" >> /etc/ssh/sshd_config
fi
systemctl restart sshd || systemctl restart ssh

echo "Setting up kernel routing..."
cat <<EOF > /etc/sysctl.d/99-yggdrasil-exit-node.conf
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
net.ipv6.ip_nonlocal_bind=1
EOF
sysctl --system

echo "Installing required kernel modules..."
cat <<EOF > /etc/modules-load.d/yggdrasil.conf
tun
nft_nat
nft_chain_nat
EOF
modprobe tun || true
modprobe nft_nat || true
modprobe nft_chain_nat || true

echo "Disabling other firewalls..."
for svc in ufw firewalld iptables; do
    systemctl stop $svc 2>/dev/null || true
    systemctl disable $svc 2>/dev/null || true
done

echo "5. Creating basic nftables framework..."
cat <<EOF > /etc/nftables.conf
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;

        ct state established,related accept

        iif "lo" accept

        tcp dport 2222 accept

        ip protocol icmp accept
        ip6 nexthdr icmpv6 accept

        iifname "octojet0" accept
    }

    chain forward {
        type filter hook forward priority 0; policy drop;
    }

    chain output {
        type filter hook output priority 0; policy accept;
    }
}

table ip nat {
    chain postrouting {
        type nat hook postrouting priority 100; policy accept;
    }
}

table ip6 nat {
    chain postrouting {
        type nat hook postrouting priority 100; policy accept;
    }
}
EOF

systemctl enable --now nftables
systemctl restart nftables

echo "Done! SSH uses 2222 port, nftables is enabled, kernel routing is enabled. Enjoy your exit node!"