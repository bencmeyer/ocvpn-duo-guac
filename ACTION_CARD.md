# 🎯 YOUR ACTION CARD - Run This Now

## Problem
You see "Settings" not "Administration" menu in Guacamole, even though admin permission exists.

## Solution
The XML backend file is conflicting. Remove it and restart.

## DO THIS (Copy & Paste):

### Command 1: Remove XML Backend
```bash
docker exec ocvpn-guac rm -f /root/.guacamole/user-mapping.xml
```

### Command 2: Hard Restart Guacamole
```bash
docker exec ocvpn-guac bash << 'EOF'
supervisorctl -c /etc/supervisor/supervisord.conf stop all
sleep 2
pkill -9 java
sleep 2
supervisorctl -c /etc/supervisor/supervisord.conf start all
sleep 10
EOF
```

### Command 3: Browser Cache Clear
```
Press: Ctrl+Shift+Delete (Windows) or Cmd+Shift+Delete (Mac)
Select: All time
Check: Cookies + Cache
Click: Clear data
Close browser completely
Reopen browser
```

### Command 4: Test
```
Go to: http://YOUR_IP:8080/guacamole
Login: guacadmin / guacadmin
Look for: "Administration" menu at top
```

---

## If Still Not Working

Run this diagnostic:

```bash
docker exec ocvpn-guac bash << 'EOF'
echo "[1] XML file removed?"
[ -f /root/.guacamole/user-mapping.xml ] && echo "  NO - still exists" || echo "  YES - good"

echo ""
echo "[2] MySQL configured?"
grep "^mysql-hostname" /root/.guacamole/guacamole.properties && echo "  YES" || echo "  NO"

echo ""
echo "[3] Admin permission in DB?"
ENTITY_ID=$(mysql -u root guacamole -se "SELECT entity_id FROM guacamole_entity WHERE name='guacadmin' AND type='USER';" 2>/dev/null)
[ -n "$ENTITY_ID" ] && mysql -u root guacamole -se "SELECT permission FROM guacamole_system_permission WHERE entity_id=$ENTITY_ID;" 2>/dev/null || echo "  User not found"

echo ""
echo "[4] Guacamole responding?"
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:8080/guacamole/

EOF
```

Send me the output if it doesn't work.

---

## Full Documentation Available

- `FINAL_ADMIN_SOLUTION.md` - Complete guide
- `CONTAINER_DIAGNOSIS_GUIDE.md` - Detailed diagnosis
- `FIX_SETTINGS_NOT_ADMIN.md` - Technical details
- `critical-diagnosis.sh` - Advanced diagnostic script
- `diagnose-in-container.sh` - In-container diagnostic

All in the repository root.

---

## Expected Result
✅ See "Administration" menu  
✅ Can create connections  
✅ Can manage users  
✅ Full admin access

**Time to fix: 5 minutes**
