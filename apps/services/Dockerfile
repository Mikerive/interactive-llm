FROM node:18 AS builder

WORKDIR /usr/src/app

# Install pnpm and workspace dependencies (dev deps required for build)
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN corepack enable && corepack prepare pnpm@latest --activate && pnpm install --shamefully-hoist

# Copy only the services app and build it
COPY apps/services ./apps/services
WORKDIR /usr/src/app/apps/services

# Build using tsc directly (services has no build script)
RUN npx tsc -p tsconfig.json

FROM node:18-alpine AS runtime

WORKDIR /usr/src/app

# Install only production dependencies
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && corepack prepare pnpm@latest --activate && pnpm install --prod --shamefully-hoist

# Copy compiled output from builder
COPY --from=builder /usr/src/app/apps/services/dist ./dist

# Expose runtime port
EXPOSE 8484

# Run compiled server entrypoint (adjust if your build outputs a different filename)
CMD ["node", "dist/server.mjs"]