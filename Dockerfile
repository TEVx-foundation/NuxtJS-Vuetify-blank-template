FROM node
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["export", "SET", "NODE_OPTIONS=--openssl-legacy-provider", "&&", "yarn", "dev"]