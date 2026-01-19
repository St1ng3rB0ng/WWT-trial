# Spring Boot Microservices Test Task

Two microservices: Service A handles authentication and calls Service B for text transformation.

## Architecture

- Service A: Authentication service with JWT
- Service B: Text transformation service (internal only)
- PostgreSQL: Stores users and processing logs

## Requirements

- Docker and Docker Compose
- curl for testing

## Quick Start

Start all services:

```bash
docker compose up -d --build
```

Wait about 30 seconds for services to initialize.

Check status:

```bash
docker compose ps
```

## Testing

Run automated tests:

```bash
chmod +x test.sh
./test.sh
```

Or test manually:

### 1. Register user

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"user@test.com\",\"password\":\"pass123\"}"
```

Response:
```json
{"token":"eyJhbGciOiJIUzM4NCJ9..."}
```

### 2. Login

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"user@test.com\",\"password\":\"pass123\"}"
```

Response:
```json
{"token":"eyJhbGciOiJIUzM4NCJ9..."}
```

### 3. Process text

Replace YOUR_TOKEN with actual token from login:

```bash
curl -X POST http://localhost:8080/api/process \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"text\":\"hello world\"}"
```

Response:
```json
{"result":"DLROW OLLEH [TRANSFORMED]"}
```

## How it works

1. User registers or logs in to Service A
2. Service A returns JWT token
3. User sends process request with token to Service A
4. Service A validates token
5. Service A calls Service B with internal token
6. Service B transforms text and returns result
7. Service A saves log to database
8. Service A returns result to user

## Database Schema

users table:
- id (UUID)
- email (unique)
- password_hash

processing_log table:
- id (UUID)
- user_id (UUID)
- input_text (text)
- output_text (text)
- created_at (timestamp)

## Commands

View logs:
```bash
docker compose logs -f
```

Stop services:
```bash
docker compose down
```

Restart:
```bash
docker compose restart
```

Remove all data:
```bash
docker compose down -v
```

## Environment Variables

PostgreSQL:
- POSTGRES_DB: app_db
- POSTGRES_USER: user
- POSTGRES_PASSWORD: password

Service A:
- SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/app_db
- SERVICE_B_URL: http://data-api:8081
- JWT_SECRET: signing key for JWT tokens
- INTERNAL_API_TOKEN: shared secret for Service B

Service B:
- INTERNAL_API_TOKEN: shared secret for validation

## Security

- Passwords hashed with BCrypt
- JWT tokens expire after 24 hours
- Service B accessible only from Service A via internal Docker network
- Internal token required for Service A to Service B communication

## Tech Stack

- Spring Boot 4.0.1
- Java 17
- PostgreSQL 15
- Docker