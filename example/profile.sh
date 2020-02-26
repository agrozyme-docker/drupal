#!/bin/bash

function main() {
  local source="$(readlink -f ${BASH_SOURCE[0]})"
  local path="$(dirname ${source})"
  local drupal_do="${path}/drupal.do.sh"

  sudo chmod +x "${path}"/*
  alias profile="source ${source}"

  alias php="${drupal_do} php"
  alias composer="${drupal_do} composer"
  alias drush="${drupal_do} drush"
  alias drupal="${drupal_do} drupal_console"
  alias drupal-check="${drupal_do} drupal_check"
}

main "$@"
