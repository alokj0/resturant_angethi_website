FROM php:8.2-apache
RUN docker-php-ext-install pdo pdo_mysql \
 && a2enmod headers \
 && echo 'SetEnvIf Authorization "(.*)" HTTP_AUTHORIZATION=$1' > /etc/apache2/conf-enabled/auth-header.conf
COPY . /var/www/html/
# Render gives the port in $PORT; make Apache listen on it
CMD ["sh", "-c", "sed -i \"s/Listen 80/Listen ${PORT:-80}/; \" /etc/apache2/ports.conf && sed -i \"s/:80>/:${PORT:-80}>/\" /etc/apache2/sites-available/000-default.conf && apache2-foreground"]
