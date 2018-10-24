FROM node:10.10.0-alpine
#FROM keymetrics/pm2-docker-alpine:latest

ADD . /app
WORKDIR /app
RUN npm install
CMD ["npm", "start"]
