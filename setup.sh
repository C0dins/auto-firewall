#!/bin/bash


# exit with error status code if user is not root
if [[ $EUID -ne 0 ]]; then
  echo "* This script must be executed with root privileges (sudo)." 1>&2
  exit 1
fi

# check for curl
if ! [ -x "$(command -v curl)" ]; then
  echo "* curl is required in order for this script to work."
  echo "* install using apt (Debian and derivatives) or yum/dnf (CentOS)"
  exit 1
fi

output() {
  echo -e "* ${1}"
}

output "Setting up Incoming ping requests"
output
iptables -I INPUT -p icmp --icmp-type echo-request -j REJECT
output "Setting up outgoing ping requests"
output
iptables -A INPUT -pr icmp -i eth0 -j DROP
iptables -A OUTPUT -p icmp --icmp-type echo-request -j REJECT
output "Limiting Apache Requests"
output
iptables -A INPUT -p tcp --dport 80 -m limit --limit 100/minute --limit-burst 300 -j ACCEPT
output "Making sure localnetwork is always allowed"
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
output
output "Done Setting up Iptables now restarting iptables to make sure our new rules work."
/sbin/iptables-save
output

output "Starting to install fail2ban"

output 

sudo apt install fail2ban

cat << EOF | sudo tee /etc/fail2ban/jail.d/ssh.local
[sshd]
enabled = true
banaction = ufw
port = ssh
filter = sshd
logpath = %(sshd_log)s
maxretry = 5
EOF

output "Done setting up Fail2Ban"
