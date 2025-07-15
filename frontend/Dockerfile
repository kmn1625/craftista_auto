# Dockerfile for Express + EJS App (No build step needed)
FROM node:18-alpine

WORKDIR /app

COPY . .

RUN npm install

EXPOSE 3000

CMD ["npm", "start"]
