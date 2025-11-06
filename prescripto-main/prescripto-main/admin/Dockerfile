FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN chmod +x node_modules/.bin/vite
RUN npm run build

FROM node:20-alpine AS runtime
WORKDIR /app
COPY --from=build /app/dist ./dist
COPY package*.json ./
RUN npm install

EXPOSE 5174
CMD ["npm", "run", "preview", "--", "--host", "0.0.0.0", "--port", "5174"]



