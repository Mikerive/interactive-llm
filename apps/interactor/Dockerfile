FROM miku/node-pnpm-builder:latest AS builder

WORKDIR /usr/src/app

# Install pnpm and dependencies (workspace)
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN corepack enable && corepack prepare pnpm@latest --activate && pnpm install --shamefully-hoist

# Copy full workspace so a single workspace build can run
COPY . .
WORKDIR /usr/src/app
# Build all workspace packages once (faster when using shared builder)
RUN pnpm -w run build

FROM nginx:stable-alpine AS runtime

# Copy built static files into nginx html dir
COPY --from=builder /usr/src/app/apps/interactor/dist /usr/share/nginx/html

# Expose nginx default port
EXPOSE 80

# Run nginx in foreground
CMD ["nginx", "-g", "daemon off;"]