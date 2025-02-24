FROM node:19-alpine AS build

RUN addgroup -S app && adduser -S app -G app
RUN mkdir /app && chown app:app /app

RUN apk add --update --no-cache git

USER app

WORKDIR /app

COPY ./app/package.json ./
COPY ./app/tsconfig.json ./

RUN npm config set registry https://registry.npmmirror.com
RUN npm install

COPY ./app/craco.config.js ./craco.config.js
COPY ./app/public ./public
COPY ./app/src ./src

ENV NODE_ENV=production
ENV REACT_APP_AUTH_PROVIDER=local
ENV ENABLE_SERVER_COMPLETION=1

RUN npm run build

FROM node:19-alpine AS server

RUN addgroup -S app && adduser -S app -G app

WORKDIR /app

COPY ./server/package.json ./
COPY ./server/tsconfig.json ./

RUN apk add --update --no-cache python3 py3-pip make g++ git

ENV ENABLE_SERVER_COMPLETION=1

RUN npm config set registry https://registry.npmmirror.com
RUN npm install

COPY ./server/src ./src

RUN npm config set registry https://registry.npmmirror.com
RUN CI=true sh -c "cd /app && mkdir data && npm run start && rm -rf data"

COPY --from=build /app/build /app/public

LABEL org.opencontainers.image.source="https://github.com/cogentapps/chat-with-gpt"
ENV PORT 3000

CMD ["npm", "run", "start"]
