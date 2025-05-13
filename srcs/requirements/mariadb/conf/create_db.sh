#!/bin/sh

if [ ! -d "/var/lib/mysql/mysql" ]; then

    echo "Initializing MariaDB..."
    chown -R mysql:mysql /var/lib/mysql
    
    mysql_install_db --basedir=/usr --datadir=/var/lib/mysql --user=mysql --rpm

    tfile=$(mktemp)
    if [ ! -f "$tfile" ]; then
        echo "Error: Failed to create temporary file"
        exit 1
    fi
fi

if [ ! -d "/var/lib/mysql/${DB_NAME}" ]; then
    echo "Creating database and user..."

    cat <<EOF > /tmp/create_db.sql
USE mysql;
FLUSH PRIVILEGES;

DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test';

DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.1', '::1');

ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT}';

CREATE DATABASE ${DB_NAME} CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF

        /usr/bin/mysqld --user=mysql --bootstrap < /tmp/create_db.sql
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create database and user"
        exit 1
    fi
    rm -f /tmp/create_db.sql
fi