#!/bin/bash
set -euo pipefail

function extract_file() {
  local reset=${DRUPAL_RESET:-}
  local version=${DRUPAL_VERSION}
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

function create_project() {
  local composer=${1:-}
  local html=${2:-.}

  ${composer} -n global require hirak/prestissimo

  if [[ ! -f "${html}/composer.json" ]]; then
    ${composer} -n create-project drupal-composer/drupal-project:8.x-dev "${html}"
    return
  fi
}

function make_gitignore() {
  local html=/var/www/html
  local ignore="${html}"/.gitignore
  
  if [[ -f "${ignore}" ]]; then
    return
  fi
  
  cp "${html}"/example.gitignore "${ignore}"
}

function update_class_loader_auto_detect() {
  local file=${1:-}
  local detect=${DRUPAL_CLASS_LOADER_AUTO_DETECT:-}
  
  if [[ ! -f "${file}" ]]; then
    return
  fi
  
  if [[ "YES" == "${detect}" ]]; then
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
  local reverse_proxy=${DRUPAL_REVERSE_PROXY:-}
  
  if [[ ! -f "${file}" ]] || [[ -z "${reverse_proxy}" ]]; then
    return
  fi
  
  case "${reverse_proxy}" in
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
    *)
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
  local security=${DRUPAL_SECURITY:-}
  local html=${1:-.}
  local web="${html}/web"
  local htaccess="${html}/vendor/.htaccess"
  
  if [[ "YES" != "${security}" ]]; then
    return
  fi
  
  rm -f "${web}/robots.txt"
  
  if [[ -e "${htaccess}" ]]; then
    cp "${htaccess}" "${web}/config/"
  fi
}

function composer_update() {
  local composer=${1:-}
  ${composer} -n update drupal/core webflo/drupal-core-require-dev symfony/* --with-dependencies
  ${composer} -n update
}

function main() {
  local html=/var/www/html
  local web="${html}/web"
  local default="${web}/sites/default"
  local composer=/usr/local/bin/composer.phar

  create_project "${composer}" "${html}"
  rm -rf "${default}/files/config_*/"
  mkdir -p "${web}/config/default" "${default}/private"
  update_settings "${default}/default.settings.php" "${default}/settings.php"
  update_security "${html}"
  composer_update "${composer}"
}

main "$@"
