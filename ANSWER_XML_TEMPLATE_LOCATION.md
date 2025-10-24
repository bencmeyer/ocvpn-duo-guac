# Answer: Where Does the XML Template File Go?

## The Short Answer

**File:** `vpn-connect.xml`  
**Location on Unraid:** `/boot/config/plugins/dockerMan/templates-user/vpn-connect.xml`  
**What it does:** Makes deploying the container super easy through Unraid's web UI  

---

## Step-by-Step Installation

### Step 1: Copy the File to Unraid

From your build machine:
```bash
scp vpn-connect.xml root@unraid-ip:/boot/config/plugins/dockerMan/templates-user/
```

Or if you SSH into Unraid first:
```bash
ssh root@unraid-ip
# Create the directory if needed
mkdir -p /boot/config/plugins/dockerMan/templates-user/

# Then paste the vpn-connect.xml file there
# Or download it:
cd /boot/config/plugins/dockerMan/templates-user/
wget https://your-server/vpn-connect.xml
```

### Step 2: Refresh Your Browser

- Go to Unraid Dashboard
- Go to **Docker** tab
- Press **F5** to refresh (or clear cache with Ctrl+Shift+Del, then F5)

### Step 3: Use the Template

1. Click **Add Container**
2. In the template dropdown, select **openconnect-vpn**
3. Fill in:
   - **VPN Username:** your_netid
   - **VPN Password:** your_password
4. Other fields are pre-filled (Illinois VPN defaults)
5. Click **Create**

Done! The container will start with all correct settings.

---

## Full Directory Structure

On Unraid, the templates directory looks like this:

```
/boot/config/plugins/dockerMan/
├── templates/              (Unraid built-in templates - don't edit)
│   ├── emby.xml
│   ├── plex.xml
│   ├── nextcloud.xml
│   └── ...
│
└── templates-user/         ← PUT YOUR FILE HERE
    ├── vpn-connect.xml     ← YOUR NEW FILE
    ├── my-custom-app.xml
    └── ...
```

The key is: **`templates-user/` is where Unraid looks for custom templates**

---

## What's in the XML File?

The `vpn-connect.xml` file tells Unraid:

✅ **Container Info**
- Image name: `openconnect-vpn-all:latest`
- Needs privileged mode
- Needs special capabilities (NET_ADMIN, SYS_ADMIN, NET_RAW)

✅ **Port Mappings**
- Port 8080 → Guacamole web UI
- Port 9000 → openconnect-web monitor

✅ **Environment Variables (Pre-filled)**
```
VPN_SERVER=vpn.illinois.edu
VPN_AUTHGROUP=OpenConnect1 (Split)
DUO_METHOD=push
DNS_SERVERS=130.126.2.131
DEBUG=false
```

✅ **User Inputs (Required)**
- VPN_USER (your NetID)
- VPN_PASS (your password)

✅ **Nice Labels & Descriptions**
- Each field has a tooltip
- Shows what needs to be filled in
- Marks required vs optional

---

## Why Use the Template?

### Without Template (Manual):
1. Docker → Add Container
2. Select image: `openconnect-vpn-all:latest`
3. Set container name
4. Set network to bridge
5. Enable privileged mode
6. Add capabilities (NET_ADMIN, SYS_ADMIN, NET_RAW)
7. Map port 8080 → 8080
8. Map port 9000 → 9000
9. Add environment variable VPN_USER
10. Add environment variable VPN_PASS
11. Add environment variable VPN_SERVER
12. Add environment variable VPN_AUTHGROUP
13. Add environment variable DUO_METHOD
14. Add environment variable DNS_SERVERS
15. ... (many more steps)

**Total: 15+ manual steps** ❌

### With Template (Using XML):
1. Docker → Add Container
2. Select **openconnect-vpn** template
3. Fill VPN_USER
4. Fill VPN_PASS
5. Click Create

**Total: 5 clicks** ✅

---

## Verification Checklist

After copying the XML file:

- [ ] File exists: `ls /boot/config/plugins/dockerMan/templates-user/vpn-connect.xml`
- [ ] File is readable: File permissions should be 644
- [ ] File is valid XML: `head /boot/config/plugins/dockerMan/templates-user/vpn-connect.xml` should start with `<?xml`
- [ ] Template appears in Unraid UI: Docker → Add Container → dropdown shows "openconnect-vpn"

If template doesn't show:
1. Refresh browser (F5)
2. Restart Docker (Unraid Settings → Docker → Restart Docker)
3. Check file permissions: `chmod 644 /boot/config/plugins/dockerMan/templates-user/vpn-connect.xml`

---

## File Transfer Commands

### Command 1: SCP (Secure Copy)
```bash
# From your build machine:
scp vpn-connect.xml root@10.0.1.100:/boot/config/plugins/dockerMan/templates-user/

# Note: Replace 10.0.1.100 with your Unraid IP
```

