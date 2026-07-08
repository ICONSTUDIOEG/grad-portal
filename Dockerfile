FROM nginx:alpine
COPY index.html dashboard.html presentation.html /usr/share/nginx/html/
COPY data/ /usr/share/nginx/html/data/
