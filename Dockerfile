FROM agrozyme/php:7.3
COPY rootfs /
ENV \
  PHP_OPTIONS='-d memory_limit=-1'
RUN set +e -uxo pipefail && chmod +x /usr/local/bin/* && /usr/local/bin/docker-build.lua
WORKDIR /var/www/html
CMD ["/usr/local/bin/docker-run.lua"]
