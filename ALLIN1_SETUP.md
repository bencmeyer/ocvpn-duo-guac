# All-in-One OpenConnect VPN + Guacamole Setup

## Overview

This is an integrated solution that combines:
- **OpenConnect Web UI** (Port 443) - Control VPN connections with a web interface
- **Guacamole** (Port 8080) - Remote desktop gateway (RDP, SSH, VNC)
- **Nginx Reverse Proxy** (Port 80/443) - Single entry point with SSL
- **MariaDB** - Database for Guacamole

Everything runs in Docker containers that communicate on internal networks.

---

## Architecture

```
┌──────────────────────────────────────┐
│         Your Browser                 │
├──────────────────────────────────────┤
            ↓
┌──────────────────────────────────────┐
│    Nginx Reverse Proxy (443)         │
│  - SSL/TLS termination               │
│  - Route to services                 │
├──────────────────────────────────────┤
      ↙                         ↘
   /guacamole/               /vpn/
      ↓                         ↓
┌────────────────────┐  ┌────────────────────┐
│   Guacamole        │  │ OpenConnect Web    │
│   :8080            │  │ :443               │
├────────────────────┤  ├────────────────────┤
│ - RDP/SSH/VNC      │  │ - Connect/Disconnect
│ - via VPN tunnel   │  │ - View status
├────────────────────┤  │ - View logs
│   MariaDB :3306   │  │ - Reconnect
└────────────────────┘  └────────────────────┘
                            ↓
                      ┌────────────────────┐
                      │ OpenConnect VPN    │
                      │ (VPN Tunnel)       │
                      │ Connected to:      │
                      │ vpn.illinois.edu   │
                      └────────────────────┘
```

---

## Prerequisites

- Docker & Docker Compose installed
- 4GB+ RAM available
- Port 80/443 available (or modify docker-compose)
- Internet access for VPN server

---

## Quick Start

### 1. Create `.env` file

```bash
cat > .env << 'EOF'
# VPN Configuration
VPN_USER=your-username
VPN_PASS=your-password
VPN_SERVER=vpn.illinois.edu
VPN_AUTHGROUP=OpenConnect1 (Split)
DNS_SERVERS=130.126.2.131

# Guacamole Database
GUAC_DB_PASS=secure-database-password
GUAC_DB_ROOT_PASS=secure-root-password
EOF
```

### 2. Start all services

```bash
docker-compose -f docker-compose-allin1.yml up -d
```

### 3. Access services

- **Guacamole**: https://localhost:8080/guacamole/
- **VPN Control**: https://localhost:443/vpn/dashboard
- **Nginx Dashboard**: https://localhost:8443/

---

## Configuration Options

### Environment Variables

Create `.env` file with:

```bash
# Required - VPN Credentials
VPN_USER=your-username
VPN_PASS=your-password

# Optional - VPN Server (defaults provided)
VPN_SERVER=vpn.illinois.edu
VPN_AUTHGROUP=OpenConnect1 (Split)
DNS_SERVERS=130.126.2.131 8.8.8.8

# Required - Guacamole Database
GUAC_DB_PASS=your-secure-password
GUAC_DB_ROOT_PASS=your-root-password
```

### Ports

Edit `docker-compose-allin1.yml` to change ports:

```yaml
ports:
  - "443:443"      # OpenConnect Web UI
  - "8080:8080"    # Guacamole
  - "8443:8443"    # Nginx (reverse proxy)
```

---

## Usage

### Access Guacamole

1. Navigate to: https://localhost:8080/guacamole/
2. Login with default credentials (check jasonbean/guacamole docs)
3. Add connections to internal machines
4. Connect via the VPN tunnel

### Control VPN

1. Navigate to: https://localhost:443/vpn/dashboard
2. View current connection status
3. Click **Connect** to establish VPN
4. Click **Disconnect** to stop VPN
5. Click **Reconnect** to reset connection
6. View logs for troubleshooting

### Monitor Services

```bash
# View running containers
docker ps

# View logs
docker-compose -f docker-compose-allin1.yml logs -f

# View specific service logs
docker-compose -f docker-compose-allin1.yml logs openconnect-vpn
docker-compose -f docker-compose-allin1.yml logs guacamole

# Check service health
docker-compose -f docker-compose-allin1.yml ps
```

---

## Troubleshooting

### VPN Won't Connect

```bash
# Check OpenConnect logs
docker-compose -f docker-compose-allin1.yml logs openconnect-vpn

# Verify DNS
docker exec openconnect-vpn cat /etc/resolv.conf

# Test DNS
docker exec openconnect-vpn nslookup example.com 130.126.2.131
```

