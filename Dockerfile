# FROM node:6-stretch
FROM node:18.20.7

RUN mkdir /usr/src/goof
RUN mkdir /tmp/extracted_files
COPY . /usr/src/goof
WORKDIR /usr/src/goof

RUN npm install
EXPOSE 3001
EXPOSE 9229
USER node
ENTRYPOINT ["npm", "start"]
