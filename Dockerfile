FROM nginx:alpine
COPY index.html dashboard.html /usr/share/nginx/html/
COPY data/ /usr/share/nginx/html/data/
