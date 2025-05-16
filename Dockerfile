FROM php:8.2-apache

# Instalar dependências do sistema e extensões PHP necessárias
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    unzip \
    git \
    mariadb-client \
    zip \
    pkg-config \
    && docker-php-ext-configure zip \
    && docker-php-ext-install pdo pdo_mysql mysqli gd xml opcache intl mbstring zip bcmath

# Ativar o módulo rewrite do Apache
RUN a2enmod rewrite

# Copiar os arquivos do GLPI
COPY glpi/ /var/www/html/

# Ajustar permissões
RUN chown -R www-data:www-data /var/www/html/ \
    && chmod -R 755 /var/www/html/

# Expor a porta do Apache
EXPOSE 80

CMD ["apache2-foreground"]
