# Admin Permission Issue - Diagnosis & Resolution

## Problem Summary

You can log in as `guacadmin` but don't have admin privileges. This means:
- ❌ No "Administration" menu appears
- ❌ Can't create connections, users, or groups
- ❌ Can't modify system settings

## Root Cause Analysis

The issue occurs because:

1. **Two conflicting authentication backends** exist:
   - `start.sh` → Sets up MySQL-based auth with system permissions
   - `update-guac-admin.sh` → Sets up XML-based auth

2. **Database permissions table might be empty** even after setup
   - The `guacamole_system_permission` table needs the `ADMINISTER` entry
   - Without it, the user is created but has no permissions

3. **Guacamole caches permissions** in memory
   - Changes to the database don't take effect until Tomcat restarts
   - Old permissions can persist after changes

## How to Test Locally

### Option 1: Use the Diagnostic Script (Recommended)

```bash
# Inside the container:
docker exec ocvpn-guac bash /path/to/test-admin-permissions.sh

# Or locally if running natively:
./test-admin-permissions.sh
```

This will show:
- ✓ Current authentication configuration (MySQL or XML)
- ✓ All users in the database
- ✓ Permissions assigned to each user
- ✓ Database connectivity status
- ✓ Recent Guacamole logs
- ✓ Web interface status

### Option 2: Manual Database Query

```bash
# Get guacadmin's entity ID
ENTITY_ID=$(mysql -u root guacamole -se \
    "SELECT entity_id FROM guacamole_entity \
     WHERE name='guacadmin' AND type='USER';")

echo "Entity ID: $ENTITY_ID"

# Check permissions
mysql -u root guacamole -e \
    "SELECT * FROM guacamole_system_permission \
     WHERE entity_id=$ENTITY_ID;"
```

**Expected output:** Shows row with `ADMINISTER` permission

**If empty:** Permission is missing → proceed to fix

## How to Fix

### Quick Fix (Immediate)

Use the provided quick-fix script:

```bash
# Inside container:
docker exec ocvpn-guac bash /path/to/fix-admin-permissions.sh

# Or locally if running natively:
./fix-admin-permissions.sh
```

This script:
1. Finds the guacadmin user
2. Checks current permissions
3. Grants `ADMINISTER` permission
4. Restarts Guacamole
5. Verifies the fix

### Manual Fix

```bash
#!/bin/bash

# 1. Get guacadmin's entity ID
ENTITY_ID=$(mysql -u root guacamole -se \
    "SELECT entity_id FROM guacamole_entity \
     WHERE name='guacadmin' AND type='USER';")

# 2. Clear old permissions and insert ADMINISTER
mysql -u root guacamole -e "
    DELETE FROM guacamole_system_permission 
    WHERE entity_id=$ENTITY_ID;
    
    INSERT INTO guacamole_system_permission 
    (entity_id, permission) 
    VALUES ($ENTITY_ID, 'ADMINISTER');
"

# 3. Restart Guacamole to apply
supervisorctl -c /etc/supervisor/supervisord.conf restart tomcat

# 4. Wait for restart
sleep 5

# 5. Verify
mysql -u root guacamole -e \
    "SELECT * FROM guacamole_system_permission \
     WHERE entity_id=$ENTITY_ID;"
```

## Verify the Fix Works

After applying the fix:

1. **Clear browser cache:**
   - Chrome/Firefox: Ctrl+Shift+Del
   - Safari: Cmd+Shift+Delete

2. **Log out completely** from Guacamole
   - Go to top-right corner, click logout

3. **Log back in** as guacadmin/guacadmin

4. **Look for "Administration" menu** at the top
   - If visible → ✓ Fix worked!
   - If not visible → Proceed to Advanced Troubleshooting

## Advanced Troubleshooting

### Still no admin after fix?

**Check 1: Browser cache**
```javascript
// Open browser console (F12) and try:
localStorage.clear()
sessionStorage.clear()
// Then refresh page
```

**Check 2: Authentication backend**
```bash
# Verify only MySQL auth is active
cat /root/.guacamole/guacamole.properties | grep -E "auth|mysql"

# Should show MySQL config, NOT xml auth
```

**Check 3: Tomcat not actually restarted**
```bash
# Force restart
supervisorctl -c /etc/supervisor/supervisord.conf restart tomcat

# OR direct restart
ps aux | grep tomcat
kill -9 <pid>
# Tomcat will auto-restart via supervisor
```

**Check 4: Multiple permission entries causing conflicts**
```bash
ENTITY_ID=$(mysql -u root guacamole -se \
    "SELECT entity_id FROM guacamole_entity \
     WHERE name='guacadmin' AND type='USER';")

# List all permissions for this user
mysql -u root guacamole -e \
    "SELECT COUNT(*), permission FROM guacamole_system_permission \
     WHERE entity_id=$ENTITY_ID \
     GROUP BY permission;"

# Should show only 1 row: ADMINISTER
# If multiple, run fix script again
```

## Long-term Solution

Updated `start.sh` now includes:

1. **Better verification** of permission insertion
2. **Explicit Tomcat restart** to clear caches
3. **Error detection** if insertion fails
4. **Database state checking** if something goes wrong

This should prevent the issue in new container deployments.

## Files Added for Support

| File | Purpose |
|------|---------|
| `test-admin-permissions.sh` | Comprehensive diagnostic tool |
| `fix-admin-permissions.sh` | Quick fix with verification |
| `ADMIN_PERMISSIONS_TROUBLESHOOTING.md` | Detailed troubleshooting guide |
| `allin1/start.sh` (updated) | Improved permission setup |

## Testing in Docker

```bash
# Build and run container
docker build -t ocvpn-test:latest -f Dockerfile.allin1 .
docker run -d --name test-ocvpn --privileged \
  -p 8080:8080 -p 9000:9000 \
  -e GUAC_DEFAULT_USER=testadmin \
  -e GUAC_DEFAULT_PASS=testpass123 \
  ocvpn-test:latest

# Wait for startup (30-60 seconds)
sleep 60

# Run diagnostics
docker exec test-ocvpn bash /app/test-admin-permissions.sh

# Run fix if needed
docker exec test-ocvpn bash /app/fix-admin-permissions.sh

# Test login
# Open http://localhost:8080/guacamole
# Use testadmin/testpass123
# Should see Administration menu
```

## Quick Reference Commands

```bash
# Show all users and their permissions
mysql -u root guacamole -e "
    SELECT 
        e.name, 
        GROUP_CONCAT(sp.permission SEPARATOR ', ') as permissions
    FROM guacamole_entity e
    LEFT JOIN guacamole_system_permission sp 
        ON e.entity_id = sp.entity_id
    WHERE e.type='USER'
    GROUP BY e.entity_id;
"

# Grant all admin permissions to a user
mysql -u root guacamole -e "
    INSERT IGNORE INTO guacamole_system_permission 
    (entity_id, permission) 
    SELECT entity_id, 'ADMINISTER' 
    FROM guacamole_entity 
    WHERE name='USERNAME' AND type='USER';
"

# List all available system permissions
mysql -u root guacamole -e "
    SELECT DISTINCT permission 
    FROM guacamole_system_permission 
    ORDER BY permission;
"

# Restart Guacamole
supervisorctl -c /etc/supervisor/supervisord.conf restart tomcat

# Monitor Guacamole startup
tail -f /var/log/supervisor/tomcat.out.log
```

