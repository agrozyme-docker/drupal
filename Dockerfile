FROM agrozyme/composer:1.8
COPY source /

RUN set -euxo pipefail \
  && chmod +x /usr/local/bin/*.sh

CMD ["agrozyme.drupal.command.sh"]
