FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y apache2 && \
    sed -i 's/^Listen 80/Listen 6400/' /etc/apache2/ports.conf && \
    sed -i 's/<VirtualHost \*:80>/<VirtualHost *:6400>/' \
      /etc/apache2/sites-enabled/000-default.conf

EXPOSE 6400

CMD ["apache2ctl", "-D", "FOREGROUND"]
