#!/bin/bash

# CRITICAL DIAGNOSIS - Permission loaded but not recognized
# When user can log in, sees Settings, but no Administration menu

echo "🔍 CRITICAL DIAGNOSIS - Admin Permission Not Loading"
echo "====================================================="
echo ""

# Step 1: Verify permission is definitely in database
echo "[1] Database Permission Check..."
ENTITY_ID=$(mysql -u root guacamole -se \
    "SELECT entity_id FROM guacamole_entity WHERE name='guacadmin' AND type='USER';" 2>/dev/null)

if [ -z "$ENTITY_ID" ]; then
    echo "✗ User not found!"
    exit 1
fi

echo "  Entity ID: $ENTITY_ID"

PERMS=$(mysql -u root guacamole -se \
    "SELECT GROUP_CONCAT(permission) FROM guacamole_system_permission WHERE entity_id=$ENTITY_ID;" 2>/dev/null)

echo "  Permissions in DB: $PERMS"

if [ "$PERMS" != "ADMINISTER" ]; then
    echo "  ✗ ERROR: ADMINISTER not found! Current: '$PERMS'"
    echo "  Fixing..."
    mysql -u root guacamole -e "DELETE FROM guacamole_system_permission WHERE entity_id=$ENTITY_ID;" 2>/dev/null
    mysql -u root guacamole -e "INSERT INTO guacamole_system_permission (entity_id, permission) VALUES ($ENTITY_ID, 'ADMINISTER');" 2>/dev/null
    echo "  ✓ Permission re-inserted"
else
    echo "  ✓ ADMINISTER permission correct in database"
fi
echo ""

# Step 2: Check authentication backend configuration
echo "[2] Authentication Backend Configuration..."
if [ -f /root/.guacamole/guacamole.properties ]; then
    AUTH_TYPE=$(grep "auth-provider" /root/.guacamole/guacamole.properties | grep -v "^#")
    if [ -n "$AUTH_TYPE" ]; then
        echo "  ⚠ XML auth backend detected: $AUTH_TYPE"
        echo "  This conflicts with MySQL permissions!"
    fi
    
    MYSQL_CHECK=$(grep "mysql-" /root/.guacamole/guacamole.properties | grep -v "^#")
    if [ -z "$MYSQL_CHECK" ]; then
        echo "  ✗ ERROR: No MySQL configuration found!"
        echo "  Current config:"
        grep -v "^#" /root/.guacamole/guacamole.properties | grep -v "^$"
    else
        echo "  ✓ MySQL backend configured"
    fi
else
    echo "  ✗ guacamole.properties not found!"
fi
echo ""

# Step 3: Check XML user-mapping.xml doesn't exist (would override MySQL)
echo "[3] Checking for conflicting XML backend..."
if [ -f /root/.guacamole/user-mapping.xml ]; then
    echo "  ⚠ user-mapping.xml exists (XML auth)"
    echo "  This will OVERRIDE MySQL permissions!"
    echo "  Checking admin attributes..."
    
    if grep -q 'username="guacadmin".*admin="true"' /root/.guacamole/user-mapping.xml; then
        echo "    ✓ guacadmin has admin=true in XML"
    elif grep -q 'username="guacadmin"' /root/.guacamole/user-mapping.xml; then
        echo "    ✗ guacadmin exists but admin=true is NOT set"
        echo "    Fix: user-mapping.xml must have admin=\"true\" attribute"
    fi
else
    echo "  ✓ No user-mapping.xml (MySQL auth being used)"
fi
echo ""

# Step 4: Check Guacamole logs for permission errors
echo "[4] Checking Guacamole Logs..."
if [ -f /var/log/supervisor/tomcat.out.log ]; then
    echo "  Searching for permission/auth messages..."
    
    PERMS_MSG=$(grep -i "permission\|administer\|system.*permission" /var/log/supervisor/tomcat.out.log | tail -5)
    if [ -n "$PERMS_MSG" ]; then
        echo "  Found permission-related messages:"
        echo "$PERMS_MSG" | sed 's/^/    /'
    fi
    
    AUTH_MSG=$(grep -i "authentication\|mysql.*connected" /var/log/supervisor/tomcat.out.log | tail -3)
    if [ -n "$AUTH_MSG" ]; then
        echo "  Auth messages:"
        echo "$AUTH_MSG" | sed 's/^/    /'
    fi
fi
echo ""

# Step 5: Check if user table has any other issues
echo "[5] User Table Details..."
mysql -u root guacamole << EOF 2>/dev/null
SELECT 
    'Entity:' as check_type,
    entity_id, name, type, disabled 
FROM guacamole_entity 
WHERE name='guacadmin' AND type='USER'
UNION ALL
SELECT 
    'User:',
    entity_id, 'password_hash_len:', disabled, disabled
FROM guacamole_user 
WHERE entity_id=$ENTITY_ID;
EOF
echo ""

# Step 6: NUCLEAR restart option
echo "[6] NUCLEAR Restart (kills everything)..."
echo ""
echo "To completely restart Guacamole:"
echo ""
echo "  # Stop supervisor completely"
echo "  supervisorctl -c /etc/supervisor/supervisord.conf stop all"
echo "  sleep 5"
echo ""
echo "  # Kill any remaining processes"
echo "  pkill -9 java"
echo "  pkill -9 tomcat"
echo "  sleep 2"
echo ""
echo "  # Remove all cache"
echo "  rm -rf /opt/guacamole/work/*"
echo "  rm -rf /var/lib/tomcat/work/*"
echo "  sleep 2"
echo ""
echo "  # Start fresh"
echo "  supervisorctl -c /etc/supervisor/supervisord.conf start all"
echo "  sleep 10"
echo ""

echo "====================================================="
echo ""
echo "If you need to fix authentication:"
echo ""
echo "Option A: Use ONLY MySQL (recommended):"
echo "  1. Remove /root/.guacamole/user-mapping.xml"
echo "  2. Ensure guacamole.properties has MySQL settings"
echo "  3. Restart Guacamole"
echo ""
echo "Option B: Use XML (if that's preferred):"
echo "  1. Edit user-mapping.xml"
echo "  2. Add admin=\"true\" administer=\"true\" to guacadmin line"
echo "  3. Remove MySQL settings from guacamole.properties"
echo "  4. Restart Guacamole"
echo ""
