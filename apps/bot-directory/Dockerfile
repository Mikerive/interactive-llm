FROM node:18 AS builder

WORKDIR /usr/src/app

# Install pnpm and workspace dependencies (dev deps required for build)
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN corepack enable && corepack prepare pnpm@latest --activate && pnpm install --shamefully-hoist

# Copy only the bot-directory app and build (tsc)
COPY apps/bot-directory ./apps/bot-directory
WORKDIR /usr/src/app/apps/bot-directory
RUN npx tsc -p tsconfig.json

FROM node:18-alpine AS runtime

WORKDIR /usr/src/app/apps/bot-directory

# Install production dependencies only
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && corepack prepare pnpm@latest --activate && pnpm install --prod --shamefully-hoist

# Copy compiled output from builder
COPY --from=builder /usr/src/app/apps/bot-directory/dist ./dist

EXPOSE 8585

# Run compiled server (adjust filename if your build emits a different file)
CMD ["node", "dist/server.js"]