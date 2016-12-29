#!/usr/bin/env bash

##
# This file is used to create basic starting point content for dev/test/stage/production
##

# Set defaults
export MYSQL_HOST=${DB_PORT_3306_TCP_ADDR-$MYSQL_HOST}
export MYSQL_PORT=${MYSQL_PORT-$DB_PORT}

# Wait until mysql is open
nc -z $MYSQL_HOST $MYSQL_PORT
if [[ $? != 0 ]] ; then
  echo "Waiting mysql to open in $DB_HOST:$DB_PORT..."
  declare -i i
  while ! nc -z $MYSQL_HOST $MYSQL_PORT; do
    if [ "$i" == "15" ]; then
      echo "Error: Mysql process timeout"
      exit 1
    fi
    i+=1
    sleep 1
  done
fi

# Fail after errors
set -e


# Get script directory
DIR=$(dirname $(readlink -f "$0"))

echo "Starting to import database seed..."

##
# Set default values for WP
##
export WP_ADMIN_USER=${WP_ADMIN_USER-admin}
# Generate password if it's missing
if [ "$WP_ADMIN_PASSWORD" == "" ]; then
    export WP_ADMIN_PASSWORD=$(openssl rand -base64 18)
fi

if [ "$SERVER_NAME" != "" ]; then
    export WP_ADMIN_EMAIL=admin@$SERVER_NAME
elif [ "$SMTP_FROM" != "" ]; then
    export WP_ADMIN_EMAIL=$SMTP_FROM
else
    export WP_ADMIN_EMAIL=admin@wordpress.test
fi

export WP_SITEURL=${WP_SITEURL-http://$SERVER_NAME}
export WP_TITLE=${WP_TITLE-WordPress}

# Install WordPress if not installed yet
if wp core version > /dev/null && ! wp core is-installed; then

    echo "You can login to WordPress with credentials: $WP_ADMIN_USER / $WP_ADMIN_PASSWORD"
    # Install basic tables
    wp core install --url=$WP_SITEURL --title=$WP_TITLE \
                    --admin_user=$WP_ADMIN_USER --admin_email=$WP_ADMIN_EMAIL \
                    --admin_password=$WP_ADMIN_PASSWORD

    # Activate all plugins
    wp plugin activate --all
fi