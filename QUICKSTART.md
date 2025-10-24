# Quick Start Guide - OpenConnect VPN with Guacamole

Get up and running in 5 minutes!

## For Unraid Users (Recommended)

### 1. Pull the Image
Open Unraid terminal and run:
```bash
docker pull openconnect-vpn:all-latest
```

### 2. Add Container via Web UI
1. Go to **Docker** → **Add Container**
2. Select image: `openconnect-vpn-all:latest`
3. Container name: `openconnect-vpn`
4. Click **Advanced view**

### 3. Set Environment Variables
Expand **Environment variables** section and fill in:

```
VPN_USER = your_username
VPN_PASS = your_password
VPN_SERVER = vpn.illinois.edu
VPN_AUTHGROUP = OpenConnect1 (Split)
DUO_METHOD = push
DNS_SERVERS = 130.126.2.131
```

### 4. Configure Network & Permissions
- **Privileged:** ON (required for TUN device)
- **Port mappings:**
  - Container Port 8080 → Host Port 8080 (Guacamole)
  - Container Port 9000 → Host Port 9000 (openconnect-web)

### 5. Click Create
Container should start automatically.

### 6. Verify Connection
Check logs:
```bash
docker logs openconnect-vpn | tail -20
```

You should see: `Connected as 10.x.x.x`

### 7. Access Guacamole
Open browser: `http://unraid-ip:8080`  
Login: `admin` / `admin`

---

## For Docker Compose Users

### Quick Deploy (All-in-One)
```bash
# Create .env file with your credentials
cat > .env << EOF
VPN_USER=your_username
VPN_PASS=your_password
VPN_SERVER=vpn.illinois.edu
VPN_AUTHGROUP=OpenConnect1 (Split)
DUO_METHOD=push
DNS_SERVERS=130.126.2.131
EOF

# Deploy
docker-compose -f docker-compose-allin1.yml up -d

# Check status
docker-compose logs openconnect-vpn
```

### Multi-Container Deploy
```bash
docker-compose -f docker-compose.yml up -d
```

---

## Illinois VPN Specific

### Standard Setup
```
VPN_USER: Your NetID (e.g., bcmeyer)
VPN_PASS: Your password (with special chars if needed)
VPN_SERVER: vpn.illinois.edu
VPN_AUTHGROUP: OpenConnect1 (Split)
DUO_METHOD: push
DNS_SERVERS: 130.126.2.131
```

### Two-Factor Authentication
- **Duo Method Options:**
  - `push` - Push notification to Duo app (recommended)
  - `phone` - Phone call authentication
  - `sms` - SMS text message code

---

## Testing Your Connection

### 1. Verify VPN is Connected
```bash
docker exec openconnect-vpn ip addr show | grep tun
```
Should show: `tun0: <UP,LOWER_UP>`

### 2. Test DNS Resolution
```bash
docker exec openconnect-vpn nslookup fandsu025.ad.uillinois.edu
```
Should resolve to an IP (e.g., 130.126.10.130)

### 3. Access Internal Services via Guacamole
1. Login to Guacamole at `http://unraid-ip:8080`
2. Go to **Home** → **New Connection**
3. Add RDP/SSH connection:
   - **Protocol:** RDP (or SSH)
   - **Hostname:** Internal server IP/hostname
   - **Username/Password:** Your credentials
4. Click **Save** and connect through VPN tunnel

---

## Common Issues & Quick Fixes

| Problem | Solution |
|---------|----------|
| Container won't start | Check logs: `docker logs openconnect-vpn` \| Enable Privileged mode |
| VPN won't connect | Verify credentials \| Enable DEBUG=true |
| Can't access Guacamole | Check port 8080 free \| Verify port mapping |
| DNS not resolving | Test: `nslookup domain 130.126.2.131` \| Verify DNS_SERVERS set |
| VPN disconnects | Set restart policy to Always \| Check session limit |

---

## Accessing Different Services

### Guacamole Web UI (Port 8080)
- Remote desktop gateway for RDP/SSH/VNC
- Add your internal servers
- Connect through VPN tunnel

### openconnect-web UI (Port 9000)
- Monitor VPN connection status
- Control connection start/stop
- View detailed logs

### Command Line
```bash
# Check connection status
docker exec openconnect-vpn ip route

# View logs
docker logs openconnect-vpn | tail -30

# Test internal connectivity
docker exec openconnect-vpn ping 10.x.x.x
```

---

## Next Steps

1. ✅ Container is running
2. ✅ VPN is connected  
3. ✅ Guacamole is accessible
4. **Add RDP/SSH connection** to Guacamole
5. **Create additional users** in Guacamole (Settings → Users)
6. **Customize connections** with shared folders, printers, etc.

---

## For More Help

- **Full Docs:** See [README.md](README.md)
- **Unraid Setup:** See [UNRAID_SETUP.md](UNRAID_SETUP.md)
- **Troubleshooting:** See README Troubleshooting section
- **Issues:** Open GitHub issue

