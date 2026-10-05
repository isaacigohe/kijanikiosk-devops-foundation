#!/bin/bash
# lets lxd containers get an ip inside wsl
sudo iptables -I FORWARD -i lxdbr0 -j ACCEPT
sudo iptables -I FORWARD -o lxdbr0 -j ACCEPT
sudo iptables -I INPUT -i lxdbr0 -p udp --dport 67 -j ACCEPT
