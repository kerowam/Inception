NAME = inception

all:
	@mkdir -p /home/$(USER)/data
	@mkdir -p /home/$(USER)/data/mariadb
	@mkdir -p /home/$(USER)/data/wordpress
	@printf "${name}: Building and setting configuration: ${NAME}...\n"
	@docker-compose -f srcs/docker-compose.yml --env-file srcs/.env up -d --build

down:
	@printf "${name}: Stopping...\n"
	@docker-compose -f srcs/docker-compose.yml down

clean:	down
	@printf "${name}: Cleaning configuration...\n"
	@docker system prune -a
	
fclean:
	@printf "${name}: Cleaning configuration and volumes...\n"
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

.PHONY: all down clean fclean re build