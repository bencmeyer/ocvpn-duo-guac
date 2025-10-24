#!/bin/bash

# OpenConnect VPN All-in-One Test Script
# Tests the all-in-one container deployment

set +H  # Disable history expansion

echo "========================================="
echo "OpenConnect VPN All-in-One Test"
echo "========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

# ==========================================
# TEST 1: Check if image exists
# ==========================================
echo -e "\n${YELLOW}=== Image Tests ===${NC}"
echo -n "Testing: Image exists... "
if docker image ls | grep -q openconnect-vpn-all; then
  echo -e "${GREEN}✓ PASSED${NC}"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "${RED}✗ FAILED${NC}"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ==========================================
# TEST 2: Start container
# ==========================================
echo -e "\n${YELLOW}=== Deployment Tests ===${NC}"
echo -n "Starting test container... "
if docker run -d \
  --name=test-openconnect-vpn \
  --rm \
  --privileged \
  -p 8080:8080 -p 9000:9000 \
  -e VPN_USER='test_user' \
  -e VPN_PASS='test_pass' \
  -e VPN_SERVER='vpn.illinois.edu' \
  -e VPN_AUTHGROUP='OpenConnect1 (Split)' \
  -e DUO_METHOD='push' \
  -e DNS_SERVERS='130.126.2.131' \
  openconnect-vpn-all:latest > /dev/null 2>&1; then
  echo -e "${GREEN}✓ Started${NC}"
  TESTS_PASSED=$((TESTS_PASSED + 1))
  
  sleep 5
  
  # ==========================================
  # TEST 3: Container running
  # ==========================================
  echo -n "Testing: Container running... "
  if docker ps -a | grep -q test-openconnect-vpn; then
    echo -e "${GREEN}✓ PASSED${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗ FAILED${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  
  # ==========================================
  # TEST 4: Supervisord started
  # ==========================================
  echo -n "Testing: Supervisord initialized... "
  if docker logs test-openconnect-vpn 2>&1 | grep -q supervisord; then
    echo -e "${GREEN}✓ PASSED${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗ FAILED${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  
  # ==========================================
  # TEST 5: Guacamole daemon running
  # ==========================================
  echo -n "Testing: Guacamole daemon running... "
  if docker logs test-openconnect-vpn 2>&1 | grep -q guacd; then
    echo -e "${GREEN}✓ PASSED${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗ FAILED${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  
  # ==========================================
  # TEST 6: Port 8080 responding
  # ==========================================
  echo -n "Testing: Port 8080 accessible (Guacamole)... "
  if curl -s -I http://localhost:8080 | grep -q "HTTP/1"; then
    echo -e "${GREEN}✓ PASSED${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗ FAILED${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  
  # ==========================================
  # TEST 7: Environment variables set
  # ==========================================
  echo -n "Testing: VPN_USER environment variable... "
  if docker exec test-openconnect-vpn printenv VPN_USER | grep -q test_user; then
    echo -e "${GREEN}✓ PASSED${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗ FAILED${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  
  # ==========================================
  # TEST 8: VPN script exists
  # ==========================================
  echo -n "Testing: VPN connection script... "
  if docker exec test-openconnect-vpn test -f /usr/local/bin/connect-vpn.sh; then
    echo -e "${GREEN}✓ PASSED${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗ FAILED${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  
  # ==========================================
  # TEST 9: Supervisord config exists
  # ==========================================
  echo -n "Testing: Supervisord config... "
  if docker exec test-openconnect-vpn test -f /etc/supervisor/conf.d/supervisord-openconnect.conf; then
    echo -e "${GREEN}✓ PASSED${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗ FAILED${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  
  # ==========================================
  # TEST 10: Cleanup
  # ==========================================
  echo -n "Stopping test container... "
  docker stop test-openconnect-vpn > /dev/null 2>&1
  echo -e "${GREEN}✓ Stopped${NC}"
  
else
  echo -e "${RED}✗ Failed to start${NC}"
  TESTS_FAILED=$((TESTS_FAILED + 1))
  docker logs test-openconnect-vpn 2>&1 | tail -20 || true
fi

# ==========================================
# SUMMARY
# ==========================================
echo ""
echo "========================================="
echo "Test Results"
echo "========================================="
echo -e "Passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Failed: ${RED}${TESTS_FAILED}${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ All tests passed!${NC}"
  echo ""
  echo "Container is ready for deployment:"
  echo "  1. docker-compose -f docker-compose-allin1.yml up -d"
  echo "  2. Access Guacamole: http://localhost:8080"
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  exit 1
fi
