FROM node:bookworm
RUN apt-get update && apt-get install -y sudo && npm install --global mime
RUN userdel --force --remove node || true
RUN adduser --system --uid 1001 node
ADD app.js /app.js
ENV NODE_PATH /usr/local/lib/node_modules
EXPOSE 8000
ENTRYPOINT ["sudo", "-u", "node", "--preserve-env=NODE_PATH", "node", "app.js"]
