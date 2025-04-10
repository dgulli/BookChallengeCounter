#!/bin/sh

# Substitute environment variables in the Nginx config template
envsubst '$PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

# Execute the CMD (nginx)
exec nginx -g 'daemon off;' 