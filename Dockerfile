FROM node:lts-alpine as base
RUN apk add libc6-compat gcompat curl 
RUN curl -f https://get.pnpm.io/v6.16.js | node - add --global pnpm

FROM base 
WORKDIR /ns-ecommerce
COPY . ./
RUN pnpm install --frozen-lockfile
RUN pnpm build

WORKDIR /ns-ecommerce/site
EXPOSE 3000
ENTRYPOINT ["pnpm", "dev"]