# ---- build stage ----
FROM public.ecr.aws/docker/library/node:20-alpine AS build
WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# ---- runtime stage (nginx) ----
FROM public.ecr.aws/docker/library/nginx:1.27-alpine

# Vite SPA routing support (optional but recommended)
COPY ./nginx.conf /etc/nginx/conf.d/default.conf

# Copy built assets
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
