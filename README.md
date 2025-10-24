# OpenConnect VPN + Guacamole

Production-ready Docker container combining OpenConnect VPN with Guacamole remote desktop gateway for Unraid and Docker.

## Features

✅ OpenConnect VPN with Duo 2FA (push, phone, SMS)  
✅ Guacamole gateway for RDP/SSH/VNC through VPN  
✅ Special characters in passwords (!, @, #, $ supported)  
✅ Auto-reconnect with persistent VPN tunnel  
✅ Easy Unraid template deployment  
✅ Standalone and all-in-one Docker options  

## Quick Start

### Unraid (Recommended)

1. Add template:
```bash
wget https://raw.githubusercontent.com/bencmeyer/ocvpn-duo-guac/main/vpn-connect.xml
scp vpn-connect.xml root@UNRAID_IP:/boot/config/plugins/dockerMan/templates-user/
```

2. In Unraid UI: Docker → Add Container → Select "openconnect-vpn" → Fill credentials → Create

3. Access: http://UNRAID_IP:8080 (admin/admin)

### Docker Compose

```bash
docker-compose -f docker-compose-allin1.yml up -d
```

### Direct Docker

```bash
docker run -d --name=ocvpn-guac --privileged \
  -p 8080:8080 -p 9000:9000 \
  -e VPN_USER=your-netid \
  -e VPN_PASS=your-password \
  -e VPN_SERVER=vpn.illinois.edu \
  -e DUO_METHOD=push \
  bencmeyer/ocvpn-duo-guac:latest
```

## Configuration

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `VPN_USER` | VPN username | (required) | netid |
| `VPN_PASS` | VPN password | (required) | P@ssw0rd! |
| `VPN_SERVER` | VPN server | vpn.illinois.edu | vpn.company.com |
| `VPN_AUTHGROUP` | Auth group on VPN | OpenConnect1 (Split) | Corp |
| `DUO_METHOD` | 2FA method | push | phone, sms |
| `DNS_SERVERS` | DNS servers (space-separated) | 130.126.2.131 | 8.8.8.8 1.1.1.1 |
| `DEBUG` | Debug logging | false | true |

### DNS Options (Examples)

```
Illinois:      130.126.2.131
Google:        8.8.8.8 8.8.4.4
Cloudflare:    1.1.1.1 1.0.0.1
Quad9:         9.9.9.9 149.112.112.112
OpenDNS:       208.67.222.123
```

## Ports & Accessing Services

| Port | Service | URL |
|------|---------|-----|
| 8080 | Guacamole Web UI | http://localhost:8080 (admin/admin) |
| 9000 | OpenConnect Monitor | http://localhost:9000 |

## Troubleshooting

**VPN won't connect?**
- Check logs: `docker logs ocvpn-guac`
- Verify credentials and VPN_SERVER
- Ensure `--privileged` flag is set

**DNS not resolving?**
- Verify DNS_SERVERS matches your VPN's DNS
- Test: `docker exec ocvpn-guac nslookup yourdomain.com`

**Can't access Guacamole?**
- Check port 8080 isn't in use
- Verify container is running: `docker ps | grep ocvpn`

**Password with special characters not working?**
- Use single quotes: `VPN_PASS='P@ss!w0rd'`
- Avoid bash special chars without escaping

## Ports & Protocols

- **VPN**: 443/tcp (OpenConnect)
- **Guacamole**: 8080/tcp
- **Monitor**: 9000/tcp

## Requirements

- Docker with privileged mode support
- TUN device support (NET_ADMIN capability)
- VPN credentials with optional 2FA setup

## Images

| Image | Size | Use Case |
|-------|------|----------|
| `bencmeyer/ocvpn-duo-guac:latest` | 815 MB | All-in-one (recommended) |
| `bencmeyer/openconnect-vpn:latest` | 187 MB | VPN only |

## License & Attribution

- **OpenConnect**: https://www.infradead.org/openconnect/ (LGPL)
- **Guacamole**: https://guacamole.apache.org/ (Apache 2.0)
- **This project**: MIT License

## Support

- **GitHub**: https://github.com/bencmeyer/ocvpn-duo-guac
- **Issues**: https://github.com/bencmeyer/ocvpn-duo-guac/issues
- **Documentation**: See QUICKSTART.md for detailed setup

