FROM agrozyme/php:7.2
COPY source /

RUN set -euxo pipefail \
  && chmod +x /usr/local/bin/*.sh \
  && apk add --no-cache php7-session php7-tokenizer php7-curl php7-dom php7-gd php7-json php7-simplexml php7-xml $(apk search --no-cache -xq php7-pdo* | sort) \
  && wget -O /var/www/drupal.tar.gz https://ftp.drupal.org/files/projects/drupal-8.5.5.tar.gz

CMD ["agrozyme.drupal.command.sh"]
