NAME = inception

all:
	@if [ ! -f srcs/.env ]; then cp /home/$(USER)/.env srcs/.env; fi
	@if [ ! -f srcs/requirements/nginx/tools/certs/$(USER).42.fr.crt ]; then \
		cp /home/$(USER)/$(USER).42.fr.crt srcs/requirements/nginx/tools/certs/$(USER).42.fr.crt; fi
	@if [ ! -f srcs/requirements/nginx/tools/certs/$(USER).42.fr.key ]; then \
		cp /home/$(USER)/$(USER).42.fr.key srcs/requirements/nginx/tools/certs/$(USER).42.fr.key; fi
	@mkdir -p /home/$(USER)/data
	@mkdir -p /home/$(USER)/data/mariadb
	@mkdir -p /home/$(USER)/data/wordpress
	@printf "${NAME}: Building and setting configuration: ${NAME}...\n"
	@docker-compose -f srcs/docker-compose.yml --env-file srcs/.env up -d --build

down:
	@printf "${NAME}: Stopping...\n"
	@docker-compose -f srcs/docker-compose.yml down

clean:	down
	@printf "${NAME}: Cleaning configuration...\n"
	@docker system prune -a

fclean:
	@printf "${NAME}: Cleaning configuration and volumes...\n"
	@if [ -n "$$(docker ps -qa)" ]; then docker stop $$(docker ps -qa); fi
	@docker system prune --all --force --volumes
	@docker network prune --force
	@docker volume prune --force
	@docker image prune --all --force
	@docker container prune --force
	@docker builder prune --all --force
	@if [ -n "$$(docker volume ls -q)" ]; then docker volume rm $$(docker volume ls -q); fi
	@if [ -d "/home/$(USER)/data" ]; then sudo rm -rf /home/$(USER)/data; fi

re:	clean all

.PHONY: all down clean fclean re copy