# Admin Access Fix - Complete Solution Guide

## Your Situation

✅ Database shows `ADMINISTER` permission exists  
✅ Can log in as `guacadmin`  
❌ See "Settings" page, not "Administration" menu  
❌ Can't manage users, connections, or system settings  

## Root Cause

**Conflicting authentication backends:**

The container can be set up with TWO different auth methods:
1. **MySQL** - Permissions stored in database
2. **XML** - Permissions in `user-mapping.xml` file

If BOTH exist, **XML takes precedence and overrides MySQL permissions**.

The startup script sets up MySQL backend with admin permissions, but if `user-mapping.xml` exists without proper admin attributes, you get regular user access only.

---

## Solution: 3 Steps to Fix

### STEP 1: Diagnose What's Configured

Copy-paste this in your terminal (works if container is named `ocvpn-guac`):

```bash
docker exec ocvpn-guac bash << 'EOF'
echo "=== Quick Diagnosis ==="
echo ""
echo "1. XML Backend:"
[ -f /root/.guacamole/user-mapping.xml ] && echo "   EXISTS (potential issue)" || echo "   Not found (good)"

echo ""
echo "2. MySQL Config:"
grep "^mysql-hostname" /root/.guacamole/guacamole.properties && echo "   ✓ Configured" || echo "   ✗ Missing"

echo ""
echo "3. Admin Permission:"
ENTITY_ID=$(mysql -u root guacamole -se "SELECT entity_id FROM guacamole_entity WHERE name='guacadmin' AND type='USER';" 2>/dev/null)
if [ -n "$ENTITY_ID" ]; then
    mysql -u root guacamole -se "SELECT permission FROM guacamole_system_permission WHERE entity_id=$ENTITY_ID;" 2>/dev/null || echo "   No permissions found"
else
    echo "   User not in database"
fi
EOF
```

### STEP 2: Apply the Fix

**If XML file exists**, remove it:

```bash
docker exec ocvpn-guac rm -f /root/.guacamole/user-mapping.xml
```

**Then hard restart Guacamole:**

```bash
docker exec ocvpn-guac bash << 'EOF'
echo "Stopping services..."
supervisorctl -c /etc/supervisor/supervisord.conf stop all
sleep 2

echo "Killing Java processes..."
pkill -9 java
sleep 2

echo "Clearing cache..."
rm -rf /opt/guacamole/work/*
rm -rf /var/lib/tomcat/work/*
sleep 1

echo "Starting fresh..."
supervisorctl -c /etc/supervisor/supervisord.conf start all
sleep 10

echo "Checking status..."
curl -s http://localhost:8080/guacamole/ | head -3 | grep -q "DOCTYPE\|html" && echo "✓ Guacamole started" || echo "⚠ May still be loading"
EOF
```

### STEP 3: Clear Browser Cache & Test

1. **Close browser completely** (not just tabs)
2. **Press `Ctrl+Shift+Delete`** (Windows/Linux) or **`Cmd+Shift+Delete`** (Mac)
3. Select **"All time"**
4. Check both:
   - Cookies and site data
   - Cached images and files
5. Click **"Clear data"**
6. **Close browser** completely
7. **Reopen browser**
8. Go to **`http://YOUR_IP:8080/guacamole`**
9. Login as **`guacadmin / guacadmin`**
10. **Look for "Administration" menu** at the top right

✅ **If you see "Administration" → FIXED!**

---

## If Still Not Working

### Try These Checks

**Check 1: Is user-mapping.xml still gone?**
```bash
docker exec ocvpn-guac test -f /root/.guacamole/user-mapping.xml && echo "Still exists!" || echo "Good - removed"
```

**Check 2: Is Tomcat really running?**
```bash
docker exec ocvpn-guac ps aux | grep -i tomcat | grep -v grep
```

**Check 3: Can you reach Guacamole?**
```bash
docker exec ocvpn-guac curl -I http://localhost:8080/guacamole/
```

