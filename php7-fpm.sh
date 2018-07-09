
# copy /usr/local/vesta/data/templates/web/apache2/php7-fpm.sh
# chmod +x /usr/local/vesta/data/templates/web/apache2/php7-fpm.sh

user="$1"
domain="$2"
ip="$3"
home_dir="$4"
docroot="/home/$user/web/$domain/public_html"
WEB_BACKEND="php7.0-fpm"
template="php7-dynamic"
WEBTPL="/usr/local/vesta/data/templates/web/php7-fpm"

if [ -d "/etc/php-fpm.d" ]; then
        pool="/etc/php-fpm.d"
    fi
    if [ -d "/etc/php/7.0/fpm/" ]; then
        pool="/etc/php/7.0/fpm/pool.d"
    fi
    if [ ! -e "$pool" ]; then
        pool=$(find /etc/php* -type d \( -name "pool.d" -o -name "*fpm.d" \))
        if [ ! -e "$pool" ]; then
            check_result $E_NOTEXIST "php-fpm pool doesn't exist"
        fi
    fi

ubic="$pool/$domain.conf"
# Allocating backend port
if [ ! -e "$ubic" ]; then
#PHP-FPM 7 starts in 9000
backend_port=9000
ports=$(grep -v '^;' $pool/* 2>/dev/null |grep listen |grep -o :[0-9].*)
ports=$(echo "$ports" |sed "s/://" |sort -n)
for port in $ports; do
    if [ "$backend_port" -eq "$port" ]; then
        backend_port=$((backend_port + 1))
    fi
done
fi

if [ -e "$ubic" ]; then
ports=$(grep -v '^;' $pool/$2.conf 2>/dev/null |grep listen |grep -o :[0-9].*)
ports=$(echo "$ports" |sed "s/://" |sort -n)
backend_port=$ports
fi
# Adding backend config
cat $WEBTPL/$template.tpl |\
    sed -e "s|%backend_port%|$backend_port|" \
        -e "s|%user%|$1|g"\
        -e "s|%domain%|$2|"\
        -e "s|%docroot%|$docroot|"\
        -e "s|%backend%|$2|g" > $pool/$2.conf


sed -i -e "s/%backend_lsnr_cust%/127.0.0.1:$backend_port/g" /home/$user/conf/web/$domain.apache2.conf > /dev/null

sed -i -e "s/%backend_lsnr_cust%/127.0.0.1:$backend_port/g" /home/$user/conf/web/$domain.apache2.ssl.conf > /dev/null

systemctl restart $WEB_BACKEND > /dev/null
