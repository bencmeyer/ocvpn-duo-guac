# OpenConnect VPN Container with Guacamole Gateway

A production-ready all-in-one Docker container combining OpenConnect VPN client with Guacamole remote desktop gateway. Designed for **Unraid**, with optional multi-container deployment for other platforms.

## What's Included

**All-in-One Container** (Recommended for Unraid):
- 🔐 **OpenConnect VPN Client** - Cisco AnyConnect compatible
- 🖥️ **Guacamole Gateway** - RDP/SSH/VNC proxy for remote access through VPN
- 🌐 **openconnect-web UI** - Web-based VPN control and monitoring
- 📊 **MariaDB** - Guacamole connection database
- ✅ **Automatic MFA** - Duo 2FA support with configurable response
- 🔒 **Special Characters** - Passwords with !, @, #, $ fully supported

## Features

✅ **Single Container** - All services in one image (easy Unraid deployment)  
✅ **Secure Password Handling** - Supports special characters (!, @, #, $, etc.)  
✅ **Automatic MFA** - Auto-responds to Duo/2FA prompts  
✅ **Persistent Connection** - Maintains VPN tunnel indefinitely  
✅ **Configurable** - VPN server, auth group, DNS, Duo method all customizable  
✅ **Multi-VPN Support** - Works with any Cisco AnyConnect compatible VPN  
✅ **DNS Resolution** - Configure custom DNS for internal domain resolution  
✅ **Remote Gateway** - Use RDP/SSH/VNC through VPN tunnel via Guacamole  
✅ **Easy Unraid Integration** - One-click deployment from template  

## Quick Start (Unraid)

### Option A: Using Unraid Template (Easiest)
1. Add the container template to Unraid
2. Fill in VPN credentials
3. Click **Create**
4. Access Guacamole at `http://unraid-ip:8080`

### Option B: Manual Docker Command
```bash
docker run -d \
  --name=openconnect-vpn \
  --privileged \
  -p 8080:8080 \
  -p 9000:9000 \
  -e VPN_USER='netid' \
  -e VPN_PASS='P@ssw0rd!' \
  -e VPN_SERVER='vpn.illinois.edu' \
  -e VPN_AUTHGROUP='OpenConnect1 (Split)' \
  -e DUO_METHOD='push' \
  -e DNS_SERVERS='130.126.2.131' \
  openconnect-vpn-all:latest
```

### Option C: Docker Compose (Unraid Terminal)
See `docker-compose-allin1.yml` or run:
```bash
docker-compose -f docker-compose-allin1.yml up -d
```

---

## Configuration

### VPN Configuration (Required)

| Variable | Description | Example |
|----------|-------------|---------|
| `VPN_USER` | VPN username | `bcmeyer` or `user@company.com` |
| `VPN_PASS` | VPN password | `P@ssw0rd!` (special chars OK) |
| `VPN_SERVER` | VPN server hostname | `vpn.illinois.edu` |
| `VPN_AUTHGROUP` | Auth group/realm on VPN | `OpenConnect1 (Split)` |

### VPN Configuration (Optional)

| Variable | Default | Description |
|----------|---------|-------------|
| `DUO_METHOD` | `push` | Duo response: `push`, `phone`, or `sms` |
| `DNS_SERVERS` | `130.126.2.131` | Space-separated DNS servers |
| `DEBUG` | `false` | Set to `true` for verbose logs |

### Guacamole Configuration (Optional)

| Variable | Default | Description |
|----------|---------|-------------|
| `GUACAMOLE_ADMIN_USER` | `admin` | Web UI admin username |
| `GUACAMOLE_ADMIN_PASS` | `admin` | Web UI admin password |

### Common VPN Configurations

**Illinois VPN (University of Illinois):**
```
VPN_USER: Your NetID
VPN_PASS: Your password
VPN_SERVER: vpn.illinois.edu
VPN_AUTHGROUP: OpenConnect1 (Split)
DUO_METHOD: push
DNS_SERVERS: 130.126.2.131
```

**Generic Corporate VPN:**
```
VPN_USER: username
VPN_PASS: password
VPN_SERVER: vpn.company.com
VPN_AUTHGROUP: Corporate
DUO_METHOD: push (or phone/sms)
DNS_SERVERS: 10.0.0.1 10.0.0.2
```

---

## Usage

### Accessing Guacamole Web UI

Once the container is running:
1. Open browser to `http://unraid-ip:8080`
2. Login with default credentials (admin/admin)
3. Add RDP/SSH/VNC connections to internal servers
4. Access them through the VPN tunnel

### Accessing openconnect-web UI

Open browser to `http://unraid-ip:9000` to:
- Monitor VPN connection status
- Control VPN connection (start/stop)
- View VPN logs and diagnostics

### Check VPN Connection Status

```bash
docker exec openconnect-vpn ip addr show | grep tun
docker exec openconnect-vpn ip route
docker logs openconnect-vpn 2>&1 | tail -30
```

### Test DNS Resolution

```bash
docker exec openconnect-vpn nslookup internal.domain.com
```

### Test Network Connectivity

```bash
docker exec openconnect-vpn ping -c 1 10.0.0.1
```

---

## Deployment Options

### Recommended: All-in-One (Unraid)

**Image:** `openconnect-vpn-all:latest` (815 MB)  
**Best for:** Unraid users, single-container simplicity

Features:
- ✅ All services in one container
- ✅ Easy one-click Unraid deployment
- ✅ Minimal resource overhead
- ✅ Includes Guacamole + VPN + web UI

Deploy with:
```bash
docker-compose -f docker-compose-allin1.yml up -d
```

### Alternative: Multi-Container (Advanced)

**Images:** Separate guacamole, openconnect-web, vpn-client  
**Best for:** Non-Unraid users, microservices architecture

Features:
- ✅ Modular design, scale independently
- ✅ Better resource isolation
- ✅ Can replace individual components

Deploy with:
```bash
docker-compose -f docker-compose.yml up -d
```

### Minimal: Standalone VPN Only

**Image:** `openconnect-vpn:latest` (187 MB)  
**Best for:** Lightweight deployments, VPN-only use

Features:
- ✅ Smallest footprint
- ✅ VPN client only
- ✅ For other containers to route through

Deploy with:
```bash
docker run -d --name=vpn-client \
  --privileged \
  -e VPN_USER='user' \
  -e VPN_PASS='password' \
  openconnect-vpn:latest
```

---

---

## Troubleshooting

### Container Won't Start

**Check logs:**
```bash
docker logs openconnect-vpn
```

**Common issues:**
- `Operation not permitted` → Container needs `--privileged` flag
- `No such file or directory` → Volume mount path doesn't exist
- Port already in use → Change port mapping (e.g., `-p 8081:8080`)

### VPN Connection Fails

1. **Verify credentials:**
   - Test password outside VPN (doesn't have special chars stripped?)
   - Confirm VPN_USER format (some require `domain\user`)

2. **Check VPN server details:**
   ```bash
   docker logs openconnect-vpn | grep -i "connected\|error\|failed"
   ```

3. **Enable debug mode:**
   ```bash
   -e DEBUG=true
   ```
   Then check logs for detailed error messages

4. **Common mistakes:**
   - Quotes around password: use single quotes with special chars
   - VPN_SERVER not resolvable (add custom DNS)
   - Wrong VPN_AUTHGROUP name

### DNS Not Working

1. **Verify VPN is connected:**
   ```bash
   docker exec openconnect-vpn ip addr show | grep tun
   ```

2. **Test DNS directly:**
   ```bash
   docker exec openconnect-vpn nslookup domain.com 130.126.2.131
   ```

3. **Check DNS config in container:**
   ```bash
   docker exec openconnect-vpn cat /etc/resolv.conf
   ```

4. **For Illinois VPN:**
   - Ensure DNS_SERVERS is set to `130.126.2.131`
   - Some internal AD domains won't resolve with public DNS

### Guacamole Not Accessible

1. **Check port mapping:**
   ```bash
   docker ps | grep openconnect
   ```
   Should show `0.0.0.0:8080->8080/tcp`

2. **Test from host:**
   ```bash
   curl -I http://localhost:8080
   ```

3. **Reset admin password:**
   - Stop container, remove MariaDB volume, restart
   - Or login and change via web UI (Settings → Users)

### Session Expires / VPN Disconnects

**Expected behavior:** VPN sessions expire after 24 hours (depends on server)

**Auto-restart container:**
```bash
docker run --restart=unless-stopped \
  -e VPN_USER='user' \
  -e VPN_PASS='pass' \
  openconnect-vpn-all:latest
```

In Unraid: Set container restart policy to "Always"

---

## Security Notes

### Password Handling
- Passwords with special characters are fully supported
- Use single quotes when passing passwords on command line: `'P@ss!word'`
- In Unraid UI, passwords are masked in the web interface
- Never commit credentials to version control

### Best Practices
1. Use environment variables, not command-line arguments
2. Consider using secrets management for production
3. Don't share docker-compose files with embedded credentials
4. Review logs for sensitive information before sharing

---

---

## Unraid Setup Guide

### Prerequisites
- Unraid 6.9+ with Docker support enabled
- Internet connection for pulling image
- VPN credentials with Duo 2FA setup

### Installation Steps

1. **Pull the image** (in Unraid terminal):
   ```bash
   docker pull openconnect-vpn:all-latest
   # Or load from tar if offline:
   # docker load -i openconnect-vpn-all.tar
   ```

2. **Create container** via Docker UI:
   - Click `Add Container`
   - Select `openconnect-vpn-all:latest`
   - Set container name: `openconnect-vpn`
   - Fill in environment variables (see Configuration section)
   - Click `Advanced view`
   - Set Privileged: `On`
   - Set Port mappings: `8080` and `9000`
   - Click `Create`

3. **Start container** (auto-starts if set in settings)

4. **Verify connection:**
   - Check container logs: `docker logs openconnect-vpn`
   - Should see `Connected as 10.x.x.x` after ~30 seconds

5. **Access Guacamole:**
   - Open browser to `http://unraid-ip:8080`
   - Login: admin/admin
   - Add RDP/SSH connections to internal servers

### Unraid-Specific Troubleshooting

**Container stays in "starting" state:**
- Check Docker → Logs for the container
- Verify all required env variables are set
- Ensure Privileged mode is enabled

**Can't access port 8080:**
- In Unraid, check Shares → System → Docker Port Range
- May need to adjust port mapping if in use
- Default mapping: `8080:8080` (host:container)

**VPN keeps disconnecting:**
- Set Auto-restart policy to "Always" (Container settings)
- Check VPN session limit with provider (usually 24h)
- Enable DEBUG=true to see detailed logs

---

## Supported VPN Servers

This container works with:
- ✅ Illinois VPN (University of Illinois) - Tested
- ✅ Any Cisco AnyConnect compatible server
- ✅ Servers using Duo 2FA - Tested
- ✅ Servers using other OTP methods

Contact your VPN provider for:
- VPN_SERVER hostname
- VPN_AUTHGROUP name
- Authentication method details

---

## Image Information

### All-in-One Image (Recommended for Unraid)
- **Name:** `openconnect-vpn-all:latest`
- **Size:** 815 MB
- **Base OS:** Alpine Linux (via jasonbean/guacamole)
- **Components:** OpenConnect + Guacamole + MariaDB + supervisord
- **Requires:** Privileged mode, TUN device support

### Standalone VPN Image (Advanced Users)
- **Name:** `openconnect-vpn:latest`
- **Size:** 187 MB
- **Base OS:** Debian Bullseye Slim
- **Components:** OpenConnect only
- **Use case:** Lightweight, VPN-only, other containers route through

---

## Performance & Resources

### Recommended Unraid Settings
- CPU: Share with system (no reservation needed)
- RAM: 256 MB minimum, 512 MB recommended
- Storage: Mounts as read-only (no persistent data needed by default)

### Network Performance
- VPN throughput limited by server, not container
- Typical: 50-200 Mbps through Illinois VPN
- Low CPU overhead (~5-10% usage during activity)

---

## License & Attribution

- **OpenConnect:** https://www.infradead.org/openconnect/ (LGPL)
- **Guacamole:** https://guacamole.apache.org/ (Apache 2.0)
- **openconnect-web:** https://github.com/weikinhuang/openconnect-web (MIT)
- **Expect:** https://expect.sourceforge.net/ (Public Domain)
- **This project:** MIT License - See LICENSE file

---

## Support & Issues

**For help with:**

| Topic | Resource |
|-------|----------|
| This container | Check Troubleshooting section above or GitHub Issues |
| OpenConnect | https://www.infradead.org/openconnect/ |
| Guacamole | https://guacamole.apache.org/doc/gug/ |
| Your VPN | Contact your IT department or VPN provider |
| Unraid | https://forums.unraid.net/ |

**Contributing:** Found a bug? Have a feature request? Open an issue on GitHub!

---

## Changelog

### v1.0 (October 2025)
- ✅ Initial release
- ✅ All-in-one Unraid container
- ✅ Standalone VPN image
- ✅ Multi-container compose option
- ✅ Duo 2FA support
- ✅ Special character password handling
- ✅ Internal DNS resolution
- ✅ Guacamole gateway integration

