# Guacamole Admin Permissions Troubleshooting

## Issue: Can login as guacadmin but not admin

When you log in as `guacadmin`, you can access the account but lack admin/system permissions to configure connections, users, etc.

## Root Causes

### 1. **Authentication Backend Mismatch** (Primary Issue)
The system has TWO authentication backends configured which conflict:

- **start.sh**: Sets up MySQL-based authentication with `guacamole_system_permission` table
- **update-guac-admin.sh**: Creates XML-based authentication via `user-mapping.xml`

Guacamole uses whichever is configured in `guacamole.properties`:

```properties
# If using MySQL:
mysql-hostname: localhost
mysql-port: 3306
mysql-database: guacamole

# If using XML:
auth-provider: xml
xml-root: /root/.guacamole
```

### 2. **MySQL Permissions Not Granted**
Even if MySQL authentication is set up, the `guacamole_system_permission` table may not have the `ADMINISTER` permission for the user.

### 3. **Permission Cache Not Cleared**
Guacamole caches permissions in memory. Changes to the database won't take effect until Tomcat is restarted.

## Diagnostic Steps

### Step 1: Check Current Authentication Method

```bash
cat /root/.guacamole/guacamole.properties | grep -E "auth-provider|mysql-"
```

**Expected MySQL output:**
```
mysql-hostname: localhost
mysql-port: 3306
mysql-database: guacamole
mysql-username: guacamole
mysql-password: guacamole
```

**Expected XML output:**
```
auth-provider: xml
xml-root: /root/.guacamole
```

### Step 2: Check User Exists in Database

```bash
# If using MySQL auth:
mysql -u root guacamole -e "
    SELECT e.name, e.entity_id 
    FROM guacamole_entity e 
    WHERE e.type='USER' AND e.name='guacadmin';
"
```

Expected output:
```
name         entity_id
guacadmin    1
```

### Step 3: Check Permissions

```bash
# Get user's entity_id first:
ENTITY_ID=$(mysql -u root guacamole -se "
    SELECT entity_id FROM guacamole_entity 
    WHERE name='guacadmin' AND type='USER';"
)

# Then check permissions:
mysql -u root guacamole -e "
    SELECT * FROM guacamole_system_permission 
    WHERE entity_id=$ENTITY_ID;
"
```

**Expected output:**
```
entity_id  permission
1          ADMINISTER
```

If empty, the permission is missing.

### Step 4: Check XML User Mapping

```bash
cat /root/.guacamole/user-mapping.xml
```

Look for `admin="true"` and `administer="true"` attributes.

## Solution: Fix MySQL-based Admin Permissions

### Option A: Grant Permission via Database (Recommended)

```bash
#!/bin/bash

echo "Fixing Guacamole admin permissions..."

# Get the guacadmin user's entity ID
ENTITY_ID=$(mysql -u root guacamole -se \
    "SELECT entity_id FROM guacamole_entity WHERE name='guacadmin' AND type='USER';" \
)

if [ -z "$ENTITY_ID" ]; then
    echo "ERROR: guacadmin user not found!"
    exit 1
fi

echo "Found guacadmin with entity_id: $ENTITY_ID"

# Check if ADMINISTER permission already exists
EXISTING=$(mysql -u root guacamole -se \
    "SELECT COUNT(*) FROM guacamole_system_permission \
     WHERE entity_id=$ENTITY_ID AND permission='ADMINISTER';" \
)

if [ "$EXISTING" -gt 0 ]; then
    echo "✓ ADMINISTER permission already set"
else
    echo "Adding ADMINISTER permission..."
    mysql -u root guacamole -e \
        "INSERT INTO guacamole_system_permission (entity_id, permission) \
         VALUES ($ENTITY_ID, 'ADMINISTER');"
    echo "✓ Permission added"
fi

# Restart Tomcat to clear cache
echo "Restarting Guacamole..."
supervisorctl -c /etc/supervisor/supervisord.conf restart tomcat

# Wait for restart
sleep 5
echo "✓ Done"
```

### Option B: Use the Test Script

```bash
chmod +x /path/to/test-admin-permissions.sh
./test-admin-permissions.sh
```

