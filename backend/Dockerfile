FROM node:22-alpine
WORKDIR /app
RUN corepack enable && corepack prepare pnpm@11.19.0 --activate
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --prod --frozen-lockfile --ignore-scripts
COPY *.mjs ./
ENV NODE_ENV=production HOST=0.0.0.0 QUOTA_FILE=/data/free-usage.json MONITORING_FILE=/data/market-monitors.json MONITORING_ENABLED=false
RUN mkdir /data && chown node:node /data
USER node
EXPOSE 8787
CMD ["node", "server.mjs"]
