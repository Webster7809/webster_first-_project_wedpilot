# syntax=docker/dockerfile:1

# ── Build stage ───────────────────────────────────────────────────────────────
# Debian-slim rather than Alpine deliberately. bcrypt and mysql2 both ship
# native code; the prebuilt binaries they publish are glibc-linked, so on
# Alpine's musl they fall back to compiling from source — which needs a
# toolchain in the image and breaks in ways that only show up at runtime.
# The size difference after the runtime stage below is a few tens of MB.
FROM node:22-bookworm-slim AS build

WORKDIR /app

# Build toolchain for any dependency that has no prebuilt binary for this
# platform. It stays in this stage only — the runtime image never sees it.
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 make g++ \
    && rm -rf /var/lib/apt/lists/*

# Copied before the source so this layer is reused whenever dependencies are
# unchanged, which is most builds.
COPY package.json package-lock.json ./

# `npm ci` installs exactly the lockfile, failing if package.json disagrees —
# the property that makes an image reproducible. --omit=dev leaves nodemon out.
RUN npm ci --omit=dev

# ── Runtime stage ─────────────────────────────────────────────────────────────
FROM node:22-bookworm-slim AS runtime

ENV NODE_ENV=production

# dumb-init becomes PID 1. Without an init, Node runs as PID 1 itself, where
# it does not get default signal handlers — `docker stop` sends SIGTERM to a
# process that ignores it and the container is SIGKILLed ten seconds later,
# cutting in-flight requests. dumb-init also reaps orphaned children.
RUN apt-get update \
    && apt-get install -y --no-install-recommends dumb-init \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=build /app/node_modules ./node_modules
COPY . .

# The node images ship a non-root `node` user (uid 1000). Running as root
# inside the container means a container escape starts as root on the host.
# uploads/ is the one path the app writes to, so it needs to be owned by the
# user that will write it — the compose volume mounted here inherits this
# ownership on first creation.
RUN mkdir -p uploads && chown -R node:node /app
USER node

EXPOSE 3000

# Hits the app's own /health route, so the check exercises the real HTTP
# listener rather than merely confirming the process exists. Uses Node's
# built-in fetch (v18+) to avoid adding curl to the runtime image.
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD node -e "fetch('http://127.0.0.1:3000/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

ENTRYPOINT ["dumb-init", "--"]
# Applies any pending migration before the server starts — the only place
# this happens for a platform like Railway, which has no separate release
# step and runs this image with NODE_ENV=production, where server.js
# deliberately skips its own sequelize.sync(). Idempotent (see db/migrate.js),
# and migrate.js exits non-zero on failure, so `&&` refuses to boot the server
# against a schema that didn't actually update rather than serving traffic
# against columns the code assumes exist.
CMD ["sh", "-c", "node db/migrate.js && node server.js"]
