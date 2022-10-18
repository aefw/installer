#!/bin/bash

AESYS_USERNAME="siska"
AUTHORIZED_KEYS_URL="https://raw.githubusercontent.com/aefw/installer/main/aefw.user.pub"
CONFIG_PHP_INI_URL="https://raw.githubusercontent.com/aefw/installer/main/config.php.ini.php"

#
# BEGIN check only allow run without sudo or not root user
# but user can be access sudo command
#
if [ $(id -u) = 0 ]; then
	echo "[Error] The script don't run as root." >&2
	exit 1
fi
#echo "The login user is ${SUDO_USER:-$USER}"
#echo "The login user is ${SUDO_USER:-$(whoami)}"
sudo_response=$(SUDO_ASKPASS=/bin/false sudo -A whoami 2>&1 | wc -l)
if [ $sudo_response = 2 ]; then
	# Bisa sudo dengan prompt password
	can_sudo=1
	echo "This need access sudo"
	echo "[sudo] password for ${SUDO_USER:-$(whoami)}: "
	read -s sudopassword
elif [ $sudo_response = 1 ]; then
	# Bisa sudo dengan tanpa prompt password
	can_sudo=0
else
	echo "[Error] Unexpected sudo response: $sudo_response" >&2
	exit 1
fi
echo $sudopassword | sudo -S su
echo 
if ! [ $(sudo id -u) = 0 ]; then
	echo "[Error] The script can't run as root." >&2
	exit 1
fi
#
# END check
#


#
# BEGIN check only allow run in ubuntu
#
THIS_OS_NAME=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
if [[ $THIS_OS_NAME =~ "buntu" ]]; then
	THIS_OS_CODENAME=$(awk -F= '/^UBUNTU_CODENAME/{print $2}' /etc/os-release)
	echo "You are use the OS $THIS_OS_NAME $THIS_OS_CODENAME"
else
	echo "[Error] Please use Ubuntu server operating system"
	exit 1
fi
#
# END check
#


#
# BEGIN change source.list ubuntu
#
# [ -f "/etc/apt/sources.list.bk" ] && echo " " || sudo cp /etc/apt/sources.list /etc/apt/sources.list.bk
echo "
deb http://en.archive.ubuntu.com/ubuntu/ $THIS_OS_CODENAME main restricted
deb http://en.archive.ubuntu.com/ubuntu/ $THIS_OS_CODENAME-updates main restricted
deb http://en.archive.ubuntu.com/ubuntu/ $THIS_OS_CODENAME universe
deb http://en.archive.ubuntu.com/ubuntu/ $THIS_OS_CODENAME-updates universe
deb http://en.archive.ubuntu.com/ubuntu/ $THIS_OS_CODENAME multiverse
deb http://en.archive.ubuntu.com/ubuntu/ $THIS_OS_CODENAME-updates multiverse
deb http://en.archive.ubuntu.com/ubuntu/ $THIS_OS_CODENAME-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu $THIS_OS_CODENAME-security main restricted
deb http://security.ubuntu.com/ubuntu $THIS_OS_CODENAME-security universe
deb http://security.ubuntu.com/ubuntu $THIS_OS_CODENAME-security multiverse
" | sudo tee /etc/apt/sources.list.d/00-sources.list
#
# END change
#


sudo apt update
sudo apt upgrade -y


#
# BEGIN Configuration System
#
grep -q -F 'fs.inotify.max_user_watches' /etc/sysctl.d/99-sysctl.conf || \
	echo 'fs.inotify.max_user_watches = 1048576' | sudo tee /etc/sysctl.d/99-sysctl.conf
grep -q -F 'fs.inotify.max_user_instances' /etc/sysctl.d/99-sysctl.conf || \
	echo 'fs.inotify.max_user_instances = 256' | sudo tee /etc/sysctl.d/99-sysctl.conf
