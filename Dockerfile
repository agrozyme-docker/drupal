FROM agrozyme/php:7.2
COPY source /
ENV DRUPAL_VERSION=8.6.1

RUN set -euxo pipefail \
  && chmod +x /usr/local/bin/*.sh \
  && wget -O /var/www/drupal.tar.gz "https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz"

CMD ["agrozyme.drupal.command.sh"]
