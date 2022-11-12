#!/bin/bash


apt update
apt install -y git curl wget jq file tar unzip zip

cd /mnt/server
ARCH=$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")

# Restrict versions to latest pm3 and pm4 for now.
if [[ "${VERSION}" == "pm4" ]] || [[ "${VERSION}" == "" ]]; then
  DOWNLOAD_LINK=$(curl -ssL https://update.pmmp.io/api?channel=stable | grep 'download_url' | cut -d '"' -f 4)
  echo -e "Downloading latest PocketMine 4 from ${DOWNLOAD_LINK}"
  curl -ssL "${DOWNLOAD_LINK}" -o PocketMine-MP.phar
elif [[ "${VERSION}" == "pm3" ]]; then
  DOWNLOAD_LINK=$(curl -ssL https://update.pmmp.io/api?channel=pm3 | grep 'download_url' | cut -d '"' -f 4)
  echo -e "Downloading latest PocketMine 3 from ${DOWNLOAD_LINK}"
  curl -ssL "${DOWNLOAD_LINK}" -o PocketMine-MP.phar
else
  echo -e "Unknown version ${VERSION}"
  exit 1
fi



if [[ "${ARCH}" == "amd64" ]]; then
echo -e "\n downloading latest php build from PocketMine https://jenkins.pmmp.io/job/PHP-8.0-Aggregate/lastStableBuild/artifact/PHP-8.0-Linux-x86_64.tar.gz"
curl -sSL -o php.binary.tar.gz https://jenkins.pmmp.io/job/PHP-8.0-Aggregate/lastStableBuild/artifact/PHP-8.0-Linux-x86_64.tar.gz

echo -e "\n unpacking php binaries"
tar -xzvf php.binary.tar.gz

echo -e "\n removing php packages"
rm -rf /mnt/server/php.binary.tar.gz

echo -e "\n configuring PHP extensions library directory"
EXTENSION_DIR=$(find "bin" -name *debug-zts*)
grep -q '^extension_dir' bin/php7/bin/php.ini && sed -i'bak' "s{^extension_dir=.*{extension_dir=\"$EXTENSION_DIR\"{" bin/php7/bin/php.ini || echo "extension_dir=\"$EXTENSION_DIR\"" >>bin/php7/bin/php.ini
else
apt install -y libtool-bin libtool make autoconf automake m4 gzip bzip2 bison g++ git cmake pkg-config re2c

wget https://raw.githubusercontent.com/pmmp/php-build-scripts/stable/compile.sh -O compile.sh 
chmod +x compile.sh

echo "please wait, this will take some time"
./compile.sh
rm compile.sh
rm -rf install_data/

echo -e "\n configuring PHP extensions library directory"
EXTENSION_DIR=$(find "bin" -name *debug-zts*)
grep -q '^extension_dir' bin/php7/bin/php.ini && sed -i'bak' "s{^extension_dir=.*{extension_dir=\"$EXTENSION_DIR\"{" bin/php7/bin/php.ini || echo "extension_dir=\"$EXTENSION_DIR\"" >>bin/php7/bin/php.ini

fi


if [[ ! -f server.properties ]]; then
  echo -e "\n downloading default server.properties"
  curl -sSL https://raw.githubusercontent.com/NodeHosting24/eggs/main/minecraft/php/pmmp/server.properties >server.properties
fi


echo -e "\n creating files and folders"
touch banned-ips.txt banned-players.txt ops.txt white-list.txt server.log
mkdir -p players worlds plugins resource_packs

echo -e "\n\nInstall script completed. Enjoy!"
