#!/bin/bash
set -euo pipefail

function cli_command() {
  local image="docker.io/agrozyme/drupal"
  local path="$(dirname $(readlink -f ${BASH_SOURCE[0]}))"
  local command="${path}/docker.do.sh run_command -v ${PWD}:/var/www/html $@ ${image} "
  echo "${command}"
}

function php() {
  local run="$(cli_command) php $@"
  ${run}
}

function composer() {
  local home="${COMPOSER_HOME:-${HOME}/.composer}"
  mkdir -p "${home}"

  local run="$(cli_command) composer $@"
  # local run="$(cli_command -v ${home}:/usr/local/lib/composer) composer $@"
  ${run}
}

function drush() {
  local run="$(cli_command) drush $@"
  ${run}
}

function drupal_check() {
  local run="$(cli_command) drupal-check $@"
  ${run}
}

function drupal_console() {
  local home="${HOME}/.console"
  mkdir -p "${home}"

  local run="$(cli_command -v ${home}:/home/core/.console) drupal $@"
  ${run}
}

function main() {
  local call=${1:-}

  if [[ -z $(typeset -F "${call}") ]]; then
    return
  fi

  shift
  ${call} "$@"
}

main "$@"
