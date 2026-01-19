#!/bin/bash

set -e

echo "Starting tests..."
echo ""

BASE_URL="http://localhost:8080"
EMAIL="test_$(date +%s)@example.com"
PASSWORD="test123"

extract_token() {
    echo "$1" | grep -o '"token":"[^"]*"' | cut -d'"' -f4
}

echo "Test 1: Register user"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

TOKEN=$(extract_token "$RESPONSE")

if [ -z "$TOKEN" ]; then
    echo "Failed to register user"
    exit 1
fi

echo "OK - User registered"
echo ""

echo "Test 2: Login"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

TOKEN=$(extract_token "$RESPONSE")

if [ -z "$TOKEN" ]; then
    echo "Failed to login"
    exit 1
fi

echo "OK - Login successful"
echo ""

echo "Test 3: Process text"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/process" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text":"hello"}')

RESULT=$(echo "$RESPONSE" | grep -o '"result":"[^"]*"' | cut -d'"' -f4)

if [ -z "$RESULT" ]; then
    echo "Failed to process text"
    exit 1
fi

echo "OK - Text processed: $RESULT"
echo ""

echo "Test 4: Unauthorized request"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/process" \
  -H "Content-Type: application/json" \
  -d '{"text":"test"}')

if [ "$STATUS" -ne 403 ]; then
    echo "Failed - Should reject unauthorized request"
    exit 1
fi

echo "OK - Unauthorized request rejected"
echo ""

echo "All tests passed"