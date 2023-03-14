# syntax=docker/dockerfile:1

FROM node:lts-alpine AS base
RUN apk add libc6-compat gcompat coreutils
RUN npm i -g pnpm

FROM base AS dependencies
WORKDIR /app
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY packages ./packages
COPY site ./site
RUN mkdir -p /root/.local/share/pnpm
RUN --mount=type=cache,target=/pnpm-cache cp -r /pnpm-cache/* /root/.local/share/pnpm/
RUN pnpm fetch
RUN pnpm install -r --offline
RUN --mount=type=cache,target=/pnpm-cache cp -r /root/.local/share/pnpm/* /pnpm-cache/

FROM base AS build
WORKDIR /app
COPY . .
COPY --from=dependencies /app/node_modules ./node_modules
COPY --from=dependencies /app/packages ./packages
COPY --from=dependencies /app/site ./site
RUN --mount=type=cache,target=/app/node_modules/.cache/turbo pnpm build

FROM base AS runner
WORKDIR /app
COPY --from=build /app/site ./site
COPY --from=build /app/packages ./packages
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/turbo.json ./turbo.json
COPY --from=build /app/pnpm-lock.yaml ./pnpm-lock.yaml
COPY --from=build /app/pnpm-workspace.yaml ./pnpm-workspace.yaml

EXPOSE 3000
ENTRYPOINT ["pnpm", "dev"]
