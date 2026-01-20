#!/bin/sh

if [ -f /var/www/html/wp-config.php ] &&
    wp core is-installed --allow-root --path="/var/www/html" &&
    wp user get "$WP_USER" --allow-root --path="/var/www/html" &> /dev/null 2>&1; then
        echo "WordPress is already installed and configured."
        exit 0
fi

if ! command -v wp > /dev/null 2>&1; then
    echo "Error: WP-CLI is not installed. Please install it first."
    exit 1
fi

if [ ! -f /var/www/html/wp-config.php ]; then
    echo "Error: WordPress files not found in /var/www/html. Please check the volume mount."
    exit 1
fi

if ! command -v php > /dev/null 2>&1; then
    echo "Error: PHP is not installed. Please install it first."
    exit 1
fi

echo "Creating setup:"
echo "DB_NAME: ${DB_NAME}"
echo "DB_USER: ${DB_USER}"
echo "DB_PASS: ${DB_PASS}"

MAX_RETRIES=5
RETRIES=0
until mysql -h mariadb -u"${DB_USER}" -p"${DB_PASS}" -e "USE ${DB_NAME};" 2>/dev/null; do
    RETRIES=$((RETRIES + 1))
    if [ ${RETRIES} -ge ${MAX_RETRIES} ]; then
        echo "Error: Could not connect to MariaDB after $MAX_RETRIES attempts"
        echo "Trying command: mysql -h mariadb -u${DB_USER} -p[hidden] -e \"USE ${DB_NAME};\""
        mysql -h mariadb -u"${DB_USER}" -p"${DB_PASS}" -e "USE ${DB_NAME};"
        exit 1
    fi
    echo "Waiting for MariaDB... (attempt $RETRIES/$MAX_RETRIES)"
    sleep 5
done

echo "MariaDB is up and running. Proceeding with WordPress setup."

if ! wp core is-installed --allow-root --path="/var/www/html"; then
    echo "Installing WordPress..."
    wp core install --allow-root \
        --url="https://$DOMAIN_NAME" \
        --title="gfredes- inception" \
        --admin_user="$DB_USER" \
        --admin_password="$DB_PASS" \
        --admin_email="germanfredes1988@protonmail.com" \
        --path="/var/www/html"
    if [ $? -ne 0 ]; then
        echo "Error: WordPress installation failed."
        exit 1
    fi
else
    echo "WordPress is already installed."
fi

if ! wp user list --allow-root --path="/var/www/html" | grep -q "^\s*[0-9]\+\s\+$WP_USER\s"; then
    echo "Creating WordPress user '$WP_USER'..."
    wp user create "$WP_USER" "guest@example.com" \
        --role=author \
        --user_pass="$WP_PASS" \
        --allow-root \
        --path="/var/www/html"
    [ $? -ne 0 ] && echo "Error: Failed to create WordPress user '$WP_USER'." && exit 1
else
    echo "WordPress user '$WP_USER' already exists."
fi

echo "WordPress setup completed successfully!"
    