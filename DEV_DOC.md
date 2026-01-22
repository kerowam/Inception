# Developer Documentation - Inception

## Table of Contents

1. [Environment Setup](#environment-setup)
2. [Project Structure](#project-structure)
3. [Building & Launching](#building--launching)
4. [Docker Commands Reference](#docker-commands-reference)
5. [Data Storage & Persistence](#data-storage--persistence)
6. [Debugging & Troubleshooting](#debugging--troubleshooting)
7. [Development Workflow](#development-workflow)

---

## Environment Setup

### Prerequisites

- **Linux-based OS Virtual Machine** (Ubuntu 20.04+, Debian 11+)
- **sudo** to exec commands with administrator (root) privileges
  ```bash
  apt install sudo
  ```
- **Docker and Docker Compose** (20.10+)
  ```bash
  sudo apt install docker docker-compose
  sudo usermod -aG docker $USER  # Add user to docker group
  ```
- **Make** for task automation
- **ufw** (Uncomplicated Firewall) for ports management
- **OpenSSL** for certificate generation
  ```bash
  sudo apt install make ufw openssl
  ```

### Initial Configuration

1. **Configure ssh:**
  • vim /etc/ssh/sshd_config -> Port 42 \
  • service ssh restart && service sshd restart 

2. **Configure ufw:**
   • ufw enable && ufw allow 443/1042

3. **Port forwarding in VB:**
   • In VirtualBox -> Settings -> Network -> Advanced -> Port forwarding
  - **ssh** -> 1042:1042
  - **https** -> 443:443 

---

## Project Structure

```
Inception/
├── Makefile                          # Task automation
├── README.md                         # Project overview
├── USER_DOC.md                       # End-user documentation
├── DEV_DOC.md                        # Developer documentation
└── srcs/
    ├── .env                          # Environment variables (NOT in git)
    ├── docker-compose.yml            # Service orchestration
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile            # MariaDB container image
        │   └── conf/
        │       └── create_db.sh       # Database initialization script
        ├── nginx/
        │   ├── Dockerfile            # Nginx container image
        │   ├── conf/
        │   │   └── nginx.conf         # Nginx configuration
        │   └── tools/
        │       └── certs/             # SSL certificates (NOT in git)
        │           ├── domain.42.fr.crt
        │           └── domain.42.fr.key
        └── wordpress/
            ├── Dockerfile            # WordPress container image
            └── conf/
                ├── wp-config.sh       # WordPress configuration script
                └── wp-setup.sh        # WordPress initialization script
```

### Key Files Explanation

| File | Purpose |
|------|---------|
| `Makefile` | Build targets (all, down, clean, fclean, re) |
| `docker-compose.yml` | Service definitions, networking, volumes |
| `Dockerfile` (each service) | Container image specifications |
| `conf/*` scripts | Service initialization and configuration |
| `.env` | Secrets and configuration (gitignored) |

---

## Building & Launching

### Using Make (Recommended)

```bash
# Build and start all services
make all

# Stop containers (preserves data)
make down

# Clean up images (keeps volumes)
make clean

# Full cleanup (removes everything)
make fclean

# Rebuild everything from scratch
make re
```

### Manual Docker Compose Commands

```bash
# Build images without starting
docker-compose -f srcs/docker-compose.yml build

# Start services in background
docker-compose -f srcs/docker-compose.yml up -d

# Stop services
docker-compose -f srcs/docker-compose.yml down

# View running services
docker-compose -f srcs/docker-compose.yml ps

# View logs for all services
docker-compose -f srcs/docker-compose.yml logs

# View logs for specific service
docker-compose -f srcs/docker-compose.yml logs wordpress

# Follow logs in real-time
docker-compose -f srcs/docker-compose.yml logs -f nginx
```

### Build Process Flow

1. **Make reads `.env`** - Loads environment variables
2. **Create directories** - `/home/$USER/data/mariadb` and `//home/$USER/data/wordpress`
3. **Build images:**
   - MariaDB image built with database initialization
   - Nginx image built with SSL certificates
   - WordPress image built with PHP-FPM and WP-CLI
4. **Create containers** - Instances started with network configuration
5. **Initialize services:**
   - MariaDB: Creates database, users, and applies security hardening
   - WordPress: Downloads WordPress, creates wp-config.php, installs WordPress
   - Nginx: Starts web server, configures SSL

---

## Docker Commands Reference

### Container Management

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Stop a container
docker stop <container_name>

# Start a container
docker start <container_name>

# Remove a container
docker rm <container_name>

# View container logs
docker logs <container_name>

# Follow logs (real-time)
docker logs -f <container_name>

# Last 50 lines of logs
docker logs --tail 50 <container_name>

# Get container details
docker inspect <container_name>
```

### Interactive Access

```bash
# Execute command in running container
docker exec -it <container_name> <command>

# Open shell in WordPress container
docker exec -it wordpress /bin/sh

# Open shell in Nginx container
docker exec -it nginx /bin/bash

# Open shell in MariaDB container
docker exec -it mariadb /bin/bash

# Run one-off command
docker exec mariadb mysql -u root -p -e "SHOW DATABASES;"
```

### Image Management

```bash
# List all images
docker images

# View image details
docker inspect <image_id>

# Remove an image
docker rmi <image_id>

# Build image manually
docker build -t myimage:tag -f Dockerfile .

# View image history
docker history <image_name>
```

### Volume Management

```bash
# List all volumes
docker volume ls

# View volume details
docker volume inspect <volume_name>

# Remove a volume
docker volume rm <volume_name>

# List files in bind mount
ls -la /home/$(USER)/data/wordpress
ls -la /home/$(USER)/data/mariadb
```

### Network Debugging

```bash
# List networks
docker network ls

# Inspect network
docker network inspect inception

# Test connectivity between containers
docker exec wordpress ping mariadb

# Test DNS resolution
docker exec wordpress nslookup wordpress

# View network traffic (requires packet tools)
docker exec nginx tcpdump -i eth0
```

### System Management

```bash
# View resource usage
docker stats

# Clean up unused resources
docker system prune

# Full cleanup with volumes
docker system prune -a --volumes

# View disk usage
docker system df
```

---

## Data Storage & Persistence

### Volume Structure

```
/home/$USER/
├── data/
│   ├── mariadb/
│   │   ├── mysql/               # System database
│   │   ├── wordpress/           # WordPress database
│   │   ├── aria_log_control     # Log files
│   │   └── ...                  # Other DB files
│   └── wordpress/
│       ├── index.php            # WordPress entry point
│       ├── wp-config.php        # Configuration file
│       ├── wp-content/          # Plugins, themes, uploads
│       │   ├── plugins/         # Installed plugins
│       │   ├── themes/          # Installed themes
│       │   └── uploads/         # User uploads (media)
│       ├── wp-admin/            # WordPress admin
│       └── wp-includes/         # WordPress core files
```

### Persistent Data Points

**What persists (survives container restart):**
- WordPress files and configuration
- Database tables and content
- Plugins and themes installed
- User uploads and media
- WordPress settings and posts

**What doesn't persist (recreated on restart):**
- Container filesystem (except mounted volumes)
- Temporary files in /tmp
- Docker layer caches

### Backing Up Data

```bash
# Backup WordPress files
tar -czf backup-wordpress-$(date +%Y%m%d).tar.gz /home/$(USER)/data/wordpress/

# Backup MariaDB
docker exec mariadb mysqldump -u wordpress -p wordpress > backup-db-$(date +%Y%m%d).sql

# Backup both
docker exec mariadb mysqldump -u wordpress -p wordpress | gzip > db.sql.gz

# Restore WordPress files
tar -xzf backup-wordpress-20250120.tar.gz -C /

# Restore database
docker exec -i mariadb mysql -u wordpress -p wordpress < backup-db-20250120.sql
```

### Data Migration

```bash
# Copy data to external storage
cp -r /home/$(USER)/data/ /external/backup/

# Migrate to new server
rsync -avz /home/$(USER)/data/ newserver:/home/username/data/
```

---

## Debugging & Troubleshooting

### Common Issues

#### 1. **Nginx shows unhealthy**

```bash
# Check nginx configuration syntax
docker exec nginx nginx -t

# View nginx logs
docker logs nginx

# Check if certificates exist
docker exec nginx ls -la /etc/nginx/ssl/

# Validate SSL certificate
docker exec nginx openssl x509 -in /etc/nginx/ssl/domain.42.fr.crt -noout -text
```

#### 2. **WordPress can't connect to database**

```bash
# Check database is running
docker exec mariadb mysqladmin ping -h localhost

# Verify credentials
docker exec mariadb mysql -u wordpress -p -e "SELECT VERSION();"

# Check if database exists
docker exec mariadb mysql -u wordpress -p -e "SHOW DATABASES;"

# View WordPress logs
docker logs wordpress

# Check database connection from WordPress
docker exec wordpress php -r "mysqli_connect('mariadb', 'wordpress', 'dbpass', 'wordpress');"
```

#### 3. **MariaDB fails to initialize**

```bash
# View initialization logs
docker logs mariadb

# Check if data directory is corrupted
ls -la /home/$(USER)/data/mariadb/

# Backup and reinitialize
mv /home/$(USER)/data/mariadb /home/$(USER)/data/mariadb.bak
make fclean && make all
```

#### 4. **Port 443 already in use**

```bash
# Find what's using port 443
sudo lsof -i :443
sudo netstat -tlnp | grep 443

# Kill the process
sudo kill -9 <PID>

# Or change port in docker-compose.yml
# Change: "443:443" to "8443:443"
```

### Debug Strategies

**Enable verbose logging:**
```bash
# View all service logs
docker-compose -f srcs/docker-compose.yml logs

# Watch logs in real-time
docker-compose -f srcs/docker-compose.yml logs -f

# Get last 100 lines
docker-compose -f srcs/docker-compose.yml logs --tail 100
```

**Test connectivity:**
```bash
# From host to nginx
curl -k https://localhost:443

# Between containers
docker exec wordpress curl http://nginx:443

# DNS resolution
docker exec wordpress nslookup mariadb
```

**Inspect container state:**
```bash
# Full container details
docker inspect wordpress | jq '.[] | {Id, State, Mounts}'

# Environment variables
docker inspect wordpress | jq '.[0].Config.Env'

# Network settings
docker inspect wordpress | jq '.[0].NetworkSettings'
```

---

## Development Workflow

### Making Configuration Changes

1. **Edit configuration file** (e.g., nginx.conf):
   ```bash
   nano srcs/requirements/nginx/conf/nginx.conf
   ```

2. **Test syntax** (for config files):
   ```bash
   docker exec nginx nginx -t
   ```

3. **Reload without restart** (if supported):
   ```bash
   docker exec nginx nginx -s reload
   ```

4. **Or restart container**:
   ```bash
   docker restart nginx
   ```

### Adding Packages to Containers

**Edit Dockerfile** and add to RUN command:
```dockerfile
RUN apt-get update && apt-get install -y \
    your-new-package \
    another-package && rm -rf /var/lib/apt/lists/*
```

Rebuild:
```bash
docker-compose -f srcs/docker-compose.yml build --no-cache wordpress
```

### Performance Profiling

```bash
# Check resource usage
docker stats

# View detailed memory usage
docker exec wordpress ps aux

# Check disk usage
du -sh /home/$(USER)/data/wordpress
du -sh /home/$(USER)/data/mariadb
```

---

## Further Reading

- [Docker Official Docs](https://docs.docker.com/)
- [Docker Compose Docs](https://docs.docker.com/compose/)
- [Nginx Configuration](https://nginx.org/en/docs/)
- [WordPress Development](https://developer.wordpress.org/)
- [MariaDB Documentation](https://mariadb.com/kb/en/)
- [PHP-FPM](https://www.php.net/manual/en/install.fpm.php)

---
