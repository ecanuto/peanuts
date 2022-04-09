#!/usr/bin/env bash
#
#  nice-motd - Nice message of the day for Linux
#  Author: Everaldo Canuto <everaldo.canuto@gmail.com>
#
#  The contents of this file is free and unencumbered software released into the
#  public domain. For more information, please refer to <http://unlicense.org/>

set -e

rst=$(tput sgr0)
grd=$(tput setaf 2 ; tput bold)
red=$(tput setaf 9 ; tput bold)
blu=$(tput setaf 4 ; tput bold)
whi=$(tput setaf 7 ; tput bold)

distinfo=$(grep "^PRETTY_NAME" /etc/os-release | cut -d'"' -f2)
cpucount=$(cat /proc/cpuinfo | grep processor | wc -l)
cpuinfo=$(cat /proc/cpuinfo | grep 'model name' | uniq | cut -d: -f2 | xargs)
meminfo=$(free -h | grep 'Mem:' | tr -s ' ' | cut -d' ' -f2)

echo "${blu}$(figlet `hostname -s`)"
echo "${grd}${distinfo}"
echo "${rst}$(uname -srpo)"
echo "${rst}${cpucount} ${cpuinfo}, ${meminfo} RAM"
echo "${rst}$(uptime -p)"
echo "${rst}"
