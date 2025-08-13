FROM node:18
LABEL miku.builder="true"

WORKDIR /usr/src/builder

# Prepare corepack and pnpm (pin to the repo's pnpm version)
RUN corepack enable && corepack prepare pnpm@10.14.0 --activate

ENV PATH=/usr/src/builder/node_modules/.bin:$PATH

# This image prepares pnpm/corepack so per-app Dockerfiles can use it faster.
# Build & push example:
# docker build -t miku/node-pnpm-builder:latest -f docker/builder-base/Dockerfile .