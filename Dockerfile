# FROM maven:3.9-eclipse-temurin-21 AS build
# WORKDIR /app

# COPY pom.xml .
# COPY src ./src

# RUN mvn package -DskipTests

# FROM eclipse-temurin:21-jre
# WORKDIR /app

# COPY --from=build /app/target/backend.jar app.jar

# EXPOSE 8080

# ENTRYPOINT ["java", "-jar", "app.jar"]
FROM node:22-alpine AS build-stage
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN VITE_GRAPHQL_URI=__VITE_GRAPHQL_URI_PLACEHOLDER__ \
    VITE_SERVER_URI=__VITE_SERVER_URI_PLACEHOLDER__ \
    npm run build -- --mode production

FROM nginx:alpine AS production-stage
COPY nginx-custom.conf /etc/nginx/conf.d/default.conf
COPY --from=build-stage /app/dist /usr/share/nginx/html
COPY docker-entrypoint.sh /docker-entrypoint.d/40-replace-env.sh
RUN chmod +x /docker-entrypoint.d/40-replace-env.sh
EXPOSE 80
ENTRYPOINT ["/docker-entrypoint.sh"]