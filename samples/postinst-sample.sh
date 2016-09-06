#!/usr/bin/env bash
source <(wget -qO- https://raw.github.com/ecanuto/peanuts/master/peanuts.sh)

check_for_root_privileges
check_for_system "debian"

info "General settings"
system_set_locale   "en_US.UTF-8" "pt_BR.UTF-8"
system_set_timezone "America/Sao_Paulo"

info "System upgrade"
system_sources "us"
system_upgrade
system_install ${ESSENTIAL_PACKAGES[@]} \
	bash-completion rsync htop mc wget curl vnstat git nginx

info "Setting some nice stuff like toilet motd"
system_goodstuff

info "Creating users"
system_add_user_group canuto adm,sudo,www-data
system_add_user       joedoe adm,sudo,www-data
system_add_user_key   joedoe "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAmk0sLUDMk4mTfB6MDRVmFNnZZnr+8LQQ7x27pfD7fGr/wqN8345iLoT01LSGIesZPVG2t6EiYf/K4yZSEqeumM0lVFG2RJcyE0hUAaL9jfwGbFFNBp+4kHQdwwsMtf8+63aecsGq+CObI1Khsg5fOBeJbPTapDR6dU6Mv2ZxKodOWm5Kzx6XKOgWtYA9rfnFPXdGxf1YsCu9qMZ+7S7LBlAnzX/x3ExFYmuUfZZ14ZMGv8cNJoRm7o0xIRo25eBF7ng4CO94HQ0uiZYLjPvxdClvXUCyu1KO8VVYM+S1s2EapYkFZcUnlVScmi7pKllDjOqfMHjSpT3AEJc2Apu3sw== joe@doe.com"
system_add_user       llbald adm,sudo,www-data
system_add_user_key   llbald "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEA3sRe1XufLeNpPO1//dMh0+jvJaMv23UoVL2RoKlHqwcrKeHhqmvwzq0K+1IDfkr/QUY/9SNK3GTDZKLfA35VhpDdjIZjaRvkGZCuVFW/oQ5FMPlpsbAnruxWok5Fb9Jzb4YNjzgPVp7HBPyvTcfAn4yRSwjyt4YIfkTTEiM3MT831WBUsad7VBsaBcH5+DORelAUwK5H5XtUoVAYWPv8avfnTRUuSQ04guOXMm2gTrSQJyIaowd7QGqaM0jilOZqLvuvPsxWPQUvkmzFPW/Hn5ebAd2RuYM5KhaeyfAGI5v4e1ENHnD0eSWYGCVxYEQiMTiWELDCSh4KkoLTt+yoIw== lex@lutor.com"

info "Installing cloud9 dependencies"
system_install nodejs nodejs-legacy npm build-essential
system_install -t jessie-backports tmux

info "Installing Nginx"
system_install nginx-extras
fset /etc/nginx/nginx.conf "\tserver_names_hash_bucket_size 128;"
fset /etc/nginx/nginx.conf "\tworker_connections 2048;"
echo "<center>$HOSTNAME</center>" > /var/www/html/index.html
systemctl restart nginx

info "Installing MySQL Server"
system_install mysql-server
mysql_secure_settings
mysql_create_database "wordpress" "wordpress" "wordpress"

info "PHP-FPM setup"
system_install \
	php5-cli php5-curl php5-fpm php5-gd php5-intl php5-mcrypt php5-mysql \
	php5-apcu

phpconf="/etc/php5/fpm/php.ini"
fset $phpconf "upload_max_filesize = 32M"
fset $phpconf "post_max_size = 32M"
fset $phpconf "short_open_tag = On"
fset $phpconf "date.timezone = $(cat /etc/timezone)"

wwwconf="/etc/php5/fpm/pool.d/www.conf"
fset $wwwconf "pm.status_path = /status"
fset $wwwconf "pm.max_children = 12"
fset $wwwconf "pm.max_spare_servers = 6"

systemctl restart php5-fpm

info "Finished!"
