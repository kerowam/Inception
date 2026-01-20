FROM alpine:3.22

ARG DB_NAME
ARG DB_USER
ARG DB_PASS
ARG DB_ROOT

RUN apk update && apk add --no-cache mariadb mariadb-client

RUN mkdir -p /var/run/mysqld && chown mysql:mysql /var/run/mysqld

RUN mkdir -p /etc/my.cnf.d && echo '[mysqld]\nskip-host-cache\nskip-name-resolve\nbind-address=0.0.0.0' > /etc/my.cnf.d/docker.cnf

RUN sed -i 's/^skip-networking/#skip-networking/' /etc/my.cnf.d/mariadb-server.cnf

RUN mariadb-install-db --user=mysql --datadir=/var/lib/mysql

EXPOSE 3306

COPY conf/create_db.sh .

RUN sh create_db.sh

USER mysql

CMD ["/usr/bin/mariadbd", "--skip-log-error"]