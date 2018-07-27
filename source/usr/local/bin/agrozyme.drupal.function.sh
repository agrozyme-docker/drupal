#!/bin/bash
set -euo pipefail

function main() {
  local reset=${DRUPAL_RESET:-}
  local version=8.5.5
  local command="tar xzf /var/www/drupal.tar.gz --strip-components=1 drupal-${version}/"

  if [[ -z "$(ls -A /var/www/html)" ]]; then
    tar xzf /var/www/drupal.tar.gz --strip-components=1 "drupal-${version}/"
    return
  fi

  if [[ "YES" == "${reset}" ]]; then
    tar xzf /var/www/drupal.tar.gz --strip-components=1 "drupal-${version}/" --exclude "drupal-${version}/composer.*"
    return
  fi
}

main "$@"
