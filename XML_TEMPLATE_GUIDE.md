# Unraid XML Template Installation Guide

## Where Does the XML Template Go?

The `vpn-connect.xml` file is an Unraid container template that makes deploying the all-in-one VPN container super easy through the Unraid web UI.

### Installation Steps

#### Option 1: Manual Copy (Recommended)

**Step 1:** Locate the templates directory on Unraid:
```bash
# Path on Unraid filesystem:
/boot/config/plugins/dockerMan/templates-user/
```

**Step 2:** Copy the XML file:
```bash
# From your build machine:
scp vpn-connect.xml root@unraid-ip:/boot/config/plugins/dockerMan/templates-user/

# OR from Unraid terminal:
cd /boot/config/plugins/dockerMan/templates-user/
wget https://path/to/vpn-connect.xml
```

**Step 3:** Reload Unraid Docker UI:
- Go to **Docker** tab in Unraid
- The template should appear in the "Add Container" dropdown
- If not visible, refresh browser (F5)

---

#### Option 2: Via Unraid Terminal

```bash
ssh root@unraid-ip

# Create directory if it doesn't exist
mkdir -p /boot/config/plugins/dockerMan/templates-user/

# Copy the file
cp vpn-connect.xml /boot/config/plugins/dockerMan/templates-user/

# Or download directly
cd /boot/config/plugins/dockerMan/templates-user/
wget https://your-server/vpn-connect.xml

# Restart Docker (optional, but recommended)
# Go to Unraid UI: Settings → Docker → Restart Docker
```

---

#### Option 3: Through Unraid Web UI

Some NAS storage solutions support uploading files directly through the web interface:
1. Go to **Tools** → **Terminal**
2. Paste the copy command above
3. Or use a file manager if available

---

## After Installing the Template

### Access the Template

1. Go to **Docker** tab in Unraid
2. Click **Add Container**
3. In the template dropdown, you should now see: **openconnect-vpn**
4. Click it to select

### Fill in Configuration

The template will show these fields:

**Required (Must Fill):**
- **VPN Username** - Your NetID or username
- **VPN Password** - Your password (masked)

**Optional (Pre-filled with defaults):**
- **VPN Server** - Default: `vpn.illinois.edu`
- **Auth Group** - Default: `OpenConnect1 (Split)`
- **Duo Method** - Default: `push`
- **DNS Servers** - Default: `130.126.2.131`

**Advanced (Usually leave as-is):**
- **Debug** - Leave as `false` unless troubleshooting
- **Guacamole Admin User** - Default: `admin`
- **Guacamole Admin Pass** - Default: `admin` (CHANGE THIS!)

### Click Create

The template will:
- ✅ Set container name to `openconnect-vpn`
- ✅ Pull image `openconnect-vpn-all:latest`
- ✅ Enable Privileged mode
- ✅ Map ports 8080 and 9000
- ✅ Set all environment variables
- ✅ Create the container with one click!

---

## Template Features

### What the Template Does

✅ **One-Click Deployment** - No need to manually set every option  
✅ **Pre-configured Defaults** - Illinois VPN already set up  
✅ **Input Validation** - Required fields highlighted  
✅ **Port Mapping** - 8080 (Guacamole) and 9000 (VPN monitor) pre-mapped  
✅ **Security Options** - Privileged mode enabled for TUN device  
✅ **Environment Variables** - All VPN settings properly configured  

### Security Notes

- **VPN_PASS field is masked** - Doesn't show in logs
- **Guacamole passwords masked** - Default credentials shown as asterisks in UI
- **Template doesn't save passwords** - Only when container is created

---

## File Structure

```
Unraid System
├── /boot/config/
│   └── plugins/
│       └── dockerMan/
│           ├── templates-user/
│           │   └── vpn-connect.xml  ← YOUR FILE GOES HERE
│           └── templates/
│               └── (built-in templates)
```

---

## Verification

### Check Template Installation

**From Unraid terminal:**
```bash
ls -la /boot/config/plugins/dockerMan/templates-user/
# Should show: vpn-connect.xml
```

**From Unraid web UI:**
1. Go to **Docker** → **Add Container**
2. Look in template dropdown
3. Should see **openconnect-vpn** listed

