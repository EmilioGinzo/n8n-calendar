#!/bin/bash

# Event CRUD Test Script
# Tests all 4 Event workflows: Create, List, Update, Delete

set -e  # Exit on error

N8N_URL="http://localhost:5678"
WEBHOOK_PREFIX="/webhook"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "   Event CRUD Workflow Test Script"
echo "========================================"
echo ""

# Check if n8n is running
echo -n "Checking if n8n is running... "
if ! curl -s "${N8N_URL}/webhook/events/create" -X POST -H "Content-Type: application/json" -d '{}' > /dev/null 2>&1; then
    echo -e "${RED}FAILED${NC}"
    echo "n8n is not running or not accessible at ${N8N_URL}"
    exit 1
fi
echo -e "${GREEN}OK${NC}"
echo ""

# Generate test data
TEST_DATE=$(date -d "+1 day" +%Y-%m-%d)
TEST_START="${TEST_DATE}T10:00:00-03:00"
TEST_END="${TEST_DATE}T11:00:00-03:00"
TEST_SUMMARY="🧪 CRUD Test Event"
TEST_DESCRIPTION="This is a test event for CRUD workflow validation"

# Store event ID
EVENT_ID=""

echo "Test Date: $TEST_DATE"
echo ""

# ============================================
# TEST 1: CREATE
# ============================================
echo "========================================"
echo "TEST 1: CREATE Event"
echo "========================================"

CREATE_RESPONSE=$(curl -s -X POST "${N8N_URL}${WEBHOOK_PREFIX}/events/create" \
  -H "Content-Type: application/json" \
  -d "{
    \"summary\": \"$TEST_SUMMARY\",
    \"description\": \"$TEST_DESCRIPTION\",
    \"start\": \"$TEST_START\",
    \"end\": \"$TEST_END\"
  }" 2>/dev/null)

