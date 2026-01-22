_This project has been created as part of the 42 curriculum by gfredes-_

# Inception

## Description

**Inception** is a Docker-based containerization project that sets up a complete web infrastructure using modern DevOps practices. The project implements a multi-container environment featuring, each container includes one service:

- **Nginx** - is a high-performance web server and reverse proxy. Its primary function is to receive HTTP/HTTPS requests from clients and respond with web content, or forward those requests to other services.
- **WordPress with php-fpm** - WordPress is a content management system (CMS). Its main function is to allow you to create and manage websites without having to program them from scratch. PHP-FPM stands for PHP FastCGI Process Manager. It is the component that executes PHP code efficiently and independently of the web server in modern environments. 
- **MariaDB** - MariaDB is an open-source relational database management system (RDBMS). It is used to store, organize, and query structured data using SQL.

The goal is to understand and practice containerization concepts, Docker Compose orchestration, networking, persistence, and security best practices in a production-like environment.

## Instructions

### Prerequisites

- This project needs to be done on a Virtual Machine.
- Docker and Docker Compose installed
- SSL certificates for your domain (or generate them)
- Make utility

### Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd Inception
   ```

2. **Configure environment variables:**
   - Create or copy your `.env` file to `srcs/.env`
   - You can store sensitive credentials using Docker secrets

3. **Build and start the infrastructure:**
   ```bash
   make
   ```

4. **Stop the infrastructure:**
   ```bash
   make down
   ```

5. **Access the website:**
   - Open a browser and navigate to `https://<login>.42.fr`

### Makefile Commands

```bash
make all       # Build and start all containers
make down      # Stop containers without removing volumes
make clean     # Stop containers and clean unused images
make fclean    # Complete cleanup (containers, volumes, images, data)
make re        # Clean and rebuild everything
```

## Project Description

### Docker Architecture & Design Choices

This project uses **Docker Compose** to orchestrate three interconnected services:

- **Nginx Container** - Acts as reverse proxy, handles HTTPS, routes requests to WordPress. FROM debian:bookworm
- **WordPress Container** - Runs PHP-FPM application server with WordPress. FROM alpine:3.22
- **MariaDB Container** - Provides persistent database storage. FROM alpine:3.22

All containers communicate over a **custom bridge network** (`inception`), allowing service-to-service communication using DNS names.

### Virtual Machines vs Docker

*   **VM:** Virtualizes the **Hardware**. Each VM runs a full Operating System (Kernel + User Space) on top of a Hypervisor. It is heavy, slow to boot, but offers high isolation.
*   **Docker:** Virtualizes the **Operating System**. Containers share the Host's Kernel but have isolated User Spaces (bins/libs). They are lightweight, start instantly, and use fewer resources.

| Aspect | Virtual Machines | Docker |
|--------|-----------------|--------|
| **Overhead** | High - full OS per VM (~5-10GB) | Low - shared kernel (~MB per container) |
| **Startup Time** | Minutes | Seconds |
| **Resource Usage** | GB RAM per VM | Minimal RAM per container |
| **Isolation** | OS-level isolation | Process-level isolation |
| **Portability** | Tied to hypervisor | Runs anywhere Docker is installed |
| **Use Case** | Complete OS isolation needed | Application isolation preferred |

**Why Docker for Inception:** Lightweight, fast iteration, resource-efficient, industry-standard for microservices and DevOps. Better suited for development and containerized deployments compared to VMs.

### Secrets vs Environment Variables

*   **Environment Variables:** Stored in the container's environment. Easy to use and standard for configuration. However, they can be viewed via commands like `docker inspect`.
*   **Secrets (Docker Swarm/K8s):** Files encrypted at rest and mounted into `/run/secrets/` only when the container is running. This is the more secure industry standard for sensitive data (passwords, keys), though for this project, environment variables were used for simplicity.

| Aspect | Environment Variables | Secrets |
|--------|----------------------|---------|
| **Security** | Visible in `docker inspect` and logs | Encrypted at rest in Docker Swarm |
| **Use Case** | Configuration, non-sensitive data | Passwords, API keys, tokens |
| **Scope** | All processes in container | Only assigned services (Swarm) |
| **Rotation** | Requires container restart | Can be rotated without restart |
| **Complexity** | Simple to implement | More complex setup required |

**Inception Implementation:** Uses `.env` files with environment variables for simplicity (suitable for development). Variables are passed via docker-compose to containers.

### Docker Network vs Host Network

