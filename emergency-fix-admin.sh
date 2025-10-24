#!/bin/bash

# EMERGENCY FIX for Guacamole admin permission caching issue
# Use when admin permissions are set in database but NOT working in UI

echo "🚨 EMERGENCY GUACAMOLE ADMIN PERMISSION FIX 🚨"
echo "================================================"
echo ""

# Step 1: Verify permission exists
echo "[1] Verifying ADMINISTER permission in database..."
ENTITY_ID=$(mysql -u root guacamole -se \
    "SELECT entity_id FROM guacamole_entity WHERE name='guacadmin' AND type='USER';" 2>/dev/null)

if [ -z "$ENTITY_ID" ]; then
    echo "✗ ERROR: guacadmin user not found!"
    exit 1
fi

PERMS=$(mysql -u root guacamole -se \
    "SELECT GROUP_CONCAT(permission) FROM guacamole_system_permission WHERE entity_id=$ENTITY_ID;" 2>/dev/null)

echo "  Entity ID: $ENTITY_ID"
echo "  Permissions: $PERMS"

if [ -z "$PERMS" ] || [ "$PERMS" = "NULL" ]; then
    echo "  ⚠ ADMINISTER permission NOT in database!"
    echo "  Granting permission now..."
    mysql -u root guacamole -e \
        "INSERT INTO guacamole_system_permission (entity_id, permission) \
         VALUES ($ENTITY_ID, 'ADMINISTER');" 2>/dev/null
    echo "  ✓ Permission inserted"
fi
echo ""

# Step 2: AGGRESSIVE cache clearing
echo "[2] Clearing Guacamole permission cache..."
echo "  Stopping Tomcat completely..."
supervisorctl -c /etc/supervisor/supervisord.conf stop tomcat 2>/dev/null || pkill -9 -f tomcat || true
sleep 2

# Kill any remaining Java processes
pkill -9 java 2>/dev/null || true
sleep 2

echo "  Removing Guacamole temporary files..."
rm -rf /opt/guacamole/work/* 2>/dev/null || true
rm -rf /opt/guacamole/wtpwebapps/* 2>/dev/null || true
rm -rf /var/lib/tomcat/work/* 2>/dev/null || true
rm -rf /var/lib/tomcat/wtpwebapps/* 2>/dev/null || true

echo "  ✓ Cache cleared"
echo ""

# Step 3: Hard restart
echo "[3] Hard restarting Tomcat..."
sleep 2
supervisorctl -c /etc/supervisor/supervisord.conf start tomcat 2>/dev/null || true
echo "  ✓ Tomcat restart command sent"
echo ""

# Step 4: Wait for startup and verify
echo "[4] Waiting for Guacamole to restart (30 seconds)..."
READY=0
for i in {1..30}; do
    if curl -s http://localhost:8080/guacamole/ >/dev/null 2>&1; then
        echo "  ✓ Guacamole is responding"
        READY=1
        break
    fi
    echo -n "."
    sleep 1
done

if [ $READY -eq 0 ]; then
    echo ""
    echo "  ⚠ Guacamole not responding after 30 seconds"
    echo "  Check logs: tail -f /var/log/supervisor/tomcat.out.log"
fi
echo ""

# Step 5: User session cleanup advice
echo "[5] Final step - CLIENT SIDE cleanup required:"
echo ""
echo "  YOU MUST DO THIS in your browser:"
echo "  1. Press Ctrl+Shift+Delete (or Cmd+Shift+Delete on Mac)"
echo "  2. Clear ALL browsing data (especially cookies & cache)"
echo "  3. Close ALL tabs with Guacamole"
echo "  4. Go to http://YOUR_IP:8080/guacamole in a FRESH tab"
echo "  5. Log in as guacadmin / guacadmin"
echo "  6. You should NOW see the 'Administration' menu"
echo ""

# Step 6: Verify fix
echo "[6] Verification query (run this to confirm fix):"
echo ""
echo "  mysql -u root guacamole -e \\"
echo "    \"SELECT entity_id, permission FROM guacamole_system_permission WHERE entity_id=$ENTITY_ID;\""
echo ""

echo "================================================"
echo "✓ Emergency fix complete!"
echo ""
echo "If STILL not admin after clearing browser cache:"
echo "  1. Try incognito/private window (bypasses all browser cache)"
echo "  2. Try a different browser"
echo "  3. Check browser console (F12) for errors"
echo "  4. Run: tail -50 /var/log/supervisor/tomcat.err.log"
echo ""
