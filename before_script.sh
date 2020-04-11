#!/bin/bash
set -eux

function main() {
  local prefix="./rootfs"
  local bin="${prefix}/usr/local/bin"
  local run="${bin}/docker-build.sh"
  chmod +x "${bin}"/*
  ${run} setup "${prefix}"
}

main "$@"