**Check 4: Are there errors in logs?**
```bash
docker exec ocvpn-guac tail -30 /var/log/supervisor/tomcat.err.log
```

### Try Different Browser

Try a completely different browser:
- If using Chrome → try Firefox
- If using Firefox → try Safari
- If using Safari → try Edge

### Try Incognito Mode

Even after clearing cache, incognito is more aggressive:
- Chrome: `Ctrl+Shift+N`
- Firefox: `Ctrl+Shift+P`
- Safari: `Cmd+Shift+N`
- Edge: `Ctrl+Shift+InPrivate`

---

## Alternative: Use XML Backend Instead

If you prefer to keep XML backend instead of MySQL:

**Edit `user-mapping.xml`:**

```bash
docker exec ocvpn-guac cat > /root/.guacamole/user-mapping.xml << 'XMLEOF'
<user-mapping>
    <authorize username="guacadmin" 
               password="guacadmin"
               admin="true"
               administer="true"
               create="true"
               delete="true"
               update="true">
        <!-- Admin with full permissions -->
    </authorize>
</user-mapping>
XMLEOF
```

**Then disable MySQL in guacamole.properties:**

```bash
docker exec ocvpn-guac bash << 'EOF'
# Comment out MySQL settings
sed -i 's/^mysql-/#&/g' /root/.guacamole/guacamole.properties

# Enable XML auth
echo "auth-provider: xml" >> /root/.guacamole/guacamole.properties
echo "xml-root: /root/.guacamole" >> /root/.guacamole/guacamole.properties

# Restart
supervisorctl -c /etc/supervisor/supervisord.conf restart tomcat
EOF
```

Then test (wait 10 seconds, clear cache, log in).

---

## Long-term Fix for the Project

The project should standardize on ONE authentication method:

**Recommended:** Use MySQL only
- More maintainable
- Works with Guacamole's admin UI for user management
- Easier to automate
- Better for Docker/containers

**Changes needed:**
1. Remove `update-guac-admin.sh` entirely
2. Keep only `start.sh` with MySQL setup
3. Delete `user-mapping.xml` from container
4. Remove XML settings from `guacamole.properties`

---

## Quick Reference

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| See Settings, not Administration | XML backend exists without admin attributes | Remove user-mapping.xml |
| Permission says ADMINISTER but still no admin | Permission cache not cleared | Restart Tomcat, clear browser cache |
| XML file fixed but still not admin | Browser cache | Clear cache, try different browser |
| Restarted but Tomcat won't start | Port in use or bad config | Check logs, kill remaining Java |

---

## Files in Repo for Reference

- `CONTAINER_DIAGNOSIS_GUIDE.md` - Detailed diagnosis instructions
- `diagnose-in-container.sh` - Automated diagnostic script
- `FIX_SETTINGS_NOT_ADMIN.md` - Detailed fix guide
- `critical-diagnosis.sh` - Advanced diagnostics
- `emergency-fix-admin.sh` - Aggressive cache clear
- `allin1/start.sh` - Startup script (improved)

---

## TL;DR - Just Do This

```bash
# 1. Remove XML backend
docker exec ocvpn-guac rm -f /root/.guacamole/user-mapping.xml

# 2. Restart hard
docker exec ocvpn-guac bash << 'EOF'
supervisorctl -c /etc/supervisor/supervisord.conf stop all
sleep 2
pkill -9 java
sleep 2
supervisorctl -c /etc/supervisor/supervisord.conf start all
sleep 10
EOF

# 3. Clear browser cache (Ctrl+Shift+Delete), close browser, reopen
# 4. Log in to http://YOUR_IP:8080/guacamole
# 5. Should see "Administration" menu

# If not, run: docker exec ocvpn-guac bash /path/to/diagnose-in-container.sh
```

**Expected time to fix:** 5 minutes