### Guacamole Can't Connect

```bash
# Check Guacamole logs
docker-compose -f docker-compose-allin1.yml logs guacamole

# Check database
docker-compose -f docker-compose-allin1.yml logs guacamole-db

# Verify DNS in Guacamole
docker exec guacamole nslookup internal-machine.ad.uillinois.edu
```

### Nginx Not Proxying

```bash
# Check Nginx logs
docker-compose -f docker-compose-allin1.yml logs nginx

# Verify configuration
docker exec nginx-proxy nginx -t

# Reload configuration
docker exec nginx-proxy nginx -s reload
```

---

## Port Mapping Reference

| Service | Container Port | Host Port | Purpose |
|---------|----------------|-----------|---------|
| OpenConnect Web | 443 | 443 | VPN control UI |
| Guacamole | 8080 | 8080 | Remote desktop |
| Nginx HTTPS | 8443 | 8443 | Reverse proxy |
| MariaDB | 3306 | (internal) | Database |

---

## Security Considerations

### SSL/TLS

Default setup uses self-signed certificate. For production:

```bash
# Generate self-signed cert for 365 days
mkdir -p nginx/ssl
openssl req -x509 -newkey rsa:4096 -keyout nginx/ssl/self-signed.key \
    -out nginx/ssl/self-signed.crt -days 365 -nodes
```

Or use Let's Encrypt (uncomment in nginx.conf):

```bash
# Install Certbot
sudo apt-get install certbot python3-certbot-nginx

# Get certificate
sudo certbot certonly --standalone -d your-domain.com
```

### Credentials

✅ Store passwords in `.env` file (add to `.gitignore`)  
✅ Never commit `.env` to version control  
✅ Use strong passwords for database  
✅ Rotate credentials regularly  

---

## Advanced Usage

### Connect Multiple VPNs

Create separate services in docker-compose for each VPN:

```yaml
openconnect-vpn-1:
  image: weikinhuang/openconnect-web:latest
  environment:
    VPN_USER: user1
    VPN_PASS: pass1
    VPN_SERVER: vpn1.company.com

openconnect-vpn-2:
  image: weikinhuang/openconnect-web:latest
  environment:
    VPN_USER: user2
    VPN_PASS: pass2
    VPN_SERVER: vpn2.company.com
```

### Persistent Volumes

Add volume mounts to preserve data:

```yaml
volumes:
  - ./guacamole_config:/config
  - ./mysql_data:/var/lib/mysql
```

### Custom Guacamole Configuration

Mount custom config:

```yaml
volumes:
  - ./guacamole.properties:/config/guacamole.properties:ro
```

---

## Maintenance

### Backup

```bash
# Backup Guacamole database
docker exec guacamole-db mysqldump -u guacamole -p guacamole_db > backup.sql

# Backup configuration
cp -r guacamole_config backup_config
```

### Update Services

```bash
# Pull latest images
docker-compose -f docker-compose-allin1.yml pull

# Restart with new images
docker-compose -f docker-compose-allin1.yml up -d
```

### Clean Up

```bash
# Stop all services
docker-compose -f docker-compose-allin1.yml down

# Remove volumes (careful - deletes data)
docker-compose -f docker-compose-allin1.yml down -v
```

---

## FAQ

**Q: Can I access VPN without going through Nginx?**  
A: Yes, connect directly to OpenConnect Web UI on port 443 or Guacamole on 8080

**Q: Does the VPN stay connected if I'm not using Guacamole?**  
A: Yes, the VPN runs independently. Use the web UI to manage it.

**Q: Can I add more internal machines to Guacamole?**  
A: Yes, use the Guacamole admin panel to add RDP/SSH/VNC connections

**Q: What if the VPN times out?**  
A: Use the web UI to disconnect and reconnect manually

**Q: Can I use this on Unraid?**  
A: Yes! Just copy docker-compose-allin1.yml and .env to Unraid, then run docker-compose

---

## Next Steps

1. ✅ Configure `.env` with your credentials
2. ✅ Run `docker-compose up -d`
3. ✅ Access Guacamole and configure connections
4. ✅ Use VPN control panel to manage connection
5. ✅ Connect to internal machines via Guacamole

---

## Support

For issues:
- Check logs: `docker-compose logs [service]`
- Verify DNS: `docker exec [container] nslookup [domain]`
- Test connectivity: `docker exec [container] ping [host]`

See troubleshooting section above for common issues.
