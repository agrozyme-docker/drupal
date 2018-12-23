#!/bin/bash
set -euo pipefail

function create_project() {
  local html=${1:-.}
  local json="${html}/composer.json"

  composer.phar -n global require hirak/prestissimo

  if [[ -f "${json}" ]]; then
    return
  fi

  tar -C "${html}" -zxf "${html}/../drupal-project.tgz" --strip-components=1
  cp "${html}/../composer.json" "${json}"
  composer.phar -n update
}

function update_class_loader_auto_detect() {
  local file=${1:-}
  local switch=${DRUPAL_CLASS_LOADER_AUTO_DETECT:-}

  if [[ ! -f "${file}" ]]; then
    return
  fi

  if [[ "YES" == "${switch}" ]]; then
    sed -ri -e 's/^[\/#[:space:]]*(\$settings\[\x27class_loader_auto_detect\x27\])[[:space:]]*=[[:space:]]*(.*)$/# \1 = \2/' "${file}"
  else
    sed -ri -e 's/^[\/#[:space:]]*(\$settings\[\x27class_loader_auto_detect\x27\])[[:space:]]*=[[:space:]]*(.*)$/\1 = FALSE;/' "${file}"
  fi
}

function update_config_private_settings() {
  local file=${1:-}

  if [[ ! -f "${file}" ]]; then
    return
  fi

  sed -ri -e 's!^[\/#[:space:]]*(\$settings\[\x27file_private_path\x27\])[[:space:]]*=.*$!\1 = "sites/default/private";!' "${file}"
}

function update_config_sync_settings() {
  local file=${1:-}

  if [[ ! -f "${file}" ]]; then
    return
  fi

  sed -ri -e '/^[#[:space:]]*\$config_directories\[CONFIG_SYNC_DIRECTORY\][[:space:]]*=.*$/d' "${file}"
  sed -ri -e '$ a $config_directories[CONFIG_SYNC_DIRECTORY] = "config/default";' "${file}"
}

function update_reverse_proxy_settings() {
  local file=${1:-}
  local switch=${DRUPAL_REVERSE_PROXY:-}

  if [[ ! -f "${file}" ]] || [[ -z "${switch}" ]]; then
    return
  fi

  case "${switch}" in
  none)
    sed -ri \
      -e 's/^[\/#[:space:]]*(\$settings\[\x27reverse_proxy\x27\])[[:space:]]*=[[:space:]]*(.*)$/# \1 = \2/' \
      -e 's/^[\/#[:space:]]*(\$settings\[\x27reverse_proxy_addresses\x27\])[[:space:]]*=[[:space:]]*(.*)$/# \1 = \2/' \
      -e 's/^[\/#[:space:]]*(\$settings\[\x27reverse_proxy_header\x27\])[[:space:]]*=[[:space:]]*(.*)$/# \1 = \2/' \
      -e 's/^[\/#[:space:]]*(\$settings\[\x27reverse_proxy_proto_header\x27\])[[:space:]]*=[[:space:]]*(.*)$/# \1 = \2/' \
      -e 's/^[\/#[:space:]]*(\$settings\[\x27reverse_proxy_host_header\x27\])[[:space:]]*=[[:space:]]*(.*)$/# \1 = \2/' \
      -e 's/^[\/#[:space:]]*(\$settings\[\x27reverse_proxy_port_header\x27\])[[:space:]]*=[[:space:]]*(.*)$/# \1 = \2/' \
      -e 's/^[\/#[:space:]]*(\$settings\[\x27reverse_proxy_forwarded_header\x27\])[[:space:]]*=(.*)$/# \1 = \2/' \
      "${file}"
    ;;
  traefik)
    sed -ri \
      -e 's/^[\/#[:space:]]*(\$settings\[\x27reverse_proxy\x27\])[[:space:]]*=[[:space:]]*(.*)$/\1 = TRUE;/' \
      -e 's/^[\/#[:space:]]*(\$settings\[\x27reverse_proxy_addresses\x27\])[[:space:]]*=[[:space:]]*(.*)$/\1 = [$_SERVER["REMOTE_ADDR"]];/' \
      -e 's/^[\/#[:space:]]*(\$settings\[\x27reverse_proxy_header\x27\])[[:space:]]*=[[:space:]]*(.*)$/\1 = "x-real-ip";/' \
      -e 's/^[\/#[:space:]]*(\$settings\[\x27reverse_proxy_proto_header\x27\])[[:space:]]*=[[:space:]]*(.*)$/# \1 = \2/' \
      -e 's/^[\/#[:space:]]*(\$settings\[\x27reverse_proxy_host_header\x27\])[[:space:]]*=[[:space:]]*(.*)$/# \1 = \2/' \
      -e 's/^[\/#[:space:]]*(\$settings\[\x27reverse_proxy_port_header\x27\])[[:space:]]*=[[:space:]]*(.*)$/# \1 = \2/' \
      -e 's/^[\/#[:space:]]*(\$settings\[\x27reverse_proxy_forwarded_header\x27\])[[:space:]]*=[[:space:]]*(.*)$/# \1 = \2/' \
      "${file}"
    ;;
  *) ;;
  esac

}

function update_settings() {
  local file=${1:-}

  if [[ -z "${file}" ]]; then
    return
  fi

  if [[ -f "${file}" ]]; then
    update_class_loader_auto_detect "${file}"
    update_config_private_settings "${file}"
    update_config_sync_settings "${file}"
    update_reverse_proxy_settings "${file}"
  fi

  shift
  update_settings "$@"
}

function update_security() {
  local switch=${DRUPAL_SECURITY:-}
  local html=${1:-.}

  if [[ "YES" != "${switch}" ]]; then
    return
  fi

  local web="${html}/web"
  rm -f "${web}/robots.txt"
}

function update_composer() {
  local switch=${DRUPAL_COMPOSER_UPDATE:-}

  if [[ "YES" != "${switch}" ]]; then
    return
  fi

  composer.phar -n update
}

function main() {
  local html=/var/www/html
  local default="${html}/web/sites/default"

  create_project "${html}"
  mkdir -p "${default}/private"
  # update_settings "${default}/default.settings.php" "${default}/settings.php"
  update_security "${html}"
  update_composer
}

main "$@"
