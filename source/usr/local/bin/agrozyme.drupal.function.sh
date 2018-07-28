#!/bin/bash
set -euo pipefail

function extract_file() {
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

function update_setting() {
  local file=${1:-}
  
  if [[ -z "${file}" ]]; then
    return
  fi
  
  if [[ -e "${file}" ]]; then
    sed -ri \
    -e 's/^[#[:space:]]*($config_directories['sync'])[[:space:]]*=.*$//i' \
    -e 's!^$config_directories = array();$!a $config_directories['sync'] = 'config/sync'!i' \
    "${file}"
  fi
  
  shift
  update_setting "$@"
}

function main() {
  extract_file
  mkdir -p /var/www/html/config/sync
  update_setting /var/www/html/sites/default/default.settings.php /var/www/html/sites/default/settings.php
  rm -rf /var/www/html/sites/default/files/config_*/
}

main "$@"
