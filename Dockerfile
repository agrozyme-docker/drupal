FROM agrozyme/php:7.3
COPY rootfs /
ENV \
  PHP_OPTIONS='-d memory_limit=-1' \
  DRUSH_INI='/etc/php7/docker/00_php-cli.ini'
RUN set +e -uxo pipefail && chmod +x /usr/local/bin/* && /usr/local/bin/docker-build.lua
WORKDIR /var/www/html
CMD ["/usr/local/bin/docker-run.lua"]
