# Summary

Drupal is an open source content management platform powering millions of websites and applications.

# Commands

- [drush](https://drushcommands.com/)
- [drupal-check](https://github.com/mglaman/drupal-check)
- [drupal](https://drupalconsole.com/docs/en/)

# Environment Variables

When you start the image, you can adjust the configuration of the instance by passing one or more environment variables on the docker run command line.

## DRUPAL_COMPOSER_UPDATE

These variables are optional, set `YES` to run `composer update` after boot.

## DRUPAL_CLASS_LOADER_AUTO_DETECT

These variables are optional, set `YES` to use APC class loader.

**If the site get HTTP code 500, can set `NO` and try again.**

## DRUPAL_SECURITY

These variables are optional, set `YES` to remove `robots.txt`.

## DRUPAL_REVERSE_PROXY

These variables are optional, can set:

- `none`: no reverse proxy, it will comment all reverse proxy settings.
- `traefik`: assume use traefik reverse proxy, it will set all reverse proxy settings for traefik.
- no set or others will ignore.
