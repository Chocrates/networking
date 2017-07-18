#!/bin/bash

wget https://github.com/GNS3/gns3-gui/releases/download/v2.0.3/GNS3-2.0.3.source.zip
unzip GNS3-2.0.3.source.zip

# Build dynamips
unzip dynamips-0.2.16.zip
cd dynamips-02.16/
eopkg it -c system.devel
eopkg it cmake libelf-devel libpcap-devel elfutils-devel

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

eopkg it python3-devel
pip3 install --upgrade pip
pip3 install setuptools
pip3 install -r requirements.txt
python3 setup.py install

cd ../

# Build gns3-gui
unzip gns3-gui-2.0.3.zip
cd gns3-gui-2.0.3

python3 setup.py install
