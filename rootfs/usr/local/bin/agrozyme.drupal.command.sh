#!/bin/bash
set -euo pipefail

function main() {
  agrozyme.alpine.function.sh change_core
  agrozyme.drupal.function.sh
  exec agrozyme.php.command.sh
}

main "$@"
