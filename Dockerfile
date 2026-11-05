# ==========================================
# STAGE 1: BUILD
# Maven + JDK 17
# ==========================================
FROM maven:3.9.9-eclipse-temurin-17 AS build
WORKDIR /app
# Copy Maven configuration
COPY pom.xml .
# Copy source code
COPY src ./src

# Download dependencies
RUN mvn dependency:go-offline -B
# Compile Selenium TestNG test classes
RUN mvn test-compile
# ==========================================
# STAGE 2: RUNTIME
# Maven + JDK 17 + Chromium
# ==========================================
FROM maven:3.9.9-eclipse-temurin-17
WORKDIR /app
# Install Chromium
RUN apt-get update && apt-get install -y \
    chromium \
    && rm -rf /var/lib/apt/lists/*
# Copy project files
COPY --from=build /app /app
# Chromium configuration
ENV CHROME_BIN=/usr/bin/chromium
# Execute Selenium tests
CMD ["mvn", "test"]

Step 5: Extend the GitHub Actions Workflow File
Modify your .github/workflows/selenium-tests.yml file to include your Docker authentication, building steps, and target deployment push tasks:
name: Selenium Java Tests & Docker Publish
name: Selenium TestNG CI/CD Pipelin
# Trigger workflow on push and pull requests to main
on:
  push:
    branches: ["main"]

  pull_request:
    branches: ["main"]
jobs:
  # JOB 1: Execute Selenium TestNG Automation Tests
  selenium-test:
    runs-on: ubuntu-latest
    steps:
      # Step 1: Checkout source code
      - name: Checkout source code
        uses: actions/checkout@v4
      # Step 2: Set up JDK 17
      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'
          cache: maven
      # Step 3: Set up Chrome
      - name: Set up Chrome
        uses: browser-actions/setup-chrome@v1
      # Step 4: Verify Java and Chrome
      - name: Verify Java and Chrome
        run: |
          java -version
          google-chrome --version
      # Step 5: Run Selenium tests
      - name: Run Selenium tests
        run: mvn clean test
  # JOB 2: Build and Publish Docker Image
  # Runs only after successful Selenium tests
  build-and-publish-docker:
    needs: selenium-test
    runs-on: ubuntu-latest
    # Publish only on push events, not pull requests
    if: github.event_name == 'push'
    steps:
      # Step 1: Checkout source code
      - name: Checkout source code
        uses: actions/checkout@v4
      # Step 2: Login to Docker Hub
      - name: Log in to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
      # Step 3: Set up Docker Buildx
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      # Step 4: Build and Push Docker Image
      - name: Build and Push Docker Image
        uses: docker/build-push-action@v6
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: |
            ${{ secrets.DOCKERHUB_USERNAME }}/selenium-testng-automation:latest
            ${{ secrets.DOCKERHUB_USERNAME }}/selenium-testng-automation:${{ github.sha }}
