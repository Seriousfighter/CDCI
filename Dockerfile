# Stage 1: Build dependencies
FROM composer:2.6 as vendor

WORKDIR /app

# Copy everything needed for composer
COPY . .

RUN composer install \
    --no-interaction \
    --no-plugins \
    --no-scripts \
    --no-dev \
    --prefer-dist



# Stage 2: Build frontend assets
FROM node:18-alpine as frontend

WORKDIR /app

# Copy necessary files including vendor directory
COPY --from=vendor /app/vendor/ ./vendor/
COPY package.json package-lock.json vite.config.js ./
COPY resources/ ./resources/
COPY public/ ./public/

RUN npm ci && npm run build

# Stage 3: Final image
FROM php:8.2-fpm-alpine

WORKDIR /var/www/html

# Install dependencies
RUN apk add --no-cache \
    zip \
    unzip \
    libpng \
    libpng-dev \
    libzip-dev \
    jpegoptim \
    optipng \
    pngquant \
    gifsicle \
    freetype \
    freetype-dev \
    libjpeg-turbo \
    libjpeg-turbo-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_mysql zip gd

# Copy application files
COPY . .
COPY --from=vendor /app/vendor/ ./vendor/
COPY --from=frontend /app/public/build ./public/build

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage

    # Create storage symlink
RUN php artisan storage:link

# Configure PHP - REMOVED THE PROBLEMATIC LINE
# COPY php.ini /usr/local/etc/php/conf.d/app.ini

EXPOSE 9000

CMD ["php-fpm"]