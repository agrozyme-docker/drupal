#!/bin/bash
set -euo pipefail

function source_file() {
  echo "$(readlink -f ${BASH_SOURCE[0]})"
}

function source_path() {
  echo "$(dirname $(source_file))"
}

function setup_alias() {
  local run="$(source_file)"

  alias drush="${run} drush"
  alias drupal-check="${run} drupal_check"
  alias drupal="${run} drupal_console"
}

function cli_command() {
  local image="docker.io/agrozyme/drupal"
  local command="$(source_path)/docker.do.sh run_command -v ${PWD}:/var/www/html $@ ${image} "
  echo "${command}"
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
