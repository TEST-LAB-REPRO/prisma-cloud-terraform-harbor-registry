#!/bin/bash

#Harbor on Ubuntu 20.04

# Housekeeping
apt update -y
swapoff --all
sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab

echo "Housekeeping done"


#Install Latest Stable Docker Release
apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

MAINUSER=$(logname)
usermod -aG docker $MAINUSER
systemctl enable --now docker

echo "Docker Installation done"

#Install Latest Stable Docker Compose Release
VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*\d')
curl -L "https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
echo "Docker Compose Installation done"

#Create self certificates

openssl genrsa -out ca.key 4096

openssl req -x509 -new -nodes -sha512 -days 3650  -subj "/C=ES/ST=Madrid/L=Madrid/O=example/OU=Personal/CN=example.com"  -key ca.key  -out ca.crt

openssl genrsa -out example.com.key 4096

openssl req -sha512 -new  -subj "/C=ES/ST=Madrid/L=Madrid/O=example/OU=Personal/CN=example.com"  -key example.com.key -out example.com.csr

export server_name=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
export private_ip=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/ip)


cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=sslip.io
DNS.2=sslip
DNS.3=$server_name.sslip.io
IP.1=$server_name
IP.2=$private_ip
EOF

openssl x509 -req -sha512 -days 3650 -extfile v3.ext -CA ca.crt -CAkey ca.key -CAcreateserial -in example.com.csr -out example.com.crt

#Provide Certificates to Harbor and Docker
mkdir -p /data/cert
cp example.com.crt /data/cert
cp example.com.key /data/cert

openssl x509 -inform PEM -in example.com.crt -out example.com.cert

mkdir -p /etc/docker/certs.d/${server_name}.sslip.io

cp example.com.cert /etc/docker/certs.d/${server_name}.sslip.io
cp example.com.key /etc/docker/certs.d/${server_name}.sslip.io
cp ca.crt /etc/docker/certs.d/${server_name}.sslip.io

systemctl restart docker
echo "Configuring HTTPS access done"


#Install Latest Stable Harbor Release
HARBORVERSION=$(curl -s https://api.github.com/repos/goharbor/harbor/releases/latest| grep -Po '"tag_name": "\K.*\d')
curl -s https://api.github.com/repos/goharbor/harbor/releases/latest | grep browser_download_url | grep online | cut -d '"' -f 4 | wget -qi -
tar xvf harbor-online-installer-${HARBORVERSION}.tgz
cd harbor
cp harbor.yml.tmpl harbor.yml
sed -i "s/reg.mydomain.com/${server_name}.sslip.io/g" harbor.yml
sed -i "s/\/your\/certificate\/path/\/data\/cert\/example.com.crt/g" harbor.yml
sed -i "s/\/your\/private\/key\/path/\/data\/cert\/example.com.key/g" harbor.yml
/private/key

./prepare
./install.sh

echo -e "Harbor Installation Complete \n\nPlease log out and log in or run the command 'newgrp docker' to use Docker without sudo\n\nLogin to your harbor instance  https://${server_name}.sslip.io"