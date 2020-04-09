#!/bin/bash

RASPAP_VOL=/opt/mistborn_volumes/raspap/etc-raspap
TMP_DIR=/tmp/mistborn-raspap

# install on gateway
sudo apt-get install -y hostapd vnstat

# install dhcp server on Ubuntu, Debian, etc. (just not Raspbian)
if [ ! "$DISTRO" == "raspbian" ]; then
    sudo apt-get install -y dhcpcd5
fi

sudo mkdir -p $RASPAP_VOL 
sudo mkdir -p $RASPAP_VOL/backups
sudo mkdir -p $RASPAP_VOL/networking
sudo mkdir -p $RASPAP_VOL/hostapd
#sudo mkdir -p $RASPAP_VOL/lighttpd

sudo cat /etc/dhcpcd.conf | sudo tee -a $RASPAP_VOL/networking/defaults > /dev/null

# copy files from raspap repo
sudo git clone https://github.com/sfoerster/raspap-webgui.git -b raspap_container $TMP_DIR
sudo cp $TMP_DIR/raspap.php $RASPAP_VOL

sudo mv $TMP_DIR/installers/*log.sh $RASPAP_VOL/hostapd
sudo mv $TMP_DIR/installers/service*.sh $RASPAP_VOL/hostapd
#sudo cp $TMP_DIR/installers/configport.sh $RASPAP_VOL/lighttpd

### System Service ###
#sudo mv $TMP_DIR/installers/raspapd.service /lib/systemd/system

sudo mv /etc/default/hostapd ~/default_hostapd.old
sudo cp /etc/hostapd/hostapd.conf ~/hostapd.conf.old

sudo cp $TMP_DIR/config/default_hostapd /etc/default/hostapd
sudo cp $TMP_DIR/config/hostapd.conf /etc/hostapd/hostapd.conf
sudo cp $TMP_DIR/config/dnsmasq.conf /etc/dnsmasq.d/090_raspap.conf
sudo cp $TMP_DIR/config/dhcpcd.conf /etc/dhcpcd.conf
#sudo cp config/config.php /var/www/html/includes/

# systemd-networkd
sudo systemctl stop systemd-networkd
sudo systemctl disable systemd-networkd
sudo cp $TMP_DIR/config/raspap-bridge-br0.netdev /etc/systemd/network/raspap-bridge-br0.netdev
sudo cp $TMP_DIR/config/raspap-br0-member-eth0.network /etc/systemd/network/raspap-br0-member-eth0.network 

# enable packet forwarding
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/90_raspap.conf > /dev/null
sudo sysctl -p /etc/sysctl.d/90_raspap.conf
sudo /etc/init.d/procps restart

## iptables
#sudo iptables -t nat -A POSTROUTING -j MASQUERADE
#sudo iptables -t nat -A POSTROUTING -s 192.168.50.0/24 ! -d 192.168.50.0/24 -j MASQUERADE
#sudo iptables-save | sudo tee /etc/iptables/rules.v4

# hostapd
sudo systemctl unmask hostapd.service
sudo systemctl enable hostapd.service
