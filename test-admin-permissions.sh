#!/bin/bash

# Test script to diagnose Guacamole admin permission issues

echo "=== Guacamole Admin Permission Diagnostics ==="
echo ""

# Check 1: Guacamole configuration
echo "[1] Checking Guacamole authentication configuration..."
if [ -f /root/.guacamole/guacamole.properties ]; then
    echo "  guacamole.properties found:"
    grep -E "auth-provider|mysql-|ldap-|saml-" /root/.guacamole/guacamole.properties 2>/dev/null | head -10
    echo ""
else
    echo "  ⚠ guacamole.properties not found!"
    echo ""
fi

# Check 2: User-mapping.xml (XML auth backend)
echo "[2] Checking XML authentication backend..."
if [ -f /root/.guacamole/user-mapping.xml ]; then
    echo "  user-mapping.xml found:"
    grep -E "authorize.*username|admin=" /root/.guacamole/user-mapping.xml | head -5
    echo ""
else
    echo "  ✓ user-mapping.xml not present (using MySQL authentication)"
    echo ""
fi

# Check 3: MariaDB/MySQL user table
echo "[3] Checking database users..."
USERS=$(mysql -u root guacamole -se "SELECT name FROM guacamole_entity WHERE type='USER';" 2>/dev/null)
if [ -n "$USERS" ]; then
    echo "  Database users:"
    while IFS= read -r user; do
        echo "    - $user"
    done <<< "$USERS"
    echo ""
else
    echo "  ⚠ No users found in database"
    echo ""
fi

# Check 4: Admin permissions in database
echo "[4] Checking system permissions..."
ADMIN_PERMS=$(mysql -u root guacamole -se "
    SELECT 
        e.name as username,
        GROUP_CONCAT(sp.permission SEPARATOR ', ') as permissions
    FROM guacamole_entity e
    LEFT JOIN guacamole_system_permission sp ON e.entity_id = sp.entity_id
    WHERE e.type = 'USER'
    GROUP BY e.entity_id, e.name;
" 2>/dev/null)

if [ -n "$ADMIN_PERMS" ]; then
    echo "  User permissions:"
    echo "$ADMIN_PERMS" | while IFS=$'\t' read -r user perms; do
        if [ -z "$perms" ]; then
            echo "    ⚠ $user: (no permissions)"
        else
            echo "    ✓ $user: $perms"
        fi
    done
    echo ""
else
    echo "  ⚠ Could not query permissions"
    echo ""
fi

# Check 5: Test direct database access
echo "[5] Testing database connectivity..."
TEST_RESULT=$(mysql -u guacamole -pguacamole guacamole -se "SELECT COUNT(*) FROM guacamole_user;" 2>&1)
if echo "$TEST_RESULT" | grep -q "[0-9]"; then
    echo "  ✓ Database connection successful"
    echo "  User count: $TEST_RESULT"
else
    echo "  ✗ Database connection failed"
    echo "  Error: $TEST_RESULT"
fi
echo ""

# Check 6: Tomcat/Guacamole logs
echo "[6] Checking recent Guacamole logs..."
if [ -f /var/log/supervisor/tomcat.out.log ]; then
    echo "  Recent Tomcat output:"
    tail -10 /var/log/supervisor/tomcat.out.log | sed 's/^/    /'
    echo ""
fi

if [ -f /var/log/supervisor/tomcat.err.log ]; then
    ERRORS=$(tail -10 /var/log/supervisor/tomcat.err.log 2>/dev/null)
    if [ -n "$ERRORS" ] && [ "$ERRORS" != "" ]; then
        echo "  Recent Tomcat errors:"
        echo "$ERRORS" | sed 's/^/    /'
        echo ""
    fi
fi

# Check 7: Guacamole web interface status
echo "[7] Testing Guacamole web interface..."
GUAC_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/guacamole/ 2>/dev/null)
if [ "$GUAC_STATUS" = "200" ]; then
    echo "  ✓ Guacamole web interface responding (HTTP $GUAC_STATUS)"
else
    echo "  ⚠ Guacamole web interface status: HTTP $GUAC_STATUS"
fi
echo ""

# Summary
echo "=== Diagnosis Summary ==="
echo ""
echo "If you see '⚠' items above, check:"
echo ""
echo "1. For XML auth backend issues:"
echo "   - Check guacamole.properties for 'auth-provider=xml'"
echo "   - Verify user-mapping.xml syntax"
echo ""
echo "2. For MySQL auth backend issues:"
echo "   - Check that guacamole_system_permission table has ADMINISTER entries"
echo "   - Run: mysql -u root guacamole -e \"SELECT * FROM guacamole_system_permission;\""
echo ""
echo "3. To grant ADMINISTER permission manually:"
echo "   ENTITY_ID=\$(mysql -u root guacamole -se \"SELECT entity_id FROM guacamole_entity WHERE name='guacadmin' AND type='USER';\") && \\"
echo "   mysql -u root guacamole -e \"INSERT INTO guacamole_system_permission (entity_id, permission) VALUES (\$ENTITY_ID, 'ADMINISTER');\""
echo ""
