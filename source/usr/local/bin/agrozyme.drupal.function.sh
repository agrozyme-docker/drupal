#!/bin/bash
set -euo pipefail

function extract_file() {
  local reset=${DRUPAL_RESET:-}
  local version=8.5.5
  local extract="tar xzf /var/www/drupal.tar.gz --strip-components=1 drupal-${version}/"
  
  if [[ -z "$(ls -A /var/www/html)" ]]; then
    ${extract}
    return
  fi
  
  if [[ "YES" == "${reset}" ]]; then
    ${extract} --exclude "drupal-${version}/composer.*"
    return
  fi
}

function security_fix() {
  local security=${DRUPAL_SECURITY:-}
  local html=/var/www/html
  
  if [[ "YES" != "${security}" ]]; then
    return
  fi
  
  rm -f "${html}/robots.txt"
  
  if [[ -e "${html}/config/sync/.htaccess" ]]; then
    cp "${html}/config/sync/.htaccess" "${html}/config/"
  fi
  
}

function update_setting() {
  local file=${1:-}
  
  if [[ -z "${file}" ]]; then
    return
  fi
  
  if [[ -e "${file}" ]]; then
    sed -ri \
    -e '/^[#[:space:]]*\$config_directories\[CONFIG_SYNC_DIRECTORY\][[:space:]]*=.*$/d' \
    -e '$ a $config_directories[CONFIG_SYNC_DIRECTORY] = "config/sync";' \
    "${file}"
  fi
  
  shift
  update_setting "$@"
}

function main() {
  local html=/var/www/html
  local default="${html}/sites/default"
  
  extract_file
  mkdir -p "${html}/config/sync"
  update_setting "${default}/default.settings.php" "${default}/settings.php"
  rm -rf "${default}/files/config_*/"
  security_fix
}

main "$@"
