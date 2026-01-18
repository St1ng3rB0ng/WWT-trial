# Two Spring Boot Services with PostgreSQL and Docker

Two microservices that communicate with each other: Service A handles authentication and calls Service B for text
transformation.

## Architecture

- **Service A (auth-api)**: Authentication service with JWT, exposes `/api/auth/register`, `/api/auth/login`, and
  `/api/process`
- **Service B (data-api)**: Text transformation service, accepts requests only from Service A via internal token
- **PostgreSQL**: Stores users and processing logs

## Requirements

- Docker and Docker Compose
- curl (for testing)

## Quick Start

### Build and run

```bash
docker compose up -d --build
```

Wait 30-60 seconds for services to start.

### Check status

```bash
docker compose ps
```

You should see three running containers: postgres_db, auth_api, data_api.

## API Endpoints

### Service A (port 8080)

**Register user**

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"test11@example.com\",\"password\":\"password123\"}" \
  -w "\nHTTP Status: %{http_code}\n"
```

Response (201):

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9..."
}
```

**Login**

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"test11@example.com\",\"password\":\"password123\"}" \
  -w "\nHTTP Status: %{http_code}\n"
```

Response (200):

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9..."
}
```

**Process text** (requires JWT token)

```bash
# Replace YOUR_TOKEN with the token from register/login
# for example: eyJhbGciOiJIUzM4NCJ9.eyJ1c2VySWQiOiI3ZWI2OTU0Mi1hOTIzLTQ5YTYtYmIwMC05ZDg1YzM2YTFjNWYiLCJzdWIiOiJ0ZXN0MTFAZXhhbXBsZS5jb20iLCJpYXQiOjE3Njg3NDAwNDgsImV4cCI6MTc2ODgyNjQ0OH0.EfcN-WnmLWFI-1xLE0bbI4HmwgtHd5CtPxZQKO4vKIde7HQMGd_EUG2lItHeoSQL
curl -X POST http://localhost:8080/api/process \
  -H "Authorization: Bearer eyJhbGciOiJIUzM4NCJ9.eyJ1c2VySWQiOiI3ZWI2OTU0Mi1hOTIzLTQ5YTYtYmIwMC05ZDg1YzM2YTFjNWYiLCJzdWIiOiJ0ZXN0MTFAZXhhbXBsZS5jb20iLCJpYXQiOjE3Njg3NDAwNDgsImV4cCI6MTc2ODgyNjQ0OH0.EfcN-WnmLWFI-1xLE0bbI4HmwgtHd5CtPxZQKO4vKIde7HQMGd_EUG2lItHeoSQL" \
  -H "Content-Type: application/json" \
  -d "{\"text\":\"hello world\"}" \
  -w "\nHTTP Status: %{http_code}\n"
```

Response (200):

```json
{
  "result": "DLROW OLLEH [TRANSFORMED]"
}
```

### Service B (port 8081)

Service B only accepts requests with valid X-Internal-Token header. Direct access without token returns 403.

Transform text (with internal token)

```bash
curl -X POST http://localhost:8081/api/transform \
  -H "X-Internal-Token: secret-key-123" \
  -H "Content-Type: application/json" \
  -d "{\"text\":\"hello\"}" \
  -w "\nHTTP Status: %{http_code}\n"
```

Response (200):

```json
{
  "result": "OLLEH [TRANSFORMED]"
}
```

Without token (403):

```bash
curl -X POST http://localhost:8081/api/transform \
  -H "Content-Type: application/json" \
  -d "{\"text\":\"hello\"}" \
  -w "\nHTTP Status: %{http_code}\n"
```

Response (403):

```json
{
  "error": "Forbidden: Invalid or missing internal token"
}
```

## Complete Example

```bash
# 1. Start services
docker compose up -d --build
sleep 30

# 2. Register user and save response
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"user@test.com\",\"password\":\"pass123\"}" \
  -w "\nHTTP Status: %{http_code}\n"

# Copy the token from response

# 3. Process text (replace YOUR_TOKEN)
curl -X POST http://localhost:8080/api/process \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"text\":\"Spring Boot\"}" \
  -w "\nHTTP Status: %{http_code}\n"

# Expected: {"result":"TOOB GNIRPS [TRANSFORMED]"}
# HTTP Status: 200
```

## Automated Testing

```bash
chmod +x test.sh
./test.sh
```

## Useful Commands

```bash
# View logs
docker compose logs -f

# View logs for specific service
docker compose logs -f auth-api

# Stop services
docker compose down

# Stop and remove volumes
docker compose down -v

# Restart services
docker compose restart
```

## Troubleshooting

**Services not starting**

```bash
docker compose logs
docker compose down -v
docker compose up -d --build
```

**Database connection error**

```bash
# Wait for PostgreSQL to be ready
docker compose exec postgres pg_isready -U user -d app_db

# Restart services
docker compose restart
```

## Technical Details

- Spring Boot 3.2.1
- Java 17
- PostgreSQL 15
- BCrypt password hashing
- Docker 