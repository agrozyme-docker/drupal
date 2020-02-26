#!/usr/bin/lua
local core = require("docker-core")

local function drupal_setup()
  local www = "/var/www"
  local project = "/tmp/drupal-project"
  core.run("composer create-project --no-install --no-interaction drupal-composer/drupal-project:8.x-dev %s", project)
  core.run("mv %s/composer.json %s/composer.json", www, project)
  core.run("composer --working-dir=%s install", project)
  core.run("tar -czf %s/drupal-project.tgz -C %s .", www, project)
  core.run("rm -rf %s", project)
end

local function drush_setup(bin)
  local version = "8.3.2"
  core.run("wget -qO %s/drush https://github.com/drush-ops/drush/releases/download/%s/drush.phar", bin, version)
end

local function drupal_check(bin)
  local version = "1.1.0"
  core.run(
    "wget -qO %s/drupal-check https://github.com/mglaman/drupal-check/releases/download/%s/drupal-check.phar",
    bin,
    version
  )
end

local function drupal_console_setup(bin)
  local version = "1.9.4"
  core.run(
    "wget -qO %s/drupal https://github.com/hechoendrupal/drupal-console-launcher/releases/download/%s/drupal.phar",
    bin,
    version
  )
end

local function main()
  local bin = "/usr/local/bin"
  core.run("apk add --no-cache lua-rex-pcre mariadb-client postgresql-client openssh-client rsync")
  drupal_setup()
  drush_setup(bin)
  drupal_check(bin)
  drupal_console_setup(bin)
  core.run("chmod +x %s/*", bin)
  core.run("drush core-status")
  core.run("drupal check")
  core.run("composer clear-cache")
end

main()
