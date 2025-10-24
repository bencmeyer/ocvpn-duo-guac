# How to Run Diagnostics In Your Container

Your container is running with the Guacamole/VPN services. To diagnose the admin issue, you need to run commands INSIDE that container.

## Option 1: Quick Diagnostic (Recommended)

If you have the repo checked out in the container:

```bash
# Run diagnostic
docker exec ocvpn-guac bash /opt/ocvpn-duo-guac/diagnose-in-container.sh
```

Or if repo is elsewhere:

```bash
docker exec ocvpn-guac bash << 'EOF'

echo "🔍 Quick Check"
echo ""

# Check if user-mapping.xml exists
echo "XML backend file:"
[ -f /root/.guacamole/user-mapping.xml ] && echo "  EXISTS (might be issue)" || echo "  Not found (good)"

# Check MySQL config
echo ""
echo "MySQL config:"
grep "^mysql-hostname" /root/.guacamole/guacamole.properties 2>/dev/null && echo "  Configured" || echo "  Not found"

# Check database permission
echo ""
echo "Admin permission in database:"
ENTITY_ID=$(mysql -u root guacamole -se "SELECT entity_id FROM guacamole_entity WHERE name='guacadmin' AND type='USER';" 2>/dev/null)
if [ -n "$ENTITY_ID" ]; then
    mysql -u root guacamole -se "SELECT permission FROM guacamole_system_permission WHERE entity_id=$ENTITY_ID;" 2>/dev/null
else
    echo "  User not found"
fi

EOF
```

## Option 2: Manual Steps

Run these commands in sequence inside your container:

```bash
# 1. Check if XML backend exists (the likely culprit)
docker exec ocvpn-guac ls -la /root/.guacamole/user-mapping.xml

# 2. Check auth configuration
docker exec ocvpn-guac grep -E "^mysql-|^auth-provider" /root/.guacamole/guacamole.properties

# 3. Check database admin permission
docker exec ocvpn-guac mysql -u root guacamole -e "
    SELECT e.name, sp.permission 
    FROM guacamole_entity e 
    LEFT JOIN guacamole_system_permission sp ON e.entity_id = sp.entity_id 
    WHERE e.type='USER';"
```

## Option 3: The Fix (If XML Exists)

If you find `/root/.guacamole/user-mapping.xml` EXISTS, run this to remove it:

```bash
# Remove XML backend
docker exec ocvpn-guac rm -f /root/.guacamole/user-mapping.xml

# Hard restart
docker exec ocvpn-guac bash << 'EOF'
supervisorctl -c /etc/supervisor/supervisord.conf stop all
sleep 2
pkill -9 java
sleep 2
supervisorctl -c /etc/supervisor/supervisord.conf start all
sleep 10
echo "✓ Restarted"
EOF

# Test
docker exec ocvpn-guac curl -s http://localhost:8080/guacamole/ | head -5
```

## What to Look For

### Result 1: user-mapping.xml EXISTS
```
-rw-r--r-- root root 500 /root/.guacamole/user-mapping.xml
```
**Action:** Remove it (XML backend conflicts with MySQL)

### Result 2: MySQL Config Present
```
mysql-hostname: localhost
mysql-port: 3306
```
**Good:** MySQL backend configured

### Result 3: Permission Correct
```
guacadmin  ADMINISTER
```
**Good:** Permission is set in database

### Result 4: Permission Missing
```
guacadmin  NULL
```
**Action:** Permission needs to be added to database

---

## Full Test Script (Copy & Paste This)

```bash
# Run everything in one go
docker exec ocvpn-guac bash << 'FULLEOF'

echo "=== FULL GUACAMOLE ADMIN DIAGNOSIS ==="
echo ""

echo "[1] XML Backend Check"
if [ -f /root/.guacamole/user-mapping.xml ]; then
    echo "  ⚠ user-mapping.xml EXISTS"
    echo "  This is likely your problem - it overrides MySQL permissions"
    echo "  FIX: rm /root/.guacamole/user-mapping.xml"
else
    echo "  ✓ user-mapping.xml does not exist"
fi
echo ""

echo "[2] MySQL Configuration"
grep "^mysql-" /root/.guacamole/guacamole.properties 2>/dev/null | head -3
echo ""

echo "[3] Admin User in Database"
ENTITY_ID=$(mysql -u root guacamole -se "SELECT entity_id FROM guacamole_entity WHERE name='guacadmin' AND type='USER';" 2>/dev/null)
echo "  Entity ID: $ENTITY_ID"

echo ""
echo "[4] Admin Permissions"
if [ -n "$ENTITY_ID" ]; then
    PERMS=$(mysql -u root guacamole -se "SELECT GROUP_CONCAT(permission) FROM guacamole_system_permission WHERE entity_id=$ENTITY_ID;" 2>/dev/null)
    echo "  Permissions: $PERMS"
else
    echo "  ERROR: User not in database"
fi
echo ""

echo "[5] Tomcat Status"
ps aux | grep -E "tomcat|catalina" | grep -v grep > /dev/null && echo "  ✓ Tomcat running" || echo "  ✗ Tomcat NOT running"
echo ""

echo "[6] Web Interface"
HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/guacamole/ 2>/dev/null)
echo "  HTTP Status: $HTTP"

FULLEOF
```

---

## Expected Output After Fix

After running the fix (removing user-mapping.xml and restarting), you should see:

```
[1] XML Backend Check
  ✓ user-mapping.xml does not exist
  
[2] MySQL Configuration
  mysql-hostname: localhost
  mysql-port: 3306
  mysql-database: guacamole
  
[3] Admin User in Database
  Entity ID: 1
  
[4] Admin Permissions
  Permissions: ADMINISTER
  
[5] Tomcat Status
  ✓ Tomcat running
  
[6] Web Interface
  HTTP Status: 200
```

Then log in and you should see **Administration** menu!

