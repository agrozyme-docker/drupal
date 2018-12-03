FROM agrozyme/composer:1.7
COPY source /
# ENV DRUPAL_VERSION=8.6.3

RUN set -euxo pipefail \
  && chmod +x /usr/local/bin/*.sh

CMD ["agrozyme.drupal.command.sh"]
