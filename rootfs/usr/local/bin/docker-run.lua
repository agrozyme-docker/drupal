#!/usr/bin/lua
local core = require("docker-core")
local pcre = require("rex_pcre")
local php = require("docker-php")

local function create_project(html)
  local json = html .. "/composer.json"

  if (core.test("! -f %s", json)) then
    core.run("tar -zxf %s/../drupal-project.tgz -C %s", html, html)
  end

  core.chown(html)
end

local function update_class_loader_auto_detect(text)
  local switch = core.getenv("DRUPAL_CLASS_LOADER_AUTO_DETECT", "")
  local pattern = [[^[\/#\s]*($settings\[['"]class_loader_auto_detect['"]\])[\s]*=[\s]*(.*)$]]

  if (core.boolean(switch)) then
    return pcre.gsub(text, pattern, "# %1 = %2", nil, "im")
  else
    return pcre.gsub(text, pattern, "%1 = FALSE", nil, "im")
  end
end

local function update_config_private_settings(text)
  local pattern = [[^[\/#\s]*($settings\[[\s]*['"]file_private_path['"][\s]*\])[\s]*=.*$]]
  return pcre.gsub(text, pattern, "%1 = 'sites/default/private';", nil, "im")
end

local function update_config_content_settings(text)
  local pattern = [[^([\/#\s]*$settings\[[\s]*['"]default_content_deploy_content_directory['"][\s]*\][\s]*=.*)$]]
  return pcre.gsub(text, pattern, "", nil, "im")
end

local function update_reverse_proxy_settings(text)
  local switch = core.getenv("DRUPAL_REVERSE_PROXY", "")
  local proxy = switch:lower(switch)
  local pattern = [[^[\/#\s]*($settings\[[\s]*['"]%s['"][\s]*\])[\s]*=[\s]*(.*)$]]

  if ("none" == proxy) then
    text = pcre.gsub(text, string.format(pattern, "reverse_proxy"), "# %1 = %2", nil, "im")
    text = pcre.gsub(text, string.format(pattern, "reverse_proxy_addresses"), "# %1 = %2", nil, "im")
    text = pcre.gsub(text, string.format(pattern, "reverse_proxy_header"), "# %1 = %2", nil, "im")
    text = pcre.gsub(text, string.format(pattern, "reverse_proxy_proto_header"), "# %1 = %2", nil, "im")
    text = pcre.gsub(text, string.format(pattern, "reverse_proxy_host_header"), "# %1 = %2", nil, "im")
    text = pcre.gsub(text, string.format(pattern, "reverse_proxy_port_header"), "# %1 = %2", nil, "im")
    text = pcre.gsub(text, string.format(pattern, "reverse_proxy_forwarded_header"), "# %1 = %2", nil, "im")
    return text
  end

  if ("traefik" == proxy) then
    text = pcre.gsub(text, string.format(pattern, "reverse_proxy"), "%1 = TRUE;", nil, "im")
    text =
      pcre.gsub(text, string.format(pattern, "reverse_proxy_addresses"), "%1 = [$_SERVER['REMOTE_ADDR']];", nil, "im")
    text = pcre.gsub(text, string.format(pattern, "reverse_proxy_header"), "%1 = 'x-real-ip';", nil, "im")
    text = pcre.gsub(text, string.format(pattern, "reverse_proxy_proto_header"), "# %1 = %2", nil, "im")
    text = pcre.gsub(text, string.format(pattern, "reverse_proxy_host_header"), "# %1 = %2", nil, "im")
    text = pcre.gsub(text, string.format(pattern, "reverse_proxy_port_header"), "# %1 = %2", nil, "im")
    text = pcre.gsub(text, string.format(pattern, "reverse_proxy_forwarded_header"), "# %1 = %2", nil, "im")
    return text
  end

  return text
end

local function update_settings(...)
  local handler = function(target)
    if (core.test("! -f %s", target)) then
      return
    end

    local text = core.read_file(target)
    text = update_class_loader_auto_detect(text)
    text = update_config_private_settings(text)
    text = update_config_content_settings(text)
    text = update_reverse_proxy_settings(text)
    core.write_file(target, text)
    core.append_file(target, "$settings['default_content_deploy_content_directory'] = '../content'; \n")
  end

  for _, target in pairs({...}) do
    handler(target)
  end
end

local function update_security(html)
  local switch = core.getenv("DRUPAL_SECURITY", "")

  if (not core.boolean(switch)) then
    return
  end

  core.run("rm -f %s/web/robots.txt", html)
end

local function update_composer()
  local switch = core.getenv("DRUPAL_COMPOSER_UPDATE", "")

  if (not core.boolean(switch)) then
    return
  end

  core.run("composer -n update drupal/core-recommended --with-dependencies")
  core.run("drush updatedb")
  core.run("drush cache:rebuild")
end

local function main()
  local html = "/var/www/html"
  local default = html .. "/web/sites/default"

  core.update_user()
  create_project(html)
  core.run("rm -rf '%s/files/config_*/'", default)
  core.run("mkdir -p %s/private %s/config/sync %s/content", default, html, html)
  update_settings(default .. "/default.settings.php", default .. "settings.php")
  update_security(html)
  update_composer()

  -- core.run("drush core-status")
  -- core.run("drupal check")
  php.run()
end

main()
