#!/usr/bin/env bash
#
#  nice-motd-rasp - Nice message of the day for Raspberry Pi
#  Author: Everaldo Canuto <everaldo.canuto@gmail.com>
#
#  The contents of this file is free and unencumbered software released into the
#  public domain. For more information, please refer to <http://unlicense.org/>

export TERM=xterm-256color

rst=$(tput sgr0)
grd=$(tput setaf 2 ; tput bold)
red=$(tput setaf 9 ; tput bold)
blu=$(tput setaf 4 ; tput bold)
whi=$(tput setaf 7 ; tput bold)

cpucount=$(cat /proc/cpuinfo | grep processor | wc -l)
cpuinfo=$(cat /proc/cpuinfo | grep 'model name' | uniq | cut -d: -f2 | xargs)
meminfo=$(free -h | grep 'Mem:' | tr -s ' ' | cut -d' ' -f2)

echo "${grd}    .~~.   .~~.     ${blu}    ___                __                      ___  _ "
echo "${grd}   '. \ ' ' / .'    ${blu}   / _ \___  ___ ___  / /  ___  ___ ___ _ __  / _ \(_)"
echo "${red}    .~ .~~~..~.     ${blu}  / , _/ _ '(_ </ _ \/ _ \/ -_) __/ __/ // / / ___/ / "
echo "${red}   : .~.'~'.~. :    ${blu} /_/|_|\_,_/___/ .__/_.__/\__/_/ /_/  \_, / /_/  /_/  "
echo "${red}  ~ (   ) (   ) ~   ${blu}              /_/                    /___/            "
echo "${red} ( : '~'.~.'~' : )  "
echo "${red}  ~ .~ (   ) ~. ~   ${whi} $(hostname)${whi} - ${blu}$(uptime -p)"
echo "${red}   (  : '~' :  )    ${rst} $(uname -srmo)"
echo "${red}    '~ .~~~. ~'     ${rst} ${cpucount} ${cpuinfo}, ${meminfo} RAM"
echo "${red}        '~'         ${rst}"
