FROM nginx:alpine
COPY index.html dashboard.html presentation.html balance-simulation.html /usr/share/nginx/html/
COPY data/ /usr/share/nginx/html/data/
