FROM php:8.2-apache

# Instalar dependências do sistema e extensões PHP necessárias
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libicu-dev \
    libldap2-dev \
    libbz2-dev \
    zlib1g-dev \
    unzip \
    curl \
    gnupg2 \
    git \
    libexif-dev \
    libssl-dev \
    libsodium-dev \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install \
    mysqli \
    pdo \
    pdo_mysql \
    intl \
    zip \
    gd \
    exif \
    ldap \
    opcache \
    bcmath \
    sockets \
    bz2 \
 && a2enmod rewrite ssl \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Criar diretórios seguros
RUN mkdir -p /var/www/html/public \
    && mkdir -p /var/lib/glpi/files

# Baixar e extrair o GLPI
RUN curl -L https://github.com/glpi-project/glpi/releases/download/10.0.18/glpi-10.0.18.tgz | tar xz \
    && mv glpi/* glpi/.htaccess /var/www/html/public/

# Mover o diretório "files" para fora da raiz web
RUN mv /var/www/html/public/files/* /var/lib/glpi/files \
    && rm -rf /var/www/html/public/files

# Criar diretórios que o GLPI espera
RUN mkdir -p /var/lib/glpi/files/_cache \
    /var/lib/glpi/files/_cron \
    /var/lib/glpi/files/_dumps \
    /var/lib/glpi/files/_graphs \
    /var/lib/glpi/files/_lock \
    /var/lib/glpi/files/_pictures \
    /var/lib/glpi/files/_plugins \
    /var/lib/glpi/files/_rss \
    /var/lib/glpi/files/_sessions \
    /var/lib/glpi/files/_tmp \
    /var/lib/glpi/files/_uploads

# Copiar plugins (se houver)
COPY plugins/ /var/www/html/public/plugins/

# Definir o caminho seguro do diretório de dados no config_path.php
RUN echo "<?php define('GLPI_VAR_DIR', '/var/lib/glpi/files');" > /var/www/html/public/config/config_path.php

# Criar ini para configurar session.cookie_httponly
RUN echo "session.cookie_httponly = 1" > /usr/local/etc/php/conf.d/glpi.ini

# Ajustar permissões
RUN chown -R www-data:www-data /var/www/html /var/lib/glpi \
 && find /var/www/html -type d -exec chmod 755 {} \; \
 && find /var/www/html -type f -exec chmod 644 {} \; \
 && find /var/lib/glpi -type d -exec chmod 750 {} \; \
 && find /var/lib/glpi -type f -exec chmod 640 {} \;

# Configurar o VirtualHost para apontar para /public
RUN echo '<VirtualHost *:80>\n\
    DocumentRoot /var/www/html/public\n\
    <Directory /var/www/html/public>\n\
        AllowOverride All\n\
        Require all granted\n\
    </Directory>\n\
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# Criar link simbólico da pasta files para o local correto
RUN ln -s /var/lib/glpi/files /var/www/html/public/files

# Criar config_path.php corretamente
RUN echo "<?php define('GLPI_VAR_DIR', '/var/lib/glpi/files');" > /var/www/html/public/config/config_path.php

# Ajustar permissões finais após tudo configurado
RUN chown -R www-data:www-data /var/www/html /var/lib/glpi \
 && chmod -R 750 /var/lib/glpi \
 && chmod -R 755 /var/www/html \
 && find /var/lib/glpi -type f -exec chmod 640 {} \; \
 && find /var/www/html -type f -exec chmod 644 {} \;

EXPOSE 80
