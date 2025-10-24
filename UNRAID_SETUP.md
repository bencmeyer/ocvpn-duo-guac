# Unraid Setup Guide - OpenConnect VPN + Guacamole

Complete step-by-step guide for deploying the all-in-one OpenConnect VPN + Guacamole container on Unraid.

## System Requirements

- **Unraid 6.9+** with Docker support enabled
- **Memory:** 256 MB minimum, 512 MB recommended
- **Storage:** ~5 GB available for container
- **Network:** Internet connection for pulling image
- **Ports:** 8080 and 9000 available

## Image Details

**All-in-One Container:**
- **Image:** `openconnect-vpn-all:latest` (815 MB)
- **Base:** Alpine Linux (jasonbean/guacamole)
- **Includes:** OpenConnect VPN + Guacamole + MariaDB + supervisord
- **Ports:** 8080 (Guacamole), 9000 (openconnect-web)

**Standalone VPN:**
- **Image:** `openconnect-vpn:latest` (187 MB) - Alternative for VPN-only
- **Base:** Debian Bullseye Slim
- **Includes:** OpenConnect VPN only

## Deployment Method 1: Docker Compose (Recommended)

### Step 1: SSH into Unraid
```bash
ssh root@unraid-ip
```

### Step 2: Create Configuration File
```bash
cat > .env << 'EOF'
# REQUIRED - Your VPN credentials
VPN_USER=your_netid
VPN_PASS=your_password

# OPTIONAL - VPN Server Settings (defaults work for Illinois)
VPN_SERVER=vpn.illinois.edu
VPN_AUTHGROUP=OpenConnect1 (Split)
DUO_METHOD=push
DNS_SERVERS=130.126.2.131

# OPTIONAL - Guacamole Settings
DEBUG=false
GUACAMOLE_ADMIN_USER=admin
GUACAMOLE_ADMIN_PASS=admin
EOF
```

### Step 3: Deploy
```bash
docker-compose -f docker-compose-allin1.yml up -d
```

### Step 4: Verify
```bash
docker logs openconnect-vpn | tail -20
```

---

## Deployment Method 2: Unraid Web UI

### Step 1: Pull Image
Open Unraid terminal:
```bash
docker pull openconnect-vpn-all:latest
```

### Step 2: Add Container
1. Dashboard → Docker
2. Click **Add Container**
3. Select: `openconnect-vpn-all:latest`
4. Name: `openconnect-vpn`
5. Click **Advanced view**

### Step 3: Set Environment Variables
| Variable | Value |
|----------|-------|
| VPN_USER | your_netid |
| VPN_PASS | your_password |
| VPN_SERVER | vpn.illinois.edu |
| VPN_AUTHGROUP | OpenConnect1 (Split) |
| DUO_METHOD | push |
| DNS_SERVERS | 130.126.2.131 |

### Step 4: Configure Network
- **Privileged:** ON
- **Port 8080** → Host Port 8080
- **Port 9000** → Host Port 9000

### Step 5: Create
Click **Create** button

---

## Deployment Method 3: Export from Build Machine

If deploying from your build machine to Unraid:

### Export Image
```bash
docker save -o openconnect-vpn-all.tar openconnect-vpn-all:latest
```

### Transfer to Unraid
```bash
scp openconnect-vpn-all.tar root@unraid-ip:/mnt/user/appdata/
```

### Load on Unraid
```bash
ssh root@unraid-ip
docker load -i /mnt/user/appdata/openconnect-vpn-all.tar
```

---

## Post-Installation Verification

### Check Container is Running
```bash
docker ps | grep openconnect
```

### View Startup Logs
```bash
docker logs openconnect-vpn | tail -50
```

Should show:
- `supervisord started`
- `guacd` and `tomcat` processes started
- `Connected as 10.x.x.x` (VPN connection confirmed)

### Verify VPN Connection
```bash
docker exec openconnect-vpn ip addr show | grep tun
```

Should output: `tun0: <UP,LOWER_UP>`

### Test DNS
```bash
docker exec openconnect-vpn nslookup fandsu025.ad.uillinois.edu
```

Should resolve to an internal IP

---

## Accessing the Services

### Guacamole Web UI
- **URL:** `http://unraid-ip:8080`
- **Username:** admin (default)
- **Password:** admin (default)
- **Function:** Remote desktop gateway for RDP/SSH/VNC

### openconnect-web UI
- **URL:** `http://unraid-ip:9000`
- **Function:** VPN connection monitor and control

---

## Configuration for Illinois VPN

