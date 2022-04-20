### BASE
FROM node:16-alpine AS base

RUN \
  # Add our own user and group to avoid permission problems
  addgroup -g 131337 app \
  && adduser -u 131337 -G app -s /bin/sh -h /app -D app \
  # Create directories for application
  && mkdir -p /app \
  && mkdir -p /github
# Set the working directory
WORKDIR /app
# Copy project specification and dependencies lock files
COPY package.json package-lock.json ./


### DEPENDENCIES
FROM base AS dependencies
RUN \
  # Install Node.js dependencies (only production)
  npm ci --only=production --ignore-scripts \
  # Backup production dependencies aside
  && cp -R ./node_modules /tmp/node_modules \
  # Install ALL Node.js dependencies
  && npm ci --ignore-scripts \
  # Backup development dependencies aside
  && mv ./node_modules /tmp/node_modules_dev


### Build
FROM base AS builder
COPY --from=dependencies /tmp/node_modules_dev ./node_modules
# Copy app sources
COPY . .
RUN \
  # Build app
  npm run build \
  # Backup development dependencies aside
  && mv ./dist /tmp/dist


### RELEASE
FROM base AS release
# Copy development dependencies if --build-arg DEBUG=1, or production dependencies
ARG DEBUG
COPY --from=dependencies /tmp/node_modules${DEBUG:+_dev} ./node_modules
COPY --from=builder /tmp/dist ./dist
# Copy app sources
COPY . .
# Change permissions for files and directories
RUN \
  chown -R app:app /app && chmod g+s /app \
  && chown -R app:app /github && chmod g+s /github
# Set NODE_ENV to 'development' if --build-arg DEBUG=1, or 'production'
ENV NODE_ENV=${DEBUG:+development}
ENV NODE_ENV=${NODE_ENV:-production}
# Use non-root user
USER app:app
# Run
CMD [ "node", "dist/index.js" ]
