#!/bin/bash
set -euo pipefail

function main() {
  agrozyme.drupal.function.sh
  exec agrozyme.php.command.sh
}

main "$@"