### Recommended Settings
```
VPN_USER: Your NetID
VPN_PASS: Your password (with special chars OK)
VPN_SERVER: vpn.illinois.edu
VPN_AUTHGROUP: OpenConnect1 (Split)
DUO_METHOD: push
DNS_SERVERS: 130.126.2.131
```

### Change Duo Method
- `push` - Push notification to Duo app (default, no waiting)
- `phone` - Phone call (old method, requires manual interaction)
- `sms` - SMS text message code (slower)

---

## Troubleshooting

### Container Won't Start

**Check status:**
```bash
docker ps -a | grep openconnect
```

**View detailed error:**
```bash
docker logs openconnect-vpn
```

**Common fixes:**

| Error | Fix |
|-------|-----|
| `Operation not permitted` | Enable Privileged mode in Docker settings |
| `Port 8080 already in use` | Change port mapping to 8081:8080 |
| Missing env variable | Add VPN_USER and VPN_PASS |

**Recovery:**
```bash
docker stop openconnect-vpn
# Fix the issue
docker start openconnect-vpn
```

### VPN Won't Connect

**Check logs:**
```bash
docker logs openconnect-vpn | grep -i "error\|auth\|fail\|connect"
```

**Common issues:**
1. **Wrong credentials:**
   - Test outside VPN with official Cisco client
   - Verify special chars are correct

2. **Duo 2FA not approved:**
   - Check Duo app for pending push
   - Try SMS method: `-e DUO_METHOD=sms`

3. **Wrong VPN settings:**
   - Verify VPN_SERVER and VPN_AUTHGROUP with IT

**Enable debug for more info:**
```bash
# Edit container environment
docker stop openconnect-vpn
# In Unraid: Edit container, add DEBUG=true
# Or with docker-compose: add DEBUG: "true" to .env
docker start openconnect-vpn
```

### Can't Access Guacamole (Port 8080)

**Test connectivity:**
```bash
curl -I http://localhost:8080
```

**Check port mapping:**
```bash
docker ps | grep openconnect-vpn
# Should show: 0.0.0.0:8080->8080/tcp
```

**Solutions:**
1. Wait 30-60 seconds after container starts (MariaDB initialization)
2. Check port isn't blocked by firewall
3. Try different port: Edit container, change 8080 to 8081

### DNS Not Resolving

**Verify DNS setting:**
```bash
docker exec openconnect-vpn cat /etc/resolv.conf
```

**Test specific DNS:**
```bash
docker exec openconnect-vpn nslookup domain.com 130.126.2.131
```

**Fixes:**
- For Illinois: ensure DNS_SERVERS=130.126.2.131
- For other domains: ask IT for correct DNS server
- Try different format: `DNS_SERVERS="10.0.0.1 10.0.0.2"`

### VPN Disconnects/Session Expires

**Expected behavior:** VPN sessions typically expire after 24 hours

**Auto-restart on disconnect:**
1. In Unraid: Docker → Container → openconnect-vpn
2. Edit → Restart Policy → Always
3. Apply

Or with compose:
```yaml
restart: unless-stopped  # Already default
```

### Slow Performance

**Check resource usage:**
```bash
docker stats openconnect-vpn
```

**If using excessive memory (>500 MB):**
1. Stop container
2. Remove MariaDB volume: `docker volume rm openconnect-vpn_guacamole_db`
3. Restart (will initialize fresh)

---

## Maintenance

### Backup Guacamole Configuration

**Database backup:**
```bash
docker exec openconnect-vpn \
  mysqldump -u guacamole -pguacamole guacamole_db \
  > /mnt/user/appdata/guacamole_backup.sql
```

**Configuration backup:**
```bash
docker cp openconnect-vpn:/config \
  /mnt/user/appdata/guacamole_config_backup
```

### View Container Logs

**Last 50 lines:**
```bash
docker logs openconnect-vpn | tail -50
```

**Follow live logs:**
```bash
docker logs -f openconnect-vpn
```
(Ctrl+C to exit)

**Search for errors:**
```bash
docker logs openconnect-vpn | grep -i error
```

### Restart Container

**Quick restart:**
```bash
docker restart openconnect-vpn
```

**Or via Unraid UI:**
1. Docker tab → Container → openconnect-vpn
2. Click **Stop** then **Start**

### Update Container

**Get latest image:**
```bash
docker pull openconnect-vpn-all:latest
```

**Stop and remove old container:**
```bash
docker stop openconnect-vpn
docker rm openconnect-vpn
```

**Redeploy with docker-compose:**
```bash
docker-compose -f docker-compose-allin1.yml up -d
```

---

## Security Best Practices

1. **Change Guacamole admin password immediately**
   - Guacamole UI → Settings → Users → admin

2. **Use strong, unique passwords**
   - Don't reuse your VPN password elsewhere

3. **Restrict access**
   - Firewall rules to limit port 8080 access
   - Or use Unraid's WebUI authentication

4. **Never share credentials**
   - Keep .env file secure
   - Don't add to version control

5. **Monitor for suspicious activity**
   - Review Guacamole user logs regularly
   - Check container logs for failed auth attempts

6. **Backup important data**
   - Export Guacamole connections regularly
   - Backup MariaDB database

---

## Performance Tips

### For Slow Internet

**Reduce RDP quality:**
- Guacamole connection → RDP settings
- Reduce color depth to 16-bit
- Enable compression

**Monitor bandwidth:**
```bash
docker exec openconnect-vpn iftop -i tun0
```

### For High CPU Usage

Usually indicates:
- Active file transfer
- Video streaming over RDP
- Multiple simultaneous connections

Monitor with: `docker stats openconnect-vpn`

### For Memory Issues

- Typical: 200-300 MB
- Per active RDP: +50-100 MB
- If too high: Increase Unraid system RAM or restart container

---

## Advanced Configuration

### Multiple VPN Connections

Deploy additional containers:
```bash
docker run -d --name=vpn-client-2 \
  --privileged \
  -p 8081:8080 -p 9001:9000 \
  -e VPN_USER='other_user' \
  -e VPN_PASS='other_pass' \
  openconnect-vpn-all:latest
```

### Custom DNS for Different Domains

Some internal domains may need different DNS:
```bash
# Can only set one DNS_SERVERS value per container
# For multiple domains, contact IT or use internal DNS forwarders
```

### Persistent Configuration

Store Guacamole config on Unraid share:
```bash
# In Unraid Docker settings for this container:
# Add volume: /config → /mnt/user/appdata/guacamole_config
```

---

## Support & Getting Help

### Check These First
1. Troubleshooting section above
2. Container logs: `docker logs openconnect-vpn`
3. README.md in this project
4. QUICKSTART.md for quick reference

### Getting Help
- **Unraid:** https://forums.unraid.net/
- **OpenConnect:** https://www.infradead.org/openconnect/
- **Guacamole:** https://guacamole.apache.org/doc/gug/
- **VPN Issues:** Contact your IT department

### Report Issues

When seeking help, provide:
- Unraid version
- Container logs (with passwords redacted)
- Error messages
- Steps to reproduce
- Environment variables (redacted)

---

## What's Next

1. ✅ Container deployed and verified
2. ✅ VPN connected
3. ✅ Guacamole accessible at port 8080
4. **Add RDP connections** to internal servers
5. **Create Guacamole users** for team members
6. **Configure backups** for Guacamole settings
7. **Monitor** over time for stability

---

## File Reference

| File | Purpose |
|------|---------|
| `docker-compose-allin1.yml` | All-in-one deployment config |
| `.env` | Your configuration (credentials, VPN settings) |
| `README.md` | Complete documentation |
| `QUICKSTART.md` | Quick reference guide |
| `LICENSE` | MIT license |

Transfer the `connect-vpn.sh` and `Dockerfile` to Unraid, then build directly:

```bash
docker build -t vpn-test:latest .
```

---

## Running on Unraid

### Via Command Line:
```bash
docker run -e VPN_USER='your-username' -e VPN_PASS='your-password-with-special-chars' vpn-test:latest
```

### Via Unraid Web UI:
1. Go to **Docker** tab
2. Click **Add Container**
3. Set **Repository**: `vpn-test:latest` (or `<your-username>/vpn-test:latest` if using Docker Hub)
4. Add Environment Variables:
   - `VPN_USER` = your username
   - `VPN_PASS` = your password (use single quotes in scripts to protect special chars)
5. Configure other settings as needed
6. Click **Create**

---

## Environment Variables

**Required**:
- `VPN_USER`: Your VPN username
- `VPN_PASS`: Your VPN password (supports special characters like `!`, `@`, etc.)

The script automatically:
- Handles the first password prompt with your password
- Sends "push" on the second prompt for MFA/Duo authentication
- Disables bash history expansion to safely handle special characters
- Dumps HTTP traffic for debugging

---

## Notes for Unraid

- The container runs and exits after establishing the connection
- If you want persistent VPN, consider using a wrapper script with retry logic
- The `--dump-http-traffic` flag logs HTTP requests for debugging
- All output will be logged in Unraid's Docker container logs
