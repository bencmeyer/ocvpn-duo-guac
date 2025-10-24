#!/bin/bash

# Quick fix for missing admin permissions
# Run this if guacadmin can log in but doesn't have admin access

echo "🔧 Guacamole Admin Permission Quick Fix"
echo "========================================"
echo ""

# Step 1: Get the entity ID
echo "[1] Finding guacadmin user..."
ENTITY_ID=$(mysql -u root guacamole -se \
    "SELECT entity_id FROM guacamole_entity \
     WHERE name='guacadmin' AND type='USER';" 2>/dev/null)

if [ -z "$ENTITY_ID" ]; then
    echo "✗ ERROR: guacadmin user not found in database"
    echo ""
    echo "Debug: List all users:"
    mysql -u root guacamole -e "SELECT entity_id, name FROM guacamole_entity WHERE type='USER';"
    exit 1
fi

echo "✓ Found guacadmin (entity_id: $ENTITY_ID)"
echo ""

# Step 2: Check current permissions
echo "[2] Checking current permissions..."
CURRENT_PERMS=$(mysql -u root guacamole -se \
    "SELECT GROUP_CONCAT(permission) FROM guacamole_system_permission \
     WHERE entity_id=$ENTITY_ID;" 2>/dev/null)

if [ -z "$CURRENT_PERMS" ]; then
    echo "⚠ No permissions currently set"
else
    echo "✓ Current permissions: $CURRENT_PERMS"
fi
echo ""

# Step 3: Grant ADMINISTER permission
echo "[3] Granting ADMINISTER permission..."
mysql -u root guacamole -e \
    "INSERT IGNORE INTO guacamole_system_permission (entity_id, permission) \
     VALUES ($ENTITY_ID, 'ADMINISTER');" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✓ Permission inserted"
else
    echo "✗ Failed to insert permission"
    exit 1
fi
echo ""

# Step 4: Verify permission was set
echo "[4] Verifying permission..."
VERIFY=$(mysql -u root guacamole -se \
    "SELECT COUNT(*) FROM guacamole_system_permission \
     WHERE entity_id=$ENTITY_ID AND permission='ADMINISTER';" 2>/dev/null)

if [ "$VERIFY" -gt 0 ]; then
    echo "✓ ADMINISTER permission confirmed in database"
else
    echo "✗ Verification failed - permission not in database"
    exit 1
fi
echo ""

# Step 5: Restart Guacamole
echo "[5] Restarting Guacamole to apply changes..."
supervisorctl -c /etc/supervisor/supervisord.conf restart tomcat 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✓ Tomcat restart command sent"
else
    echo "⚠ Could not restart via supervisorctl, trying direct restart..."
    pkill -f tomcat || true
    sleep 2
fi

echo ""
sleep 3

# Step 6: Verify Guacamole is responding
echo "[6] Waiting for Guacamole to restart..."
for i in {1..30}; do
    if curl -s http://localhost:8080/guacamole/ >/dev/null 2>&1; then
        echo "✓ Guacamole is responding"
        break
    fi
    if [ $i -lt 30 ]; then
        echo -n "."
        sleep 1
    else
        echo ""
        echo "⚠ Guacamole not responding after 30 seconds"
    fi
done
echo ""

# Final instructions
echo "========================================"
echo "✓ Admin permission fix complete!"
echo ""
echo "Next steps:"
echo "1. Clear browser cache (Ctrl+Shift+Del)"
echo "2. Log out from Guacamole"
echo "3. Log back in as guacadmin/guacadmin"
echo "4. Look for 'Administration' menu at the top"
echo ""
echo "If you still don't see admin features:"
echo "- Check browser console for errors (F12)"
echo "- Try a different browser or incognito mode"
echo "- Verify permission: mysql -u root guacamole -e \"SELECT * FROM guacamole_system_permission WHERE entity_id=$ENTITY_ID;\""
echo ""
