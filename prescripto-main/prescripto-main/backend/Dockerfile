# Node backend image
FROM node:20-alpine

WORKDIR /app

# Install dependencies first for better caching
COPY package*.json ./
RUN npm ci --only=production

# Copy source code
COPY . .

# Rebuild bcrypt safely (optional but safer)
RUN npm rebuild bcrypt --build-from-source || true


# Environment and port
ENV PORT=4000
EXPOSE 4000

# Ensure the server binds to 0.0.0.0 (Express listens on all interfaces by default)
CMD ["npm", "start"]

