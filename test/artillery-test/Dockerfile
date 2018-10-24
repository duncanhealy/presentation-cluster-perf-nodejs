# FROM node:10.10.0-alpine
# WORKDIR /artillery
# ADD package.json /artillery
# ADD index.js /artillery
# RUN npm install

# CMD ["npm", "start"]
FROM alpine:latest

ENV ARTILLERY_VERSION 1.6.0-2

RUN apk --update --no-cache add \
	nodejs-current \
	nodejs-current-npm

RUN npm install -g artillery@${ARTILLERY_VERSION}

ENTRYPOINT ["artillery"]
CMD ["--help"]