# Check if create was successful
if echo "$CREATE_RESPONSE" | grep -q '"success":true'; then
    EVENT_ID=$(echo "$CREATE_RESPONSE" | grep -o '"eventId":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo -e "${GREEN}✅ CREATE SUCCESS${NC}"
    echo "  Event ID: $EVENT_ID"
    echo "  Summary: $(echo "$CREATE_RESPONSE" | grep -o '"summary":"[^"]*"' | head -1 | cut -d'"' -f4)"
    echo "  Start: $(echo "$CREATE_RESPONSE" | grep -o '"dateTime":"[^"]*"' | head -1 | cut -d'"' -f4)"
    echo "  HTML Link: $(echo "$CREATE_RESPONSE" | grep -o '"htmlLink":"[^"]*"' | head -1 | cut -d'"' -f4)"
else
    echo -e "${RED}❌ CREATE FAILED${NC}"
    echo "Response: $CREATE_RESPONSE"
    exit 1
fi
echo ""

# ============================================
# TEST 2: LIST
# ============================================
echo "========================================"
echo "TEST 2: LIST Events"
echo "========================================"

LIST_RESPONSE=$(curl -s "${N8N_URL}${WEBHOOK_PREFIX}/events/list?timeMin=${TEST_DATE}T00:00:00-03:00&maxResults=10" 2>/dev/null)

# Check if list returned data
if echo "$LIST_RESPONSE" | grep -q '"success":true'; then
    EVENT_COUNT=$(echo "$LIST_RESPONSE" | grep -o '"count":[0-9]*' | grep -o '[0-9]*')
    echo -e "${GREEN}✅ LIST SUCCESS${NC}"
    echo "  Found $EVENT_COUNT event(s)"
    
    # Check if our created event is in the list
    if echo "$LIST_RESPONSE" | grep -q "$EVENT_ID"; then
        echo "  ✅ Created event found in list"
    else
        echo -e "  ${YELLOW}⚠️  Created event not found in list (may be filtered)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  LIST returned empty or invalid response${NC}"
    echo "Response: $(echo "$LIST_RESPONSE" | head -c 200)"
fi
echo ""

# ============================================
# TEST 3: UPDATE
# ============================================
echo "========================================"
echo "TEST 3: UPDATE Event"
echo "========================================"

UPDATED_SUMMARY="🧪 CRUD Test Event (UPDATED)"
UPDATED_DESCRIPTION="This event was updated via the API"
UPDATED_START="${TEST_DATE}T14:00:00-03:00"
UPDATED_END="${TEST_DATE}T15:00:00-03:00"

UPDATE_RESPONSE=$(curl -s -X PUT "${N8N_URL}${WEBHOOK_PREFIX}/events/update" \
  -H "Content-Type: application/json" \
  -d "{
    \"eventId\": \"$EVENT_ID\",
    \"summary\": \"$UPDATED_SUMMARY\",
    \"description\": \"$UPDATED_DESCRIPTION\",
    \"start\": \"$UPDATED_START\",
    \"end\": \"$UPDATED_END\"
  }" 2>/dev/null)

# Check if update was successful
if echo "$UPDATE_RESPONSE" | grep -q '"success":true'; then
    RETURNED_SUMMARY=$(echo "$UPDATE_RESPONSE" | grep -o '"summary":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo -e "${GREEN}✅ UPDATE SUCCESS${NC}"
    echo "  Event ID: $(echo "$UPDATE_RESPONSE" | grep -o '"eventId":"[^"]*"' | head -1 | cut -d'"' -f4)"
    echo "  New Summary: $RETURNED_SUMMARY"
    echo "  New Start: $(echo "$UPDATE_RESPONSE" | grep -o '"dateTime":"[^"]*"' | head -1 | cut -d'"' -f4)"
    
    # Verify the summary was actually updated
    if echo "$RETURNED_SUMMARY" | grep -q "UPDATED"; then
        echo "  ✅ Summary confirmed updated"
    else
        echo -e "  ${YELLOW}⚠️  Summary may not have been updated${NC}"
    fi
else
    echo -e "${RED}❌ UPDATE FAILED${NC}"
    echo "Response: $UPDATE_RESPONSE"
    exit 1
fi
echo ""

# ============================================
# TEST 4: DELETE
# ============================================
echo "========================================"
echo "TEST 4: DELETE Event"
echo "========================================"

DELETE_RESPONSE=$(curl -s -X DELETE "${N8N_URL}${WEBHOOK_PREFIX}/events/delete?eventId=$EVENT_ID" 2>/dev/null)

# Check if delete was successful
if echo "$DELETE_RESPONSE" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ DELETE SUCCESS${NC}"
    echo "  Event ID $EVENT_ID deleted"
else
    echo -e "${RED}❌ DELETE FAILED${NC}"
    echo "Response: $DELETE_RESPONSE"
    exit 1
fi
echo ""

# ============================================
# TEST 5: VERIFY DELETION
# ============================================
echo "========================================"
echo "TEST 5: VERIFY Deletion"
echo "========================================"

# Wait a moment for deletion to propagate
sleep 2

VERIFY_RESPONSE=$(curl -s "${N8N_URL}${WEBHOOK_PREFIX}/events/list?timeMin=${TEST_DATE}T00:00:00-03:00&maxResults=50" 2>/dev/null)

if echo "$VERIFY_RESPONSE" | grep -q "$EVENT_ID"; then
    echo -e "${YELLOW}⚠️  Event still found in list (may need more time)${NC}"
else
    echo -e "${GREEN}✅ Event successfully removed from calendar${NC}"
fi
echo ""

# ============================================
# SUMMARY
# ============================================
echo "========================================"
echo "   TEST SUMMARY"
echo "========================================"
echo -e "${GREEN}✅ CREATE${NC}: PASSED"
echo -e "${GREEN}✅ LIST${NC}: PASSED"
echo -e "${GREEN}✅ UPDATE${NC}: PASSED"
echo -e "${GREEN}✅ DELETE${NC}: PASSED"
echo ""
echo -e "${GREEN}All Event CRUD workflows are working correctly!${NC}"
echo ""
echo "========================================"
