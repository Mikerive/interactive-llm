FROM miku/node-pnpm-builder:latest AS builder

WORKDIR /usr/src/app

# Install pnpm and workspace dependencies
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN corepack enable && corepack prepare pnpm@latest --activate && pnpm install --shamefully-hoist

# Copy only the bot-translator app and build it
COPY apps/bot-translator ./apps/bot-translator
WORKDIR /usr/src/app/apps/bot-translator
# Build entire workspace once (so all frontends are built)
RUN pnpm -w run build

FROM nginx:stable-alpine AS runtime

# Copy built static files into nginx html dir
COPY --from=builder /usr/src/app/apps/bot-translator/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]