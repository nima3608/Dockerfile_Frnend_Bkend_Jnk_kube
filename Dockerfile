# Stage 1: Backend build
FROM node:14-alpine AS backend
WORKDIR /app/backend
COPY backend/package*.json ./
RUN npm install
COPY backend/ .

# Stage 2: Frontend build
FROM node:14-alpine AS frontend
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm install
COPY frontend/ .
RUN npm run build

# Stage 3: Jenkins
FROM jenkins/jenkins:lts AS jenkins

USER root
RUN apt-get update && apt-get install -y \
    docker.io \
    curl \
    git \
    && apt-get clean

# Install Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

ENV JENKINS_HOME /var/jenkins_home
RUN mkdir -p $JENKINS_HOME
VOLUME $JENKINS_HOME

# Stage 4: Final image
FROM openjdk:8-jre-alpine

WORKDIR /app

# Copy backend and frontend from previous stages
COPY --from=backend /app/backend /app/backend
#COPY --from=frontend /app/frontend/build /app/frontend/build

# Copy Jenkins files
COPY --from=jenkins /usr/share/jenkins /usr/share/jenkins
COPY --from=jenkins /usr/local/bin/docker-compose /usr/local/bin/docker-compose

EXPOSE 8080 3000 5000

CMD ["sh", "-c", "cd /app/backend && npm start & serve -s /app/frontend/build & java -Duser.home=$JENKINS_HOME -jar /usr/share/jenkins/jenkins.war"]
