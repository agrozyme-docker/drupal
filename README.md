Drupal is an open source content management platform powering millions of websites and applications.

# Environment Variables
When you start the image, you can adjust the configuration of the instance by passing one or more environment variables on the docker run command line.

## DRUPAL_RESET
These variables are optional, set `YES` to overwrite files.

**If it set `YES`, execute the command after (re)start container.**
```
composer update
```

## DRUPAL_SECURITY
These variables are optional, set `YES` to remove `robots.txt` and protect `config` directory.

## DRUPAL_REVERSE_PROXY
These variables are optional, can set:
- `none`: no reverse proxy, it will comment all reverse proxy settings.
- `traefik`: assume use traefik reverse proxy, it will set all reverse proxy settings for traefik.

  set those settings in traefik service at docker-compose file for get real client IP.
```
ports:
  - target: 80
    published: 80
    mode: host
  - target: 443
    published: 443
    mode: host
```
- no set or others will ignore.