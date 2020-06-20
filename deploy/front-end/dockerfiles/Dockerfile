FROM node:lts-alpine

# install a simple server http to serve a static content
RUN npm install -g http-server

# Define folder 'app' as work directory
WORKDIR /app

# copy 'package.json' and 'package-lock.json' (if available)
COPY front-end/package*.json ./

# install all dependancies of the project
RUN npm install

# copy files and folders of the project in workdir
COPY front-end/ .

# remove test files
RUN rm -f .env.local
RUN rm -rf tests/
RUN rm -rf tests_mock_app/

# build app for production by minifying it
RUN npm run build

EXPOSE 8080
CMD [ "http-server", "dist" ]