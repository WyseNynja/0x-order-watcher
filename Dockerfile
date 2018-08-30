FROM node:8

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied
# where available (npm@5+)
COPY package*.json ./
COPY .env.example .env

RUN npm install
# If you are building your code for production
# RUN npm install --only=production

# Bundle app source
COPY . .

EXPOSE 3000
CMD [ "npm", "start" ]

# Environment Variables
ENV PROVIDER 'http://localhost:8545'
ENV NETWORK_ID 42
ENV PORT 3000
ENV RELAYER 'http://localhost:8080/api/0x/v0/order/'
