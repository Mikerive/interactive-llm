FROM node:18 AS builder

WORKDIR /usr/src/app

# Install pnpm and workspace dependencies
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN corepack enable && corepack prepare pnpm@latest --activate && pnpm install --shamefully-hoist

# Copy only the novel-builder app and build it
COPY apps/novel-builder ./apps/novel-builder
WORKDIR /usr/src/app/apps/novel-builder
RUN pnpm --filter ./apps/novel-builder run build

FROM nginx:stable-alpine AS runtime

# Copy built static files into nginx html dir
COPY --from=builder /usr/src/app/apps/novel-builder/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]