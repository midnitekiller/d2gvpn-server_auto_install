#!/bin/bash

apt-get update
apt-get install openvpn easy-rsa
gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz > /etc/openvpn/server.conf\

sed -i 's/dh dh1024.pem/dh dh2048.pem/g'  /home/openvpn-bak/server.conf
sed -i 's/;push "redirect-gateway def1 bypass-dhcp"/push "redirect-gateway def1 bypass-dhcp"/g' /home/openvpn-bak/server.conf
sed -i 's/;push "dhcp-option DNS 208.67.222.222"/push "dhcp-option DNS 208.67.222.222"/g' /home/openvpn-bak/server.conf
sed -i 's/;push "dhcp-option DNS 208.67.220.220"/push "dhcp-option DNS 208.67.220.220"/g' /home/openvpn-bak/server.conf
sed -i 's/;user nobody/user nobody/g'  /home/openvpn-bak/server.conf
sed -i 's/;group nogroup/group nogroup/g'  /home/openvpn-bak/server.conf

echo 1 > /proc/sys/net/ipv4/ip_forward

sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g'  /etc/sysctl.conf

ufw allow ssh
ufw allow 1194/udp

ed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/g' /etc/default/ufw

echo "# START OPENVPN RULES" >> test.conf
echo "# NAT table rules" >> test.conf
echo "*nat" >> test.conf
echo ":POSTROUTING ACCEPT [0:0]" >> test.conf
echo "# Allow traffic from OpenVPN client to eth0" >> test.conf
echo "-A POSTROUTING -s 10.8.0.0/8 -o eth0 -j MASQUERADE" >> test.conf
echo "COMMIT" >> test.conf
echo "# END OPENVPN RULES" >> test.conf

ufw enable

cp -r /usr/share/easy-rsa/ /etc/openvpn

mkdir /etc/openvpn/easy-rsa/keys


sed -i 's/export KEY_COUNTRY="US"/export KEY_COUNTRY="PH"/g /etc/openvpn/easy-rsa/vars
sed -i 's/export KEY_PROVINCE="TX"/export KEY_PROVINCE="CEBU"/g /etc/openvpn/easy-rsa/vars
sed -i 's/export KEY_CITY="Dallas"/export KEY_CITY="Cebu City"/g /etc/openvpn/easy-rsa/vars
sed -i 's/export KEY_ORG="My Company Name"/export KEY_ORG="Direct2Guests"/g /etc/openvpn/easy-rsa/vars
sed -i 's/export KEY_EMAIL="sammy@example.com"/export KEY_EMAIL="liefjill@direct2guests.com"/g /etc/openvpn/easy-rsa/vars
sed -i 's/export KEY_OU="MYOrganizationalUnit"/export KEY_OU="D2GUnit"/g /etc/openvpn/easy-rsa/vars

export KEY_NAME="server"

openssl dhparam -out /etc/openvpn/dh2048.pem 2048

cd /etc/openvpn/easy-rsa
. ./vars
./clean-all
./build-ca
./build-key-server server

cp /etc/openvpn/easy-rsa/keys/{server.crt,server.key,ca.crt} /etc/openvpn
service openvpn start
service openvpn status