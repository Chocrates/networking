#!/bin/bash

wget https://github.com/GNS3/gns3-gui/releases/download/v2.0.3/GNS3-2.0.3.source.zip
unzip GNS3-2.0.3.source.zip

# Build dynamips
unzip dynamips-0.2.16.zip
cd dynamips-02.16/
eopkg it -y -c system.devel
eopkg it -y cmake libelf-devel libpcap-devel elfutils-devel

mkdir build && cd build
make build && make install

cd ../../

# Build ubridge
unzip ubridge-0.9.11.zip
cd unzip ubridge-0.9.11A

make && make install

cd ../

# Build vpcs
unzip vpcs.-0.6.1.zipA
cd vpcs-0.6.1/src
./mk.sh

cp vpcs /usr/local/bin/vpcs

cd ../../

# Build gns3-server
unzip gns3-server-2.0.3.zip
cd gns3-server-2.0.3

eopkg it -y python3-devel
pip3 install --upgrade pip
pip3 install setuptools
pip3 install -r requirements.txt
python3 setup.py install

cd ../

# Build gns3-gui
unzip gns3-gui-2.0.3.zip
cd gns3-gui-2.0.3

eopkg it -y python3-qt
python3 setup.py install


# Set up Tap interface
nmcli con add con-name tap0-con ifname tap0 type tun ipv4.ad
dress 172.16.99.1/24 ipv4.method manual tun.mode 2
nmcli -p con up tap0-con

echo "#Enable IP Forwarding on boot
net.ipv4.ip_forward=1" >> /usr/lib/sysctl.d/20-solus.conf


DEFAULT_DEVICE=$(ip route | grep default | sed "s/.*dev \(.*\) proto .*/\1/" | head -n 1)


iptables -t nat -A POSTROUTING -o $DEFAULT_DEVICE -j MASQUERADE

iptables-save -c /etc/iptables.rules

echo "
if [ -x /usr/bin/logger ]; then
            LOGGER=\"/usr/bin/logger -s -p daemon.info -t FirewallHandler\"
        else
                    LOGGER=echo
                fi

                case \"$2\" in
                            up)
                                                if [ ! -r /etc/iptables.rules ]; then
                                                                            ${LOGGER} \"No iptables rules exist to restore.\"
                                                                                                    return
                                                                                                                    fi
                                                                                                                                    if [ ! -x /sbin/iptables-restore ]; then
                                                                                                                                                                ${LOGGER} \"No program exists to restore iptables rules.\"
                                                                                                                                                                                        return
                                                                                                                                                                                                        fi
                                                                                                                                                                                                                        ${LOGGER} \"Restoring iptables rules\"
                                                                                                                                                                                                                                        /sbin/iptables-restore -c < /etc/iptables.rules
                                                                                                                                                                                                                                                        ;;
                                                                                                                                                                                                                                                                down)
                                                                                                                                                                                                                                                                                    if [ ! -x /sbin/iptables-save ]; then
                                                                                                                                                                                                                                                                                                                ${LOGGER} \"No program exists to save iptables rules.\"
                                                                                                                                                                                                                                                                                                                                        return
                                                                                                                                                                                                                                                                                                                                                        fi
                                                                                                                                                                                                                                                                                                                                                                        ${LOGGER} \"Saving iptables rules.\"
                                                                                                                                                                                                                                                                                                                                                                                        /sbin/iptables-save -c > /etc/iptables.rules
                                                                                                                                                                                                                                                                                                                                                                                                        ;;
                                                                                                                                                                                                                                                                                                                                                                                                                *)
                                                                                                                                                                                                                                                                                                                                                                                                                                    ;;
                                                                                                                                                                                                                                                                                                                                                                                                                            esac" > /etc/NetworkManager/dispatcher.d/01firewall

chmod +x /etc/NetworkManager/dispatcher.d/01firewall

