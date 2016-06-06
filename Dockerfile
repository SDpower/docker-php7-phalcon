FROM phusion/baseimage:latest
MAINTAINER Steve Lo <info@sd.idv.tw>

# Default baseimage settings
ENV HOME /root
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh
CMD ["/sbin/my_init"]
ENV DEBIAN_FRONTEND noninteractive

# Update software list, install php-nginx & clear cache
RUN apt-get -qy update && apt-get -qy upgrade && locale-gen en_US.UTF-8 && export LANG=en_US.UTF-8 && \
	apt-get -qy install nano curl software-properties-common --fix-missing && \
	add-apt-repository -y ppa:nginx/stable && \
	add-apt-repository ppa:ondrej/php && \
	apt-get -qy update && apt-get -qy install git make re2c libpcre3-dev libmemcached-dev pkg-config nginx git zip --fix-missing && \
	apt-get -qy --force-yes install php7.0-fpm php7.0-curl php7.0-cli php7.0-common php7.0-json php7.0-opcache \
	php7.0-mysql php7.0-phpdbg php7.0-gd php7.0-imap php7.0-ldap php7.0-pgsql php7.0-pspell php7.0-recode \
	php7.0-mbstring php7.0-mcrypt php7.0-tidy php7.0-dev php7.0-intl php7.0-gd && \
	apt-get clean && \
    rm -rf /var/lib/apt/lists/* \
           /tmp/* \
           /var/tmp/*

RUN cd ~ && \
	git clone https://github.com/phalcon/zephir && \
	cd zephir && \
	./install -c

#Add more for php7 extension
ADD php7/mods-available/*.ini /etc/php/7.0/mods-available/
ADD php7/lib/*.so /usr/lib/php/20151012/
RUN phpenmod phalcon && phpenmod memcached && phpenmod redis

#ulimit tool
RUN touch /usr/bin/getulimit && \
	 chmod 777 /usr/bin/getulimit  && \
	 echo "#!/bin/bash" >> /usr/bin/getulimit && \
	 echo "ulimit -Ha" >> /usr/bin/getulimit


# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#ssh service (remove phusion restriction)
RUN rm -f /etc/service/sshd/down

# Configure nginx
RUN echo "daemon off;" >>                                               /etc/nginx/nginx.conf
RUN sed -i "s/sendfile on/sendfile off/"                                /etc/nginx/nginx.conf
RUN mkdir -p                                                            /var/www

# Configure PHP
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathi nfo=0/"                 /etc/php/7.0/fpm/php.ini
RUN sed -i "s/;date.timezone =.*/date.timezone = Asia\/Taipei/"         /etc/php/7.0/fpm/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g"                 /etc/php/7.0/fpm/php-fpm.conf
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/"                  /etc/php/7.0/cli/php.ini
RUN sed -i "s/;date.timezone =.*/date.timezone = Asia\/Taipei/"         /etc/php/7.0/cli/php.ini

# Add nginx service
RUN mkdir                                                               /etc/service/nginx
ADD build/nginx/run.sh                                                  /etc/service/nginx/run
RUN chmod +x                                                            /etc/service/nginx/run

# Add PHP service
RUN mkdir                                                               /etc/service/phpfpm
ADD build/php/run.sh                                                    /etc/service/phpfpm/run
RUN mkdir -p /run/php
RUN chmod +x                                                            /etc/service/phpfpm/run

# Add nginx
VOLUME ["/var/www", "/etc/nginx/sites-available", "/etc/nginx/sites-enabled"]

# Workdir
WORKDIR /var/www

EXPOSE 80
