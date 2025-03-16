FROM debian:buster as builder-crt-key

RUN apt-get update && apt-get install -y openssl

run mkdir /crt-key

run openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /crt-key/nginx.key -out /crt-key/nginx.crt -subj "/C=SP/ST=Malaga/L=Malaga/O=42 Malaga/OU=gfredes-/CN=gfredes-"

FROM debian:buster

RUN apt-get update && apt-get install -y nginx

#COPY ./requirements/nginx/nginx.conf /etc/nginx/sites-available/default

COPY --from=builder-crt-key /crt-key /etc/nginx/ssl

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
