# Base image using Node.js Alpine version 22
FROM node:22-alpine AS builder

# Set the working directory for the app
WORKDIR /app

# Copy package.json and pnpm-lock.yaml to install dependencies
COPY pnpm-lock.yaml ./
COPY pnpm-workspace.yaml ./
COPY packages/app-client/package.json packages/app-client/package.json
COPY packages/app-server/package.json packages/app-server/package.json

# Install pnpm
RUN npm install -g pnpm --ignore-scripts && pnpm install --frozen-lockfile --ignore-scripts

# Copy the entire app
COPY . .

# Build the apps
RUN pnpm --filter @enclosed/app-client run build && pnpm --filter @enclosed/app-server run build:node

# Production image 
FROM node:22-alpine

# Create a non-root user and group
RUN addgroup -S nonroot && adduser -S nonroot -G nonroot

WORKDIR /app

# Copy the built apps
COPY --from=builder /app/packages/app-client/dist ./public
COPY --from=builder /app/packages/app-server/dist-node/index.cjs ./index.cjs

# Change the owner of the app directory
RUN chown -R nonroot:nonroot /app

# Change the user to nonroot
USER nonroot

EXPOSE 8787

CMD ["node", "index.cjs"]