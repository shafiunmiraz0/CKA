### Simple nginx image that serves the repository files with directory browsing.
# This avoids running the site generator and lets you browse/copy raw files directly.

FROM nginx:stable-alpine
WORKDIR /usr/share/nginx/html

# Copy repository into nginx webroot. .dockerignore will exclude unwanted files.
COPY . /usr/share/nginx/html/

# Use a custom nginx config that enables autoindex and serves markdown as text
COPY /Containerization/nginx-autoindex.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
