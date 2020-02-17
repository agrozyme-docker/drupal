#!/bin/bash
set -euo pipefail

function cli_options() {
  local network=${DOCKER_NETWORK:-network}
  local user=$(id -u):$(id -g)

  local items
  declare -A items=(
    ['image']=agrozyme/drupal
    ['run']="docker run -it --rm -u=${user} --network=${network} -v ${PWD}:/var/www/html"
    ['command']="php -d memory_limit=-1 /usr/bin"
  )

  items=$(declare -p items)
  echo "${items#*=}"
}

function composer() {
  local items=$(cli_options)
  eval "declare -A items=${items}"

  local home=${COMPOSER_HOME:-${HOME}/.composer}
  local run="${items['run']} ${items['image']} ${items['command']}/composer"
  # local run="${items['run']} -v ${home}:/usr/local/lib/composer ${items['image']} ${items['command']}/composer"

  mkdir -p "${home}"
  ${run} "$@"
}

function drush() {
  local items=$(cli_options)
  eval "declare -A items=${items}"

  local run="${items['run']} ${items['image']} ${items['command']}/drush"

  ${run} "$@"
}

function drupal_check() {
  local items=$(cli_options)
  eval "declare -A items=${items}"

  local run="${items['run']} ${items['image']} ${items['command']}/drupal-check"

  ${run} "$@"
}

function drupal_console() {
  local items=$(cli_options)
  eval "declare -A items=${items}"

  local home=${HOME}/.console
  local run="${items['run']} -v ${home}:/home/core/.console ${items['image']} ${items['command']}/drupal"

  mkdir -p "${home}"
  ${run} "$@"
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
