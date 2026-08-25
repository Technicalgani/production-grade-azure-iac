FROM node:22-alpine

WORKDIR /app

COPY package*.json ./

RUN npm ci --omit=dev

COPY . .

RUN addgroup -S nodeapp && \
    adduser -S -u 10001 -G nodeapp nodeapp && \
    chown -R 10001:10001 /app

USER 10001

EXPOSE 3000

CMD ["node", "src/server.js"]