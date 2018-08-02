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
      -e 's/^[\/#[:space:]]*(\$settings\[\x27reverse_proxy_header\x27\])[[:space:]]*=[[:space:]]*(.*)$/\1 = "HTTP_X_REAL_IP";/' \
      -e 's/^[\/#[:space:]]*(\$settings\[\x27reverse_proxy_proto_header\x27\])[[:space:]]*=[[:space:]]*(.*)$/\1 = "HTTP_X_FORWARDED_PROTO";/' \
      -e 's/^[\/#[:space:]]*(\$settings\[\x27reverse_proxy_host_header\x27\])[[:space:]]*=[[:space:]]*(.*)$/\1 = "HTTP_X_FORWARDED_HOST";/' \
      -e 's/^[\/#[:space:]]*(\$settings\[\x27reverse_proxy_port_header\x27\])[[:space:]]*=[[:space:]]*(.*)$/\1 = "HTTP_X_FORWARDED_PORT";/' \
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
    sed -ri \
    -e '/^[#[:space:]]*\$config_directories\[CONFIG_SYNC_DIRECTORY\][[:space:]]*=.*$/d' \
    -e '$ a $config_directories[CONFIG_SYNC_DIRECTORY] = "config/sync";' \
    "${file}"
    
    update_reverse_proxy_settings "${file}"
  fi
  
  shift
  update_settings "$@"
}

function main() {
  local html=/var/www/html
  local default="${html}/sites/default"
  
  extract_file
  mkdir -p "${html}/config/sync"
  update_settings "${default}/default.settings.php" "${default}/settings.php"
  rm -rf "${default}/files/config_*/"
  security_fix
}

main "$@"
