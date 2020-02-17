#!/bin/bash

function main() {
  local source="$(readlink -f ${BASH_SOURCE[0]})"
  local path="$(dirname ${source})"
  local drupal="${path}/drupal.do.sh"

  alias profile="source ${source}"
  alias composer="${drupal} composer"
  alias drush="${drupal} drush"
  alias drupal="${drupal} drupal_console"
  alias drupal-check="${drupal} drupal_check"
}

main "$@"
