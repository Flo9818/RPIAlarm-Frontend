FROM nginx:stable

RUN apt-get update && apt-get install curl sudo gnupg gnupg2 gnupg1 -y

RUN curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -

RUN apt-get install nodejs npm -y

COPY package.json package-lock.json ./

RUN npm set progress=false && npm config set depth 0 && npm cache clean --force

## Storing node modules on a separate layer will prevent unnecessary npm installs at each build
RUN npm i && mkdir /ng-app && cp -R ./node_modules ./ng-app

WORKDIR /ng-app

COPY . .

## Build the angular app in production mode and store the artifacts in dist folder
RUN $(npm bin)/ng build --prod --aot --output-path dist


## Copy our default nginx config
COPY nginx/default.conf /etc/nginx/conf.d/

## Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

## From 'builder' stage copy over the artifacts in dist folder to default nginx public folder
RUN cp dist/* /usr/share/nginx/html

RUN chmod g+rwx /var/cache/nginx /var/run /var/log/nginx

RUN sed -i.bak 's/listen\(.*\)80;/listen 8080;/' /etc/nginx/conf.d/default.conf

EXPOSE 8080

RUN sed -i.bak 's/^user/#user/' /etc/nginx/nginx.conf

CMD ["nginx", "-g", "daemon off;"]