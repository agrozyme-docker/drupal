#!/bin/bash
set -eux

function download_drush() {
  local prefix=${1:-}
  local bin="${prefix}/usr/local/bin"
  local target="${bin}/drush"

  if [[ ! -f "${target}" ]]; then
    local version="8.3.2"
    wget -qO "${target}" "https://github.com/drush-ops/drush/releases/download/${version}/drush.phar"
    # local version=$(curl -s https://api.github.com/repos/drush-ops/drush-launcher/releases/latest | jq -r '.tag_name')
    # wget -qO "${target}" "https://github.com/drush-ops/drush-launcher/releases/download/${version}/drush.phar"
  fi
}

function download_drupal_check() {
  local prefix=${1:-}
  local bin="${prefix}/usr/local/bin"
  local target="${bin}/drupal-check"

  if [[ ! -f "${target}" ]]; then
    local version=$(curl -s https://api.github.com/repos/mglaman/drupal-check/releases/latest | jq -r '.tag_name')
    wget -qO "${target}" "https://github.com/mglaman/drupal-check/releases/download/${version}/drupal-check.phar"
  fi
}

function download_drupal_console() {
  local prefix=${1:-}
  local bin="${prefix}/usr/local/bin"
  local target="${bin}/drupal"

  if [[ ! -f "${target}" ]]; then
    # local version=$(curl -s https://api.github.com/repos/hechoendrupal/drupal-console-launcher/releases/latest | jq -r '.tag_name')
    # wget -qO "${target}" "https://github.com/hechoendrupal/drupal-console-launcher/releases/download/${version}/drupal.phar"
    wget -qO "${target}" "https://drupalconsole.com/installer"
  fi
}

function setup() {
  local prefix=${1:-}
  download_drush "${prefix}"
  download_drupal_check "${prefix}"
  download_drupal_console "${prefix}"
}

function main() {
  local call="${1:-}"

  if [[ -z $(typeset -F "${call}") ]]; then
    return
  fi

  shift
  ${call} "$@"
}

main "$@"
