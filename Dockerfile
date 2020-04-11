FROM docker.io/agrozyme/php
COPY rootfs /
RUN set +e -ux && chmod +x /usr/local/bin/* && /usr/local/bin/docker-build.lua
WORKDIR /var/www/html
CMD ["/usr/local/bin/docker-run.lua"]
