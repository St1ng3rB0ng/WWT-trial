#!/bin/bash

# Automated test script for the microservices
# Requirements: curl (jq optional - using grep/sed fallback)

set -e

echo "=================================="
echo "Starting Automated Tests"
echo "=================================="
echo ""

BASE_URL_A="http://localhost:8080"
BASE_URL_B="http://localhost:8081"
EMAIL="test_$(date +%s)@example.com"
PASSWORD="test123"
INTERNAL_TOKEN="secret-key-123"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper function to print test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
        exit 1
    fi
}

# Helper function to extract JSON value (works without jq)
extract_json_value() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -o "\"$key\":\"[^\"]*\"" | sed "s/\"$key\":\"\([^\"]*\)\"/\1/"
}

# Wait for services to be ready
echo "${YELLOW}Waiting for services to be ready...${NC}"
sleep 5

# Test 1: Register user
echo ""
echo "Test 1: Register new user"
echo "=========================="
REGISTER_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL_A/api/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

HTTP_CODE=$(echo "$REGISTER_RESPONSE" | tail -n1)
REGISTER_BODY=$(echo "$REGISTER_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" -eq 201 ]; then
    TOKEN=$(extract_json_value "$REGISTER_BODY" "token")
    print_result 0 "User registered successfully"
    echo "   Email: $EMAIL"
    echo "   Token: ${TOKEN:0:50}..."
else
    print_result 1 "Failed to register user (HTTP $HTTP_CODE)"
fi

# Test 2: Login with registered user
echo ""
echo "Test 2: Login with registered user"
echo "==================================="
LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL_A/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

HTTP_CODE=$(echo "$LOGIN_RESPONSE" | tail -n1)
LOGIN_BODY=$(echo "$LOGIN_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" -eq 200 ]; then
    TOKEN=$(extract_json_value "$LOGIN_BODY" "token")
    print_result 0 "Login successful"
    echo "   Token: ${TOKEN:0:50}..."
else
    print_result 1 "Failed to login (HTTP $HTTP_CODE)"
fi

# Test 3: Login with wrong password
echo ""
echo "Test 3: Login with wrong password (should fail)"
echo "================================================"
WRONG_LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL_A/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"wrongpassword\"}")

HTTP_CODE=$(echo "$WRONG_LOGIN_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" -eq 401 ]; then
    print_result 0 "Correctly rejected wrong password"
else
    print_result 1 "Should have rejected wrong password (HTTP $HTTP_CODE)"
fi

# Test 4: Process text without authorization (should fail)
echo ""
echo "Test 4: Process text without authorization (should fail)"
echo "========================================================="
NO_AUTH_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL_A/api/process" \
  -H "Content-Type: application/json" \
  -d '{"text":"hello"}')

HTTP_CODE=$(echo "$NO_AUTH_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" -eq 401 ] || [ "$HTTP_CODE" -eq 403 ]; then
    print_result 0 "Correctly rejected unauthorized request"
else
    print_result 1 "Should have rejected unauthorized request (HTTP $HTTP_CODE)"
fi

# Test 5: Process text with authorization
echo ""
echo "Test 5: Process text with valid authorization"
echo "=============================================="
INPUT_TEXT="Hello Spring Boot"
PROCESS_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL_A/api/process" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"text\":\"$INPUT_TEXT\"}")

HTTP_CODE=$(echo "$PROCESS_RESPONSE" | tail -n1)
PROCESS_BODY=$(echo "$PROCESS_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" -eq 200 ]; then
    RESULT=$(extract_json_value "$PROCESS_BODY" "result")
    print_result 0 "Text processed successfully"
    echo "   Input:  $INPUT_TEXT"
    echo "   Output: $RESULT"
else
    print_result 1 "Failed to process text (HTTP $HTTP_CODE)"
fi

# Test 6: Call Service B directly without internal token (should fail)
echo ""
echo "Test 6: Call Service B without internal token (should fail)"
echo "============================================================"
NO_TOKEN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL_B/api/transform" \
  -H "Content-Type: application/json" \
  -d '{"text":"test"}')

HTTP_CODE=$(echo "$NO_TOKEN_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" -eq 403 ]; then
    print_result 0 "Service B correctly rejected request without internal token"
else
    print_result 1 "Service B should have rejected request without token (HTTP $HTTP_CODE)"
fi

# Test 7: Call Service B with invalid internal token (should fail)
echo ""
echo "Test 7: Call Service B with invalid internal token (should fail)"
echo "================================================================="
INVALID_TOKEN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL_B/api/transform" \
  -H "X-Internal-Token: wrong-token" \
  -H "Content-Type: application/json" \
  -d '{"text":"test"}')

HTTP_CODE=$(echo "$INVALID_TOKEN_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" -eq 403 ]; then
    print_result 0 "Service B correctly rejected request with invalid token"
else
    print_result 1 "Service B should have rejected request with invalid token (HTTP $HTTP_CODE)"
fi

# Test 8: Call Service B with valid internal token
echo ""
echo "Test 8: Call Service B with valid internal token"
echo "================================================="
VALID_TOKEN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL_B/api/transform" \
  -H "X-Internal-Token: $INTERNAL_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text":"test"}')

HTTP_CODE=$(echo "$VALID_TOKEN_RESPONSE" | tail -n1)
VALID_TOKEN_BODY=$(echo "$VALID_TOKEN_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" -eq 200 ]; then
    RESULT=$(extract_json_value "$VALID_TOKEN_BODY" "result")
    print_result 0 "Service B accepted request with valid token"
    echo "   Result: $RESULT"
else
    print_result 1 "Service B should have accepted request (HTTP $HTTP_CODE)"
fi

# Summary
echo ""
echo "=================================="
echo -e "${GREEN}All tests passed! ✓${NC}"
echo "=================================="
echo ""
echo "Summary:"
echo "  - User registration: OK"
echo "  - User login: OK"
echo "  - Authentication security: OK"
echo "  - Text processing: OK"
echo "  - Service B protection: OK"
echo "  - Internal token validation: OK"
echo ""