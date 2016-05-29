#!/usr/bin/env bash
#
# Peanuts Bash Library
# Copyright (c) 2016 Everaldo Canuto <everaldo.canuto@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

### Global settings ############################################################

set -e
export DEBIAN_FRONTEND=noninteractive

### System constants ###########################################################

ESSENTIAL_PACKAGES=(sudo openssh-server ufw nano)
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
	sed -n -e "s|^ *$argc[ =]*\(.*\) *|\1|p" $file
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
	sed -i "s/# *$2/$2/" /etc/locale.gen
	locale-gen
}

function system_set_hostname {
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

function system_upgrade {
	apt-get update
	apt-get upgrade --yes
	apt-get autoremove --yes --purge
	apt-get clean
}

function system_install() {
	apt-get install --yes $@
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

function mysql_create_database() {
	mysql -u root -e "CREATE DATABASE IF NOT EXISTS $1 CHARACTER SET utf8"
	if [ ! -z "$2" ]; then
		mysql -u root -e "GRANT ALL PRIVILEGES ON $1.* TO '$2'@'localhost' IDENTIFIED BY '$3'"
		mysql -u root -e "GRANT ALL PRIVILEGES ON $1.* TO '$2'@'127.0.0.1' IDENTIFIED BY '$3'"
		mysql -u root -e "FLUSH PRIVILEGES"
	fi
}