### Command 2: SSH + Cat
```bash
# From your build machine:
ssh root@unraid-ip 'cat > /boot/config/plugins/dockerMan/templates-user/vpn-connect.xml' < vpn-connect.xml
```

### Command 3: SSH + Paste Content
```bash
ssh root@unraid-ip

# Then paste the entire XML file content into the terminal
# Or use wget to download from a server:
cd /boot/config/plugins/dockerMan/templates-user/
wget https://your-server/vpn-connect.xml
```

---

## File Persistence

**Good news:** The XML template is persistent!

- ✅ Survives Unraid reboots
- ✅ Stored on `/boot` partition
- ✅ Available after Unraid starts
- ✅ Can be shared/backed up
- ✅ No expiration or cleanup

**Recommendation:** Backup your templates
```bash
scp -r root@unraid-ip:/boot/config/plugins/dockerMan/templates-user/ ~/unraid-templates-backup/
```

---

## Using the Template vs Docker Compose

Both work! Choose based on your preference:

| Method | Pros | Cons |
|--------|------|------|
| **XML Template** | One-click setup, no CLI, all defaults pre-filled | Need to install XML file first |
| **Docker Compose** | Fast, scriptable, replicable | Need terminal access, need to manage .env file |
| **Manual Docker** | Direct control, no files needed | Many manual steps, easy to miss something |

**Recommendation:** Use XML template if you prefer Unraid's web UI 👍

---

## Updated XML Features

The `vpn-connect.xml` we provided includes:

✅ **All-in-One Container**
- Uses image: `openconnect-vpn-all:latest`
- Includes OpenConnect VPN + Guacamole + MariaDB

✅ **Pre-configured for Illinois VPN**
- Server: vpn.illinois.edu
- Auth group: OpenConnect1 (Split)
- Duo method: push (recommended)
- DNS: 130.126.2.131 (for internal domains)

✅ **Port Mappings**
- 8080 → Guacamole web UI (login: admin/admin)
- 9000 → openconnect-web monitor

✅ **Security**
- Privileged mode: enabled (needed for TUN device)
- Required capabilities: NET_ADMIN, SYS_ADMIN, NET_RAW
- Password fields: masked in web UI

✅ **Guacamole Credentials**
- Default admin user: admin
- Default admin password: admin
- **IMPORTANT:** Change these on first login!

---

## Common Questions

### Q: Can I use the template for other VPN servers?

**A:** Yes! After selecting the template:
1. The default values are Illinois VPN
2. You can change VPN_SERVER, VPN_AUTHGROUP, DNS_SERVERS
3. Your changes are saved in the container
4. Template remains unchanged for future use

### Q: What if I want to use both Docker Compose and Web UI?

**A:** You can! Both are independent:
- Docker Compose containers and Web UI containers don't interfere
- Just use different container names
- Both can use the same image

### Q: Can I share the XML template with others?

**A:** Absolutely! The XML file is:
- ✅ Shareable without credentials
- ✅ No secrets embedded
- ✅ Just plain configuration
- You can put it in a GitHub repo
- Others can copy it to their Unraid systems

### Q: How often do I need to update the XML file?

**A:** Only when:
- The container image changes significantly
- New environment variables are added
- Port mappings need to change
- For most users: Never (set it once and forget it)

---

## Summary

| Item | Details |
|------|---------|
| **File Name** | `vpn-connect.xml` |
| **Goes To** | `/boot/config/plugins/dockerMan/templates-user/` |
| **Installation** | `scp vpn-connect.xml root@unraid-ip:/boot/config/plugins/dockerMan/templates-user/` |
| **Uses** | OpenConnect VPN + Guacamole all-in-one |
| **Ports** | 8080 (Guacamole), 9000 (VPN monitor) |
| **Setup Time** | 1 minute to install, 2 minutes to deploy |
| **Persistence** | Survives reboots, stays on /boot partition |
| **Sharing** | Shareable, no credentials embedded |

---

## Next Steps

1. ✅ Copy `vpn-connect.xml` to Unraid using SCP or SSH
2. ✅ Refresh Unraid Docker web UI (F5)
3. ✅ Click **Add Container** and select **openconnect-vpn** template
4. ✅ Fill in VPN_USER and VPN_PASS
5. ✅ Click **Create**
6. ✅ Access http://unraid-ip:8080
7. ✅ Change admin password from admin/admin

**That's it! Your VPN + Guacamole gateway is ready.** 🎉

---

For more information:
- See `XML_TEMPLATE_GUIDE.md` for detailed help
- See `QUICKSTART.md` for deployment options
- See `UNRAID_SETUP.md` for troubleshooting
