# User Documentation - Inception

## Table of Contents

1. [Services Overview](#services-overview)
2. [Starting & Stopping](#starting--stopping)
3. [Accessing the Services](#accessing-the-services)
4. [Managing Credentials](#managing-credentials)
5. [Verifying Services](#verifying-services)
6. [Troubleshooting](#troubleshooting)

---

## Services Overview

Inception provides a complete web hosting stack with three main services:

### 1. **Nginx** - Web Server & Reverse Proxy
- **Purpose:** Handles incoming HTTPS connections, routes requests to WordPress
- **Port:** 443 (HTTPS only)
- **Features:** 
  - SSL/TLS encryption for secure communication
  - Reverse proxy to PHP-FPM service
  - Static file serving

### 2. **WordPress** - Content Management System
- **Purpose:** Blogging platform and website content management
- **Port:** 9000 (FastCGI, internal only)
- **Features:**
  - Full WordPress installation with themes and plugins
  - PHP-FPM application server
  - Admin dashboard for content management

### 3. **MariaDB** - Database Server
- **Purpose:** Stores all WordPress data (posts, pages, users, settings)
- **Port:** 3306 (internal only, not exposed to host)
- **Features:**
  - Relational database for data persistence
  - User authentication
  - Backup-compatible structure

---

## Starting & Stopping

### Starting the Project

```bash
cd /path/to/Inception
make all
```

This will:
1. Create necessary directories for data storage
2. Build Docker images (if not already built)
3. Start all three containers
4. Initialize the database and WordPress

**Expected output:** All services should show as "Up" when you run:
```bash
docker ps
```

### Stopping the Project

```bash
make down
```

This will:
- Stop all running containers
- **Preserve** all data (volumes are kept)
- Keep images and configurations intact

### Restarting After Stop

```bash
make all
```

Simply run `make all` again - it will restart existing containers without rebuilding.

---

## Accessing the Services

### 1. **Accessing WordPress Website**

**URL:** `https://gfredes-.42.fr`

**Note:** Your browser may show a security warning because the SSL certificate is self-signed. This is normal for development.

**To bypass the warning:**
- Firefox: Click "Advanced" → "Accept the Risk and Continue"
- Chrome: Click "Advanced" → "Proceed to..." 
- Safari: Click "Show Details" → "Visit this Website"

### 2. **Accessing WordPress Admin Panel**

**URL:** `https://gfredes-.42.fr/wp-admin`

**Login credentials:**
- **Username:** Value of `DB_USER` from your `.env` file
- **Password:** Value of `DB_PASS` from your `.env` file

**What you can do in the admin panel:**
- Create and edit posts/pages
- Manage users and permissions
- Install plugins and themes
- Configure site settings
- View analytics and media

### 3. **Command-Line Access (Optional)**

To access containers directly:

```bash
# Connect to WordPress PHP-FPM shell
docker exec -it wordpress /bin/sh

# Connect to MariaDB shell
docker exec -it mariadb mariadb -u gfredes- -p

# Connect to Nginx shell
docker exec -it nginx /bin/bash
```

---

## Managing Credentials

### Locating Credentials

All credentials are stored in the `.env` file located at:
```
/path/to/Inception/srcs/.env
```

### Changing Passwords

#### Change WordPress Admin Password

1. Login to WordPress admin panel
2. Click "Users" in the left menu
3. Click on your username
4. Scroll to "Account Management"
5. Enter new password in "New Password" field
6. Click "Update Profile"

#### Change Database Password

**Warning:** Changing the database password requires updating `.env` and rebuilding:

1. Edit `srcs/.env`:
   ```
   DB_PASS=newpassword
   DB_ROOT_PASS=newrootpass
   ```

2. Rebuild containers:
   ```bash
   make fclean
   make all
   ```

### Security Best Practices

- **Never commit `.env` to version control** - It contains secrets
- **Use strong passwords** - Mix uppercase, lowercase, numbers, special characters
- **Rotate passwords regularly** - At least quarterly for production
- **Limit access** - Keep WordPress admin URLs private when possible
- **Keep software updated** - WordPress, plugins, and themes should be current

---

## Verifying Services

### Check All Services Are Running

```bash
docker ps
```

**Expected output:** Three containers should show as "Up"
```
CONTAINER ID   IMAGE       STATUS
...            nginx       Up 2 minutes (healthy)
...            wordpress   Up 2 minutes
...            mariadb     Up 2 minutes (healthy)
```

### Check Service Health

```bash
# MariaDB health check
docker exec mariadb mysqladmin ping -h localhost

# Output should show: "mysqld is alive"
```

### Test Database Connection

```bash
docker exec -it mariadb mariadb -u gfredes- -p -e "SELECT VERSION();"
```

Enter password when prompted. You should see the MariaDB version.

### Test WordPress Installation

1. Visit `https://gfredes-.42.fr/wp-admin`
2. Log in with your credentials
3. Navigate to "Posts" - should show existing posts
4. Check "Settings" → "General" - should show your site URL

### Verify Data Persistence

1. Create a new post in WordPress
2. Stop containers: `make down`
3. Start containers: `make all`
4. Check if your post still exists - it should!