This will show:
1. Current authentication configuration
2. Users in database
3. System permissions status
4. Any errors in logs
5. Guacamole web interface status

## Solution: Fix XML-based Admin Permissions

If using XML authentication, ensure `user-mapping.xml` has correct attributes:

```xml
<user-mapping>
    <authorize username="guacadmin" password="guacadmin"
               admin="true"
               administer="true"
               create="true"
               delete="true"
               update="true">
        <!-- Admin user -->
    </authorize>
</user-mapping>
```

Then restart Guacamole:
```bash
supervisorctl -c /etc/supervisor/supervisord.conf restart tomcat
```

## Verification

After fixing, verify admin access:

1. Log out completely from Guacamole UI
2. Clear browser cache (Ctrl+Shift+Del)
3. Log back in as guacadmin/guacadmin
4. You should now see the "Administration" menu
5. Try adding a connection or user

## Long-term Fix: Standardize Authentication

To prevent future issues, the project should:

1. **Use ONLY MySQL authentication** (recommended for Docker):
   - Removes need for XML file updates
   - Easier to manage programmatically
   - Works with Guacamole's user management UI

2. **Remove conflicting update-guac-admin.sh**:
   - This file conflicts with start.sh
   - All admin setup should be in start.sh only

3. **Update start.sh to ensure permissions are set correctly:**
   - Add better error checking
   - Verify permissions after setting them
   - Clear Guacamole permission cache

### Recommended Fix for start.sh

```bash
# Grant ADMINISTER permission (called after user creation)
echo "  Granting ADMINISTER system permission..."

# Get the entity ID
ENTITY_ID=$(mysql -u root guacamole -se \
    "SELECT entity_id FROM guacamole_entity \
     WHERE name='$GUAC_DEFAULT_USER' AND type='USER';" \
)

# Clear old permissions
mysql -u root guacamole -e \
    "DELETE FROM guacamole_system_permission WHERE entity_id=$ENTITY_ID;" 2>/dev/null

# Insert ADMINISTER permission
mysql -u root guacamole -e \
    "INSERT INTO guacamole_system_permission (entity_id, permission) \
     VALUES ($ENTITY_ID, 'ADMINISTER');"

# Verify permission was set
PERM_COUNT=$(mysql -u root guacamole -se \
    "SELECT COUNT(*) FROM guacamole_system_permission \
     WHERE entity_id=$ENTITY_ID;" \
)

if [ "$PERM_COUNT" -gt 0 ]; then
    echo "  ✓ ADMINISTER permission granted successfully"
else
    echo "  ✗ ERROR: Failed to set ADMINISTER permission"
    exit 1
fi
```

## Testing Locally

To test the fix in your local environment:

```bash
# 1. Check current status
docker exec ocvpn-guac bash /path/to/test-admin-permissions.sh

# 2. Apply the fix (run inside container)
docker exec ocvpn-guac bash << 'EOF'
ENTITY_ID=$(mysql -u root guacamole -se \
    "SELECT entity_id FROM guacamole_entity WHERE name='guacadmin' AND type='USER';" \
)
mysql -u root guacamole -e \
    "DELETE FROM guacamole_system_permission WHERE entity_id=$ENTITY_ID; \
     INSERT INTO guacamole_system_permission (entity_id, permission) VALUES ($ENTITY_ID, 'ADMINISTER');"
supervisorctl -c /etc/supervisor/supervisord.conf restart tomcat
EOF

# 3. Wait for restart
sleep 5

# 4. Test admin access
# Go to http://localhost:8080/guacamole
# Log in as guacadmin/guacadmin
# Check if you now see the Administration panel
```

## Common Issues After Fix

| Symptom | Cause | Solution |
|---------|-------|----------|
| Still not admin after fix | Permission cache not cleared | Restart Tomcat: `supervisorctl restart tomcat` |
| "ACCESS DENIED" error | Wrong auth backend configured | Check `guacamole.properties` |
| Can't log in at all | Wrong password/user | Verify in `guacamole_user` table |
| Admin works but connections fail | Connection permissions not set | Grant CREATE permission in `guacamole_object_permission` |

