FROM node:10.10.0-alpine
#FROM keymetrics/pm2-docker-alpine:latest
ENV PORT 80
ADD . /app
WORKDIR /app
RUN npm install
CMD ["npm", "start"]
