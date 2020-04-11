#!/usr/bin/lua
local core = require("docker-core")

local function update_composer_json(file)
  local rapidjson = require("rapidjson")
  local data = rapidjson.load(file)

  local repo = data.repositories
  repo[#repo + 1] = {type = "composer", url = "https://asset-packagist.org"}

  local extra = data.extra
  extra.patchLevel = {["drupal/core"] = "-p2"}
  extra["enable-patching"] = true
  extra["composer-exit-on-patch-failure"] = true
  extra["installer-types"] = {"ckeditor-plugin", "npm-asset", "bower-asset"}

  local path = extra["installer-paths"]
  path["web/libraries/ckeditor/plugins/{$name}"] = {"type:ckeditor-plugin"}

  local lib = path["web/libraries/{$name}"]
  lib[#lib + 1] = "type:bower-asset"
  lib[#lib + 1] = "type:npm-asset"

  rapidjson.dump(data, file, {pretty = true})
end

local function drupal_setup()
  local version = "8.8.5"
  local www = "/var/www"
  local project = "/tmp/drupal-project"
  local composer = project .. "/composer.json"
  core.run(
    "composer create-project --no-install --no-interaction --no-progress drupal/recommended-project:%s %s",
    version,
    project
  )

  update_composer_json(composer)

  core.run(
    "composer require --no-interaction --no-update --no-progress --sort-packages --working-dir=%s zaporylie/composer-drupal-optimizations cweagans/composer-patches oomphinc/composer-installers-extender vlucas/phpdotenv webflo/drupal-finder drush/drush drupal/console",
    project
  )

  core.run("composer install --no-interaction --no-progress --working-dir=%s", project)
  core.run("tar -czf %s/drupal-project.tgz -C %s .", www, project)
  core.run("rm -rf %s", project)
end

local function main()
  local bin = "/usr/local/bin"
  core.run("apk add --no-cache lua-rex-pcre lua-rapidjson mariadb-client postgresql-client openssh-client rsync")
  drupal_setup()
  core.run("%s/docker-build.sh setup", bin)
  core.run("chmod +x %s/*", bin)
  core.run("drush core-status")
  core.run("drupal check")
  core.run("composer clear-cache")
end

main()