sudo sysctl fs.inotify.max_user_instances=256
sudo sysctl fs.inotify.max_user_watches=1048576
#
sudo apt install -y nano telnet tzdata -y
sudo timedatectl set-timezone 'Asia/Jakarta'
#
sudo apt install -y zip unzip wget gcc curl net-tools sendmail
sudo apt install -y git
# Command Do It
#command_install_php.txt
#sudo apt install -y python-software-properties # no need ubuntu minimal 20.04
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
#
apt-get purge php5.* && \
apt-get purge php7.* && \
apt-get purge php8.*

apt install php5.6 php5.6-fpm -y && \
apt install php7.4 php7.4-fpm -y && \
apt install php8.1 php8.1-fpm -y

#php*-mbstring # need for phpSpreadSheet & OJS & SLiMS
#php*-intl # need for phpscraper

apt install php5.6-mysql php5.6-cli php5.6-xml php5.6-curl php5.6-gd php5.6-json php5.6-soap php5.6-zip \
php5.6-mbstring -y  && \

apt install php7.4-mysql php7.4-cli php7.4-xml php7.4-curl php7.4-gd php7.4-json php7.4-soap php7.4-zip \
php7.4-mbstring \
php7.4-intl -y && \

apt install php8.1-mysql php8.1-cli php8.1-xml php8.1-curl php8.1-gd             php8.1-soap php8.1-zip \
php8.1-mbstring \
php8.1-intl -y && \

date

[ -d "/home/root/php" ] && echo "Dir PHP exist" || sudo cp -r /etc/php ~/
[ -f "/tmp/config.php.ini.php" ] && echo "config.php.ini.php" || sudo rm "/tmp/config.php.ini.php"
wget "$CONFIG_PHP_INI_URL" -O "/tmp/config.php.ini.php"
sudo php7.4 "/tmp/config.php.ini.php"
sudo systemctl restart php5.6-fpm
sudo systemctl restart php7.4-fpm
sudo systemctl restart php8.1-fpm

sudo mkdir -p     "/home/$AESYS_USERNAME/logs/apache2"
sudo mkdir -p     "/home/$AESYS_USERNAME/logs/nginx"
sudo chmod -R 777 "/home/$AESYS_USERNAME/logs"
sudo mkdir        "/home/$AESYS_USERNAME/tmp"
sudo chmod -R 777 "/home/$AESYS_USERNAME/tmp"


#
# END Configuration System
#

#
# BEGIN Clone Sistem
#
SUDOERS_CONF_FILE="/etc/sudoers.d/90-cloud-init-$AESYS_USERNAME"
if id -u "$AESYS_USERNAME" >/dev/null 2>&1; then
	echo "User $AESYS_USERNAME exists [skiped]"
else
	sudo adduser --disabled-password --gecos "" $AESYS_USERNAME
fi
[ -f "$SUDOERS_CONF_FILE" ] && echo "Sudoers exist [skiped]" || echo "$AESYS_USERNAME ALL=(ALL) NOPASSWD:ALL" | sudo tee "$SUDOERS_CONF_FILE"
[ -f "/home/$AESYS_USERNAME/.ssh" ] && echo "Dir .ssh exist [skiped]" || sudo mkdir "/home/$AESYS_USERNAME/.ssh"
sudo chmod 755 "/home/$AESYS_USERNAME"
sudo chmod -R 700 "/home/$AESYS_USERNAME/.ssh"
sudo chown -R "$AESYS_USERNAME":"$AESYS_USERNAME" "/home/$AESYS_USERNAME/.ssh"
[ -f "/home/$AESYS_USERNAME/.ssh/authorized_keys" ] && echo "Keyfile exist" || sudo rm "/home/$AESYS_USERNAME/.ssh/authorized_keys"
sudo wget "$AUTHORIZED_KEYS_URL" -O "/home/$AESYS_USERNAME/.ssh/authorized_keys"
sudo chmod -R 700 "/home/$AESYS_USERNAME/.ssh"
sudo chown -R "$AESYS_USERNAME":"$AESYS_USERNAME" "/home/$AESYS_USERNAME/.ssh"
#
# END Clone
#

