#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo '>>> Installing base dependencies'
sudo apt -y install libssl-dev apt-transport-https ca-certificates \
git wget chrony curl bash tar nano gnupg2 software-properties-common

echo '>>> Disable Swap'
sudo swapoff --all

echo '>>> Enable Kernel Modules'
sudo modprobe overlay
sudo modprobe br_netfilter

echo '>>> Configure Sysctl'
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

echo '>>> Reload Sysctl'
sudo sysctl --system

