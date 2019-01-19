#!/usr/bin/lua
local core = require("docker-core")

local function main()
  local bin = "/usr/bin"
  local www = "/var/www"
  local project = "/tmp/drupal-project"
  core.run("apk add --no-cache lua-rex-pcre")
  core.run("%s/composer create-project --no-install drupal-composer/drupal-project:8.x-dev %s", bin, project)
  core.run("mv %s/composer.json %s/composer.json", www, project)
  core.run("%s/composer --working-dir=%s install", bin, project)
  core.run("tar -czf %s/drupal-project.tgz -C %s .", www, project)
  core.run("%s/composer clear-cache", bin)
  core.run("rm -rf %s", project)
end

main()
