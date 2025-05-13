FROM debian:bullseye

RUN apt-get update && apt-get install -y nginx openssl

COPY ./tools/certs/gfredes-.42.fr.crt /etc/nginx/ssl/gfredes-.42.fr.crt
COPY ./tools/certs/gfredes-.42.fr.key /etc/nginx/ssl/gfredes-.42.fr.key

COPY conf/nginx.conf /etc/nginx/sites-available/default

#COPY index.html /var/www/html/index.html
RUN touch /var/www/html/index.html && echo "<h1>Nginx is working!</h1>" > /var/www/html/index.html

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]