---

## Troubleshooting

### Template Not Showing in Dropdown

**Issue:** `vpn-connect.xml` file not found

**Solutions:**
1. Verify file is in correct directory:
   ```bash
   ls -la /boot/config/plugins/dockerMan/templates-user/vpn-connect.xml
   ```

2. Check file permissions (should be readable):
   ```bash
   chmod 644 /boot/config/plugins/dockerMan/templates-user/vpn-connect.xml
   ```

3. Restart Docker or refresh browser:
   - Browser: Press F5 to refresh
   - Unraid: Settings → Docker → Restart Docker

4. Verify file isn't corrupted:
   ```bash
   head /boot/config/plugins/dockerMan/templates-user/vpn-connect.xml
   # Should show: <?xml version="1.0"...
   ```

### Template Shows But Fields Wrong

**Issue:** Template displays but fields are not matching

**Solution:** Re-copy the latest `vpn-connect.xml`:
```bash
rm /boot/config/plugins/dockerMan/templates-user/vpn-connect.xml
scp vpn-connect.xml root@unraid-ip:/boot/config/plugins/dockerMan/templates-user/
```

### Container Created But Doesn't Start

**Issue:** Template created container but it exits immediately

**Solutions:**
1. Verify Privileged mode is enabled:
   - Docker tab → Container name → Edit
   - Check **Privileged: ON**

2. Check logs:
   ```bash
   docker logs openconnect-vpn | tail -50
   ```

3. Verify ports 8080/9000 are available:
   ```bash
   netstat -tlnp | grep -E '8080|9000'
   ```

---

## Alternative: No Template (Manual Setup)

If you prefer not to use the template, you can still deploy using:

**Option A: Docker Compose**
```bash
docker-compose -f docker-compose-allin1.yml up -d
```

**Option B: Docker Run**
```bash
docker run -d --privileged \
  -p 8080:8080 -p 9000:9000 \
  -e VPN_USER='your_user' \
  -e VPN_PASS='your_pass' \
  openconnect-vpn-all:latest
```

**Option C: Unraid UI Without Template**
1. Docker → Add Container
2. Select image: `openconnect-vpn-all:latest`
3. Manually fill in all environment variables
4. Manually set ports and privileged mode

---

## Summary

| Task | Steps | Time |
|------|-------|------|
| **Copy XML** | `scp vpn-connect.xml root@unraid-ip:/boot/config/plugins/dockerMan/templates-user/` | 1 min |
| **Refresh UI** | Browser F5 or restart Docker | 1 min |
| **Deploy** | Docker → Add Container → Select template → Fill fields → Create | 2 min |
| **Verify** | Access http://unraid-ip:8080 | 1 min |
| **Total** | | **5 minutes** |

---

## Template Contents

The `vpn-connect.xml` file includes:

✅ **Container Configuration**
- Image: `openconnect-vpn-all:latest`
- Privileged mode enabled
- Network: bridge
- Capabilities: NET_ADMIN, SYS_ADMIN, NET_RAW

✅ **Port Mappings**
- 8080 → Guacamole web UI
- 9000 → openconnect-web monitor

✅ **Environment Variables**
- VPN_USER (required)
- VPN_PASS (required, masked)
- VPN_SERVER (pre-filled)
- VPN_AUTHGROUP (pre-filled)
- DUO_METHOD (pre-filled)
- DNS_SERVERS (pre-filled)
- DEBUG (advanced)
- GUACAMOLE_ADMIN_USER (advanced)
- GUACAMOLE_ADMIN_PASS (advanced, masked)

✅ **Documentation**
- Tooltips for each field
- Quick setup instructions
- Port information

---

## Next Steps

1. **Install template** - Copy `vpn-connect.xml` to Unraid
2. **Create container** - Use template from Docker UI
3. **Configure** - Fill in VPN credentials
4. **Deploy** - Click Create button
5. **Access** - Open http://unraid-ip:8080
6. **Change password** - Settings → Users → admin (IMPORTANT!)

---

**Questions?** See the main documentation:
- `README.md` - Full documentation
- `QUICKSTART.md` - 5-minute setup
- `UNRAID_SETUP.md` - Detailed Unraid guide
