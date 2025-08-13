Build caching and shared builder image

This document describes the recommended setup to avoid redundant builds across multiple Docker images in this monorepo.

Overview
- We publish a small builder-base image that pre-configures corepack/pnpm.
- Each app Dockerfile uses [`docker/builder-base/Dockerfile`](docker/builder-base/Dockerfile:1) as the builder base so the `corepack prepare pnpm` step is pre-run.
- We use Docker BuildKit / buildx with a registry cache backend so layers can be reused cross-machine and in CI.

Benefits
- Avoids repeating expensive workspace dependency installs (pnpm install) per-image.
- Works well locally and in CI when you enable BuildKit / buildx caching (local or remote).
- Keeps per-service multi-stage Dockerfiles while reducing rebuild time.

What I changed in this repo
- Added builder base: [`docker/builder-base/Dockerfile`](docker/builder-base/Dockerfile:1).
- Updated per-app Dockerfiles to use the builder base (e.g. [`apps/interactor/Dockerfile`](apps/interactor/Dockerfile:1), [`apps/bot-translator/Dockerfile`](apps/bot-translator/Dockerfile:1), [`apps/novel-builder/Dockerfile`](apps/novel-builder/Dockerfile:1), [`apps/services/Dockerfile`](apps/services/Dockerfile:1), [`apps/bot-directory/Dockerfile`](apps/bot-directory/Dockerfile:1)).

High-level approach
1. Publish a small, stable builder base image with pnpm/corepack prepared.
   - This eliminates the repeated overhead of "corepack prepare pnpm" inside each builder stage.
2. Continue to use per-service multi-stage Dockerfiles (builder -> runtime) that COPY only the package and app sources they need.
3. Enable buildx registry-based layer caching to share and persist build layers across local builds and CI runs.

Example: builder base
- File: [`docker/builder-base/Dockerfile`](docker/builder-base/Dockerfile:1)
- Build & push (example registry):
  docker build -t registry.example.com/miku/node-pnpm-builder:latest -f docker/builder-base/Dockerfile .
  docker push registry.example.com/miku/node-pnpm-builder:latest

Per-app Dockerfile pattern (already applied)
- Each app Dockerfile uses:
  FROM registry.example.com/miku/node-pnpm-builder:latest AS builder
  COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
  RUN pnpm install --shamefully-hoist
  COPY apps/<app> ./apps/<app>
  WORKDIR /usr/src/app/apps/<app>
  RUN pnpm run build
  FROM nginx:stable-alpine AS runtime (for frontends)
  COPY --from=builder /usr/src/app/apps/<app>/dist /usr/share/nginx/html

BuildKit / buildx with registry cache (recommended)
- Create or use an existing buildx builder:
  docker buildx create --use --name miku-builder
- Example build command that reads/writes cache to a registry:
  docker buildx build \
    --platform linux/amd64 \
    --cache-from=type=registry,ref=registry.example.com/miku/build-cache:cache \
    --cache-to=type=registry,mode=max,ref=registry.example.com/miku/build-cache:cache \
    -t registry.example.com/miku/interactor:latest \
    -f apps/interactor/Dockerfile .

Notes:
- Use unique refs per repo/organization to avoid collisions (e.g., registry.example.com/miku/build-cache:cache).
- `--cache-to` with `mode=max` pushes more metadata so future builds benefit more.
- When using a private registry, ensure CI runners have credentials to push/read cache.

CI example (GitHub Actions snippet)
- Steps (conceptual):
  1) Set up QEMU & buildx (official actions)
  2) Login to the registry
  3) docker buildx build --cache-from=type=registry,ref=... --cache-to=type=registry,mode=max,ref=... --push -t registry.example.com/miku/<service>:${{ github.sha }} -f <service Dockerfile> .
- This both writes the image and updates the cache for later jobs.

Optional: local shared builder image (fast local dev)
- If you prefer not to use a remote cache, you can publish the small builder base image once and reference it locally as `miku/node-pnpm-builder:latest`.
- This avoids the repeated "corepack prepare" step locally but does not address layer caching for dependencies vs. build outputs across different services.

When this helps less
- If package manifest (package.json/pnpm-lock.yaml) changes frequently across the workspace, the dependency layer will be invalidated often; however separating the COPY of manifests from source still reduces the rebuild scope.
- Large build contexts slow build; ensure Dockerfiles COPY only what's necessary (we already COPY apps/<app> only).

Next steps I can take (pick one)
- A) Add a small Makefile / scripts in `scripts/` with buildx commands for each service (local scripts + CI-ready commands).
- B) Add a GitHub Actions workflow example that runs buildx and pushes cache + images.
- C) Stop here — you already have the updated Dockerfiles and builder base; I can wait for your CI registry credentials to wire caching.

If you want A or B, tell me which and I will add the files and CI examples (or implement both).