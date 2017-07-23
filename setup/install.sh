#!/bin/bash

echo "Downloading GNS3 Source"
wget https://github.com/GNS3/gns3-gui/releases/download/v2.0.3/GNS3-2.0.3.source.zip
unzip GNS3-2.0.3.source.zip

# Build dynamips
echo "Preparing to build dynamips"
unzip dynamips-0.2.16.zip
cd dynamips-0.2.16/

echo "Installing dynamips build dependencies"
eopkg it -y -c system.devel
eopkg it -y cmake libelf-devel libpcap-devel elfutils-devel

echo "Building dynamips"
mkdir build && cd build
cmake .. && make install

cd ../../

# Build ubridge
echo "Preparing to build ubridge"
unzip ubridge-0.9.11.zip
cd ubridge-0.9.11

echo "Building ubridge"
make && make install

cd ../

# Build vpcs
echo "Preparing to build vpcs"
unzip vpcs-0.6.1.zip
cd vpcs-0.6.1/src

echo "Building vpcs"
./mk.sh

echo "\"Installing\" vpcs"
cp vpcs /usr/local/bin/vpcs

cd ../../

# Build gns3-server
echo "Preparing gns3-server"
unzip gns3-server-2.0.3.zip
cd gns3-server-2.0.3

echo "Installing gns3-server build dependencies"
eopkg it -y python3-devel
pip3 install --upgrade pip
pip3 install setuptools
pip3 install -r requirements.txt

echo "Building gns3-server"
python3 setup.py install

cd ../

# Build gns3-gui
echo "Preparing gns3-gui"
unzip gns3-gui-2.0.3.zip
cd gns3-gui-2.0.3

echo "Installing gns3-gui build dependencies"
eopkg it -y python3-qt5
echo "Building gns3-gui"
python3 setup.py install


# Set up Tap interface
echo "Setting up tap interface"
nmcli con add con-name tap0-con ifname tap0 type tun ipv4.address 172.16.99.1/24 ipv4.method manual tun.mode 2
nmcli -p con up tap0-con

echo "Enabling IP Forwarding"
# Make IP Forwarding persistant
echo "#Enable IP Forwarding on boot
net.ipv4.ip_forward=1" >> /usr/lib/sysctl.d/20-solus.conf

# Turn it on before reboot
echo 1 > /proc/sys/net/ipv4/ip_forward

echo "Enable NAT"
# Try to find the correct internet iface
DEFAULT_DEVICE=$(ip route | grep default | sed "s/.*dev \(.*\) proto .*/\1/" | head -n 1)
# Enable nat on that  interface
iptables -t nat -A POSTROUTING -o $DEFAULT_DEVICE -j MASQUERADE
# Save the rules to a file for persistance
iptables-save -c > /etc/iptables.rules

# Create a script to reload the rules on boot
# Source: https://help.ubuntu.com/community/IptablesHowTo
echo "Creating NAT reload script"
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

# Make the file exectuable
chmod +x /etc/NetworkManager/dispatcher.d/01firewall

