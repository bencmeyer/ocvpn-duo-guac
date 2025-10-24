# Admin Shows Settings, Not Administration - FIX

## Your Symptom
✅ Can log in as guacadmin  
✅ Permission IS in database  
❌ See "Settings/Preferences", not "Administration" menu  
❌ Can't manage users/connections  

## Root Cause
**TWO authentication backends are conflicting:**

1. **MySQL backend** - In `guacamole.properties`
   - Has ADMINISTER permission set ✓
   - But Guacamole might not be using it

2. **XML backend** - `user-mapping.xml` file
   - May exist and override MySQL settings
   - May NOT have admin="true" attribute
   - Takes precedence if both exist

## THE FIX

### Step 1: Check Current Configuration

```bash
echo "=== Checking configuration ==="
echo ""
echo "guacamole.properties:"
cat /root/.guacamole/guacamole.properties | grep -v "^#" | grep -v "^$"
echo ""
echo "user-mapping.xml exists?"
[ -f /root/.guacamole/user-mapping.xml ] && echo "YES - This is the problem!" || echo "NO - Good"
```

### Step 2: PERMANENT FIX - Use MySQL Only

**Remove the conflicting XML backend:**

```bash
# Delete XML backend (conflicts with MySQL permissions)
rm -f /root/.guacamole/user-mapping.xml

# Verify guacamole.properties has MySQL settings
cat /root/.guacamole/guacamole.properties
```

**Should show:**
```
mysql-hostname: localhost
mysql-port: 3306
mysql-database: guacamole
mysql-username: guacamole
mysql-password: guacamole
```

**Should NOT show:**
```
auth-provider: xml
```

### Step 3: Restart Guacamole (Hard)

```bash
# Stop everything
supervisorctl -c /etc/supervisor/supervisord.conf stop all
sleep 3

# Kill any remaining Java
pkill -9 java
sleep 2

# Clear all caches
rm -rf /opt/guacamole/work/*
rm -rf /var/lib/tomcat/work/*
sleep 2

# Start fresh
supervisorctl -c /etc/supervisor/supervisord.conf start all
sleep 10

# Verify it's running
curl -s http://localhost:8080/guacamole/ | head -20
```

### Step 4: Clear Browser Cache Again
- Ctrl+Shift+Delete
- Select "All time"
- Check Cookies + Cache
- Clear data

### Step 5: Test Admin Access
1. Log out completely
2. Close browser
3. Reopen fresh
4. Go to `http://YOUR_IP:8080/guacamole`
5. Login as `guacadmin / guacadmin`
6. **Look for "Administration" menu** (not "Settings")

---

## Alternative Fix - If You Want XML Backend

If you prefer XML-based authentication:

**Edit `/root/.guacamole/user-mapping.xml`:**

```xml
<user-mapping>
    <!-- Admin user with ALL permissions -->
    <authorize username="guacadmin" 
               password="guacadmin"
               admin="true"
               administer="true"
               create="true"
               delete="true"
               update="true">
    </authorize>
</user-mapping>
```

**Then remove MySQL config from guacamole.properties:**
```bash
# Keep ONLY these lines in guacamole.properties:
# auth-provider: xml
# xml-root: /root/.guacamole
```

Then restart Guacamole (steps in Step 3 above).

---

## Why This Happens

The container setup has BOTH backends available:
- `start.sh` → Creates MySQL backend with permissions
- `update-guac-admin.sh` → Creates XML backend

If BOTH are configured, XML takes precedence and overrides MySQL permissions.

Since the startup log shows `✓ Admin permissions configured`, it's setting the MySQL permission. But if `user-mapping.xml` exists without `admin="true"`, the XML backend wins and you only get user access.

---

## Quick Diagnostic

Run this to see what's configured:

```bash
echo "=== Auth Backend Check ==="
echo ""
echo "Authentication provider:"
grep -E "auth-provider|^mysql-" /root/.guacamole/guacamole.properties | grep -v "^#"

echo ""
echo "XML backend exists?"
[ -f /root/.guacamole/user-mapping.xml ] && (
    echo "YES - checking content..."
    grep "authorize.*username" /root/.guacamole/user-mapping.xml | head -3
) || echo "NO"

echo ""
echo "Admin permission in database:"
ENTITY_ID=$(mysql -u root guacamole -se "SELECT entity_id FROM guacamole_entity WHERE name='guacadmin' AND type='USER';")
mysql -u root guacamole -se "SELECT permission FROM guacamole_system_permission WHERE entity_id=$ENTITY_ID;"
```

If you see:
- ✅ MySQL config + ❌ XML doesn't exist = Should work (remove XML if exists)
- ✅ XML config with admin="true" = Should work
- ❌ Both configured = Only XML is used (remove or fix XML)

---

## The Real Solution

**For this project:** Remove `update-guac-admin.sh` completely and use ONLY MySQL backend in `start.sh`. This eliminates conflicts and makes everything cleaner.

