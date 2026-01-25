# Build ccusage from upstream repo with all dependencies bundled

ARG CCUSAGE_VERSION=main

########## Builder ##########
FROM node:22-bullseye-slim AS builder

ARG CCUSAGE_VERSION
ENV DEBIAN_FRONTEND=noninteractive
ENV BUN_INSTALL=/root/.bun
ENV PATH="${BUN_INSTALL}/bin:/root/.local/share/pnpm:${PATH}"

# system deps for git, curl (bun installer), unzip (bun), and corepack
RUN apt-get update \
  && apt-get install -y --no-install-recommends git curl ca-certificates unzip \
  && rm -rf /var/lib/apt/lists/*

# pnpm (matching repo spec) and bun for schema generation
RUN corepack enable \
  && corepack prepare pnpm@10.24.0 --activate
RUN curl -fsSL https://bun.sh/install | bash

WORKDIR /app
RUN git clone --depth 1 --branch "${CCUSAGE_VERSION}" https://github.com/ryoppippi/ccusage.git .

# Install deps and build just the ccusage workspace
RUN pnpm install --frozen-lockfile
RUN pnpm --filter ccusage... build

# Keep only production deps for smaller runtime layer
RUN CI=true pnpm prune --prod --ignore-scripts

########## Runtime ##########
FROM node:22-bullseye-slim AS runtime

ENV NODE_ENV=production
WORKDIR /opt/ccusage/apps/ccusage

# Copy built app and production dependencies
COPY --from=builder /app/node_modules /opt/ccusage/node_modules
COPY --from=builder /app/apps/ccusage /opt/ccusage/apps/ccusage

# Default entrypoint runs the CLI (reads JSONL files from mounted path)
ENTRYPOINT ["node", "./dist/index.js"]
CMD ["--help"]