*   **Host Network:** The container shares the host's networking namespace. If the container listens on port 80, it binds directly to the host's port 80. Fast, but causes port conflicts and offers no isolation.
*   **Docker Network (Bridge):** Containers get their own IP addresses inside a virtual network. They can talk to each other via DNS names (e.g., `ping mariadb`). Ports must be explicitly mapped (`-p 80:80`) to be accessible from the outside.

| Aspect | Docker Network (Bridge) | Host Network |
|--------|------------------------|-------------|
| **Isolation** | Containers isolated from host | Direct host network access |
| **Inter-container Communication** | Via service names (DNS) | Via localhost/IP |
| **Port Mapping** | Required (port publishing) | Direct binding to host ports |
| **Security** | Better isolation | Less isolation |
| **Performance** | Slight overhead (~1-2%) | Minimal overhead |
| **Debugging** | More complex (namespace isolation) | Easier to debug |

**Inception Choice:** Uses a **custom bridge network** named `inception`. This approach:
- Allows containers to communicate via service names (`wordpress:9000` instead of IP)
- Maintains isolation from host network (except exposed ports)
- Provides automatic DNS resolution between containers
- Better for multi-container applications

### Docker Volumes vs Bind Mounts

*   **Docker Volume:** Volumes are persistent storage mechanisms managed by the Docker daemon. They retain data even after the containers using them are removed. Volume data is stored on the filesystem on the host, but in order to interact with the data in the volume, you must mount the volume to a container. Directly accessing or interacting with the volume data is unsupported, undefined behavior, and may result in the volume or its data breaking in unexpected ways.

Volumes are ideal for performance-critical data processing and long-term storage needs. Since the storage location is managed on the daemon host, volumes provide the same raw file performance as accessing the host filesystem directly.

*   **Bind Mounts:** Bind mounts create a direct link between a host system path and a container, allowing access to files or directories stored anywhere on the host. Since they aren't isolated by Docker, both non-Docker processes on the host and container processes can modify the mounted files simultaneously.

Use bind mounts when you need to be able to access files from both the container and the host.

| Aspect | Docker Volumes | Bind Mounts |
|--------|----------------|------------|
| **Management** | Managed by Docker daemon | Managed by host OS |
| **Location** | Docker's storage area | Any host directory |
| **Persistence** | Independent of container lifecycle | Tied to host path |
| **Performance** | Optimized for all platforms | OS-dependent |
| **Data Access** | From Docker perspective | From host perspective |
| **Backup** | Easy with Docker commands | Manual host-level backup |

**Inception Implementation:**

```yaml
# Bind Mounts - for live code editing
- ./requirements/nginx/conf/nginx.conf:/etc/nginx/sites-available/default
- wp-volume:/var/www/html  # Shared between WordPress and Nginx

# Docker Volumes - for database persistence
- db-volume:/var/lib/mysql
```

**Data Storage Location:**
- **WordPress:** `/home/$USER/data/wordpress/` - Contains WordPress files, plugins, themes
- **MariaDB:** `/home/$USER/data/mariadb/` - Contains database files and structure

This hybrid approach leverages:
- **Bind mounts** for source code → allows live editing, easy debugging
- **Docker volumes** for databases → better performance, easier backup/restore

## Resources

### Docker & Containerization
- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Guide](https://docs.docker.com/compose/)
- [Best Practices for Writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Docker Networking Overview](https://docs.docker.com/network/)
- [Docker Storage Options](https://docs.docker.com/storage/)

### Web Stack
- [Nginx Documentation](https://nginx.org/en/docs/)
- [WordPress Codex](https://codex.wordpress.org/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [PHP-FPM Documentation](https://www.php.net/manual/en/install.fpm.php)

### SSL/TLS & Security
- [Let's Encrypt](https://letsencrypt.org/)
- [OpenSSL Documentation](https://www.openssl.org/docs/)
- [Mozilla SSL Configuration Generator](https://mozilla.github.io/server-side-tls/ssl-config-generator/)

### DevOps Concepts
- [The Twelve-Factor App](https://12factor.net/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Container Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)

### AI Usage

AI assistance was utilized for:
- **Code review & optimization:** Analysis of Dockerfiles, shell scripts, and configurations for best practices
- **Documentation:** Structuring README.md, USER_DOC.md, and DEV_DOC.md according to requirements
- **Debugging:** Troubleshooting Docker networking, volume mounting, and container initialization issues
- **Architecture decisions:** Explaining Docker concepts, design trade-offs, and technology comparisons
- **Script validation:** SQL script optimization and shell script improvements