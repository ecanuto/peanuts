#!/usr/bin/env bash
#
#  Peanuts Bash Library
#  Author: Everaldo Canuto <everaldo.canuto@gmail.com>
#
#  This is free and unencumbered software released into the public domain.
#
#  Anyone is free to copy, modify, publish, use, compile,  sell,  or  distribute
#  this software, either in source code form or as a compiled  binary,  for  any
#  purpose, commercial or non-commercial, and by any means.
#
#  In jurisdictions that recognize copyright laws, the author or authors of this
#  software dedicate any and all copyright  interest  in  the  software  to  the
#  public domain. We make this dedication for the benefit of the public at large
#  and to the detriment of our heirs and successors. We intend  this  dedication
#  to be an overt act of relinquishment in perpetuity of all present and  future
#  rights to this software under copyright law.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY  KIND,  EXPRESS  OR
#  IMPLIED, INCLUDING BUT NOT LIMITED  TO  THE  WARRANTIES  OF  MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT  SHALL  THE
#  AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,  WHETHER  IN  AN
#  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN  CONNECTION
#  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

### Global settings ############################################################

set -e
export DEBIAN_FRONTEND=noninteractive

### System constants ###########################################################

ESSENTIAL_PACKAGES=(sudo openssh-server ufw nano lsb-release)
SSHD_CONFIG="/etc/ssh/sshd_config"

### Utilities ##################################################################

function info() {
	bold=$(tput bold)
	norm=$(tput sgr0)
	printf "${bold}--> ${1}${norm}\n"
}

function fset() {
	file=$1
	argc=$2
	sepc=$(echo -e $argc | sed -n -e "s/.*\(=\).*/\1/p")
	name=$(echo -e $argc | cut -f 1 -d " " | sed "s/^[ \t]*//")
	if [ ! -f "$file.orig" ]; then
	    cp "$file" "$file.orig"
	fi
	sed -i -e "s|^[ \t#;]*$name[ ]\+$sepc.\+|$argc|" $file
}

function fget() {
	file=$1
	argc=$2
	sed -n -e "s|^ *$argc[ =]\+\(.*\) *|\1|p" $file
}

function check_for_root_privileges() {
	if [[ $EUID -ne 0 ]]; then
		echo "This script must be run as root" 1>&2
		exit 1
	fi
}

function check_for_system() {
	system=$(fget /etc/os-release ID)
	if [[ "$system" != "$1" ]]; then
		echo "This script must be run on $1 systems" 1>&2
		exit 1
	fi
}

function common_system_checks() {
	check_for_root_privileges
	check_for_system "$1"
}

function urlretrieve() {
	rurl=$1; file=$2; attr=$3
	wget -O $file $rurl
	chmod $attr $file
}

### System #####################################################################

function system_set_timezone() {
	echo "$1" > /etc/timezone
	dpkg-reconfigure --frontend noninteractive tzdata
}

function system_set_locale() {
	echo "LANG=$1" > /etc/default/locale
	sed -i "s/# *$1/$1/" /etc/locale.gen
	sed -i "s/# *$2/$2/" /etc/locale.gen
	locale-gen
}

function system_set_hostname() {
    HOSTNAME="$1"
    echo "$HOSTNAME" > /etc/hostname
    hostname -F /etc/hostname
}

function system_set_swapfile() {
	SWAPFILE=$1
	SWAPSIZE=$2
	if [ ! -f "$SWAPFILE" ]; then
		dd if=/dev/zero of=$SWAPFILE bs=1024 count=${SWAPSIZE}
		chmod 0600 $SWAPFILE
		mkswap $SWAPFILE
		swapon $SWAPFILE
		cat >> /etc/fstab <<-EOF
			$SWAPFILE       none    swap    sw      0       0
		EOF
	fi
}

function system_backup_file() {
	if [ ! -f "$1.orig" ]; then
		cp "$1" "$1.orig"
	fi
}

function system_sources() {
	mirr="${1:-us}"
	comp="${2:-main contrib non-free}"
	name=$(dpkg --status tzdata | grep Provides | cut -f2 -d '-')
	file="/etc/apt/sources.list"

    system_backup_file $file
	if  [ ! -s /dev/stdin ]; then
		cat > $file <<-EOF
			deb http://ftp.$mirr.debian.org/debian $name main contrib non-free
			deb http://ftp.$mirr.debian.org/debian/ $name-updates main contrib non-free
			deb http://ftp.$mirr.debian.org/debian $name-backports main contrib non-free
			deb http://security.debian.org/ $name/updates main contrib non-free
		EOF
	else
		cat /dev/stdin > $file
	fi
}

function system_update() {
	apt-get update
}

function system_upgrade() {
	apt-get update
	apt-get upgrade --yes
	apt-get autoremove --yes --purge
	apt-get clean
}

function system_install() {
	apt-get install --yes $@
}

function system_goodstuff() {
	if [ ! $(which toilet) ] || [ ! $(which figlet) ]; then
		system_install toilet figlet
	fi

	info "Setting message of the day"
	system_backup_file /etc/motd
	toilet -f standard --metal "`hostname -s`"   > /etc/motd
	toilet -f term --metal "$(lsb_release -sd)" >> /etc/motd
}

function system_add_user() {
	USERNAME="$1"
	USERHOME="/home/$USERNAME"
	USGROUPS="$2"
	if [ ! -d "$USERHOME" ]; then
		adduser --disabled-password --gecos "" $USERNAME
		if [ ! -z "$USGROUPS" ]; then
			usermod -a -G $USGROUPS $USERNAME
		fi
		usermod -p "" $USERNAME
		chage -d 0 $USERNAME
	fi
}

function system_add_user_group() {
	usermod -G $2 $1
}

function system_add_user_key() {
	USERNAME="$1"
	USERKEYS="$2"
	if [ $1 = "root" ]; then
		USERHOME="/$USERNAME"
	else
		USERHOME="/home/$USERNAME"
	fi
	mkdir -p $USERHOME/.ssh
	cat > $USERHOME/.ssh/authorized_keys <<-EOF
		$USERKEYS
	EOF
	chmod 700 $USERHOME/.ssh
	chmod 600 $USERHOME/.ssh/authorized_keys
	chown -R $USERNAME:$USERNAME $USERHOME/.ssh
}

### MySQL ######################################################################

function mysql_secure_settings() {
	# remove anonymous users
	mysql -u root -e "DELETE FROM mysql.user WHERE user=''"
	# disallow root login remotely
	mysql -u root -e "DELETE FROM mysql.user WHERE user='root' AND host NOT IN ('127.0.0.1', 'localhost', '::1');"
	# remove 'test' database
	mysql -u root -e "DROP DATABASE IF EXISTS test"
	# reload privilege tables
	mysql -u root -e "FLUSH PRIVILEGES"
}

function mysql_common_settings() {
	mysql_secure_settings
	mysql -u root -e "UPDATE mysql.user SET plugin='mysql_native_password' WHERE User='root'"
	mysql -u root -e "FLUSH PRIVILEGES"
}

function mysql_create_database() {
	mysql -u root -e "CREATE DATABASE IF NOT EXISTS $1 CHARACTER SET utf8"
	if [ ! -z "$2" ]; then
		mysql -u root -e "GRANT ALL PRIVILEGES ON $1.* TO '$2'@'localhost' IDENTIFIED BY '$3'"
		mysql -u root -e "GRANT ALL PRIVILEGES ON $1.* TO '$2'@'127.0.0.1' IDENTIFIED BY '$3'"
		mysql -u root -e "FLUSH PRIVILEGES"
	fi
}
