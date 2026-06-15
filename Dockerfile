# Use updated nginx alpine image
FROM nginx:stable-alpine

# Update Alpine packages to latest security patches
RUN apk update && apk upgrade

# Remove default nginx page
RUN rm -rf /usr/share/nginx/html/*

# Copy frontend files
COPY . /usr/share/nginx/html

# Expose nginx port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]