FROM node:10-stretch

RUN mkdir -p /usr/src/myapp
WORKDIR /usr/src/myapp

# install dependencies
COPY package.json .
COPY yarn.lock .
RUN yarn install

# install the app
COPY . .
RUN yarn install

# run the app
ENTRYPOINT [ "yarn" ]
CMD [ "run", "start" ]
