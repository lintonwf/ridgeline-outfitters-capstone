FROM node:26-alpine

WORKDIR /app
COPY package.json ./
COPY server.js ./

ENV PORT=80
EXPOSE 80

USER node
CMD ["node", "server.js"]
