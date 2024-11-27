# Use Node.js image for building
FROM node:18 AS build

# Set the working directory in the container
WORKDIR /app

# Copy package.json and package-lock.json
COPY package.json package-lock.json ./

# Install frontend dependencies
RUN npm install

# Copy the rest of the frontend source code
COPY . .

# Build the Vite app
RUN npm run build

# Use Nginx to serve the frontend
FROM nginx:alpine

# Copy the Vite build output to Nginx's public directory
COPY --from=build /app/dist /usr/share/nginx/html

# Expose the port Nginx runs on
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
