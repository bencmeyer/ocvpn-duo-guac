#!/bin/bash

# Quick diagnosis script - run INSIDE the Docker container
# Usage: docker exec ocvpn-guac bash /path/to/this/script

echo "🔍 Quick Guacamole Auth Backend Check"
echo "======================================"
echo ""

# Check 1: MySQL configuration
echo "[1] MySQL Backend Configuration:"
if [ -f /root/.guacamole/guacamole.properties ]; then
    MYSQL_CONFIG=$(grep "^mysql-" /root/.guacamole/guacamole.properties 2>/dev/null | wc -l)
    if [ $MYSQL_CONFIG -gt 0 ]; then
        echo "  ✓ MySQL backend configured"
        grep "^mysql-hostname\|^mysql-database" /root/.guacamole/guacamole.properties
    else
        echo "  ⚠ No MySQL config found"
    fi
else
    echo "  ✗ guacamole.properties not found!"
fi
echo ""

# Check 2: XML backend
echo "[2] XML Backend (user-mapping.xml):"
if [ -f /root/.guacamole/user-mapping.xml ]; then
    echo "  ⚠ EXISTS - This might override MySQL!"
    echo ""
    echo "  Content (first 10 lines):"
    head -10 /root/.guacamole/user-mapping.xml | sed 's/^/    /'
else
    echo "  ✓ Does not exist (good)"
fi
echo ""

# Check 3: Database permissions
echo "[3] Database Permissions:"
ENTITY_ID=$(mysql -u root guacamole -se "SELECT entity_id FROM guacamole_entity WHERE name='guacadmin' AND type='USER';" 2>/dev/null)

if [ -n "$ENTITY_ID" ]; then
    echo "  Entity ID: $ENTITY_ID"
    PERMS=$(mysql -u root guacamole -se "SELECT GROUP_CONCAT(permission) FROM guacamole_system_permission WHERE entity_id=$ENTITY_ID;" 2>/dev/null)
    echo "  Permissions: $PERMS"
else
    echo "  ✗ guacadmin user not found in database!"
fi
echo ""

# Check 4: Tomcat process
echo "[4] Tomcat Process:"
if ps aux | grep -v grep | grep -q "tomcat\|catalina"; then
    echo "  ✓ Tomcat is running"
    ps aux | grep -E "tomcat|catalina" | grep -v grep | head -1 | awk '{print "    PID: " $2 " CPU: " $3 "% MEM: " $4 "%"}'
else
    echo "  ✗ Tomcat is NOT running"
fi
echo ""

# Check 5: Guacamole web interface
echo "[5] Guacamole Web Interface:"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/guacamole/ 2>/dev/null)
if [ "$HTTP_CODE" = "200" ]; then
    echo "  ✓ Responding (HTTP $HTTP_CODE)"
else
    echo "  ⚠ Status: HTTP $HTTP_CODE"
fi
echo ""

echo "======================================"
echo ""
echo "Recommendations:"
echo ""

if [ -f /root/.guacamole/user-mapping.xml ]; then
    echo "⚠ user-mapping.xml exists - this might be the issue!"
    echo "  Option A: Remove it to use MySQL-only backend"
    echo "    rm /root/.guacamole/user-mapping.xml"
    echo ""
    echo "  Option B: Update it to have admin permissions"
    echo "    Edit and add: admin=\"true\" administer=\"true\""
    echo ""
fi

if [ -z "$ENTITY_ID" ]; then
    echo "⚠ guacadmin not in database - admin setup didn't work"
    echo "  Run: /root/.guacamole/setup-admin.sh"
    echo ""
fi

if [ "$HTTP_CODE" != "200" ]; then
    echo "⚠ Guacamole not responding"
    echo "  Check: tail -50 /var/log/supervisor/tomcat.err.log"
    echo ""
fi

echo "Next step:"
echo "  If user-mapping.xml exists, try removing it:"
echo "  rm /root/.guacamole/user-mapping.xml"
echo "  supervisorctl -c /etc/supervisor/supervisord.conf restart tomcat"
echo "  sleep 5"
echo ""
