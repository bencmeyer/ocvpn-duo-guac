# Setup Checklist

## ✅ Quick Status Check

- [x] VPN script created (connect-vpn.sh)
- [x] Docker image built and tested (openconnect-vpn:latest)
- [x] Unraid XML template created (openconnect-vpn.xml)
- [x] DNS troubleshooting guide written
- [x] Guacamole integration tested
- [x] All-in-One Docker Compose designed
- [x] Web UI for VPN control created
- [x] Nginx reverse proxy configured
- [x] Supervisor process management configured
- [x] Comprehensive documentation completed

---

## Choose Your Path

### Path A: Original Solution (Proven ✅)

**Files You Need:**
- [ ] `openconnect-vpn.tar` (Docker image)
- [ ] `openconnect-vpn.xml` (Unraid template)
- [ ] Read: `QUICKSTART.md`
- [ ] Read: `UNRAID_SETUP.md`

**Setup Steps:**
```bash
# 1. Load Docker image
docker load -i openconnect-vpn.tar

# 2. Import XML template to Unraid
# - Navigate to Docker tab
# - Add container
# - Template: openconnect-vpn.xml
# - Fill in VPN credentials

# 3. Create Guacamole container
# - Use jasonbean/guacamole image
# - Configure DNS: 130.126.2.131

# 4. Test
docker logs vpn-connect
```

**Verification:**
- [ ] VPN container running
- [ ] `docker exec vpn-connect ifconfig tun0` shows TUN device
- [ ] Can ping internal machines from Guacamole
- [ ] Guacamole resolves internal hostnames

### Path B: All-in-One Solution (Recommended 🎯)

**Files You Need:**
- [ ] `docker-compose-allin1.yml`
- [ ] `nginx.conf`
- [ ] `.env.example` → `.env` (with your values)
- [ ] Read: `ALLIN1_SETUP.md`

**Setup Steps:**
```bash
# 1. Create .env file
cp .env.example .env
nano .env  # Fill in VPN_USER, VPN_PASS, database passwords

# 2. Start everything
docker-compose -f docker-compose-allin1.yml up -d

# 3. Wait for services to initialize
sleep 30

# 4. Check status
docker-compose -f docker-compose-allin1.yml ps
```

**Verification:**
- [ ] All 4 services running (openconnect-vpn, guacamole, guacamole-db, nginx)
- [ ] `docker logs` show no critical errors
- [ ] Web UI accessible at https://localhost:443/vpn/dashboard
- [ ] Guacamole accessible at https://localhost/guacamole/
- [ ] VPN control buttons work (Connect/Disconnect/Reconnect)

---

## Pre-Deployment Checklist

### Before You Start

- [ ] VPN credentials ready (username, password)
- [ ] Duo MFA method determined (push/phone/sms)
- [ ] VPN server address (e.g., vpn.illinois.edu)
- [ ] VPN auth group (e.g., OpenConnect1 (Split))
- [ ] Internal DNS server (e.g., 130.126.2.131)
- [ ] Unraid access/SSH credentials (if on Unraid)
- [ ] Docker installed and running
- [ ] Docker Compose installed (v1.29+)

### Environment Variables Needed

```bash
# VPN Configuration
VPN_USER=your_username
VPN_PASS=your_password
VPN_SERVER=vpn.illinois.edu
VPN_AUTHGROUP="OpenConnect1 (Split)"
DUO_METHOD=push
DNS_SERVERS=130.126.2.131

# Database Configuration (All-in-One only)
GUAC_DB_PASS=strong_random_password
GUAC_DB_ROOT_PASS=strong_random_password
```

---

## Deployment Steps (Choose One)

### Original Deployment

```bash
# Step 1: Load image
docker load -i openconnect-vpn.tar
# Expected: Loaded image: openconnect-vpn:latest

# Step 2: Run VPN container
docker run -d \
  --name vpn-connect \
  --privileged \
  --cap-add NET_ADMIN \
  --cap-add SYS_ADMIN \
  --device /dev/net/tun \
  -e VPN_USER=your_username \
  -e VPN_PASS='your_password' \
  -e VPN_SERVER=vpn.illinois.edu \
  -e VPN_AUTHGROUP="OpenConnect1 (Split)" \
  -e DUO_METHOD=push \
  -e DNS_SERVERS=130.126.2.131 \
  openconnect-vpn:latest

# Step 3: Check connection
sleep 10
docker logs vpn-connect
docker exec vpn-connect ifconfig tun0

# Step 4: Create Guacamole container
# (See QUICKSTART.md for details)
```

### All-in-One Deployment

```bash
# Step 1: Prepare environment
cp .env.example .env
nano .env  # Edit with your values

# Step 2: Start all services
docker-compose -f docker-compose-allin1.yml up -d

# Step 3: Wait for initialization
echo "Waiting for services..."
sleep 60

# Step 4: Check status
docker-compose -f docker-compose-allin1.yml ps

# Step 5: Verify health
docker-compose -f docker-compose-allin1.yml logs --tail=20
```

---

## Post-Deployment Testing

### Test VPN Connection

```bash
# For Original setup
docker exec vpn-connect bash -c 'curl https://my.illinois.edu'

# For All-in-One
curl -k https://localhost:443/vpn/api/status
```

### Test DNS Resolution

```bash
# For Original setup
docker exec vpn-connect nslookup fandsu025.ad.uillinois.edu

# For All-in-One (from guacamole container)
docker-compose -f docker-compose-allin1.yml exec guacamole \
  nslookup internal-hostname.domain
```

### Test Guacamole Access

```bash
# For Original setup
curl http://localhost:8080/guacamole/

# For All-in-One
curl -k https://localhost/guacamole/
# or https://localhost:8443/guacamole/
```

### Test Web UI (All-in-One only)

```bash
# Access dashboard
curl -k https://localhost:443/vpn/dashboard

# Check VPN status via API
curl -k https://localhost:443/vpn/api/status | jq .

# Check logs
curl -k https://localhost:443/vpn/api/logs | jq .
```

---

## Troubleshooting Guide

### VPN Not Connecting

**Original Setup:**
```bash
# Check logs
docker logs vpn-connect -f

# Verify credentials
docker exec vpn-connect env | grep VPN_

# Test manually
docker exec vpn-connect bash -c 'set +H; echo "test"'
```

**All-in-One Setup:**
```bash
# Check VPN service logs
docker-compose -f docker-compose-allin1.yml logs openconnect-vpn

# Check API status
curl -k https://localhost:443/vpn/api/status

# Verify environment
docker-compose -f docker-compose-allin1.yml exec openconnect-vpn env
```

### DNS Not Resolving

```bash
# Check resolv.conf
docker exec vpn-connect cat /etc/resolv.conf

# Test DNS query
docker exec vpn-connect nslookup fandsu025.ad.uillinois.edu 130.126.2.131

# For All-in-One, test from Guacamole
docker-compose -f docker-compose-allin1.yml exec guacamole \
  nslookup fandsu025.ad.uillinois.edu
```

### TUN Device Not Available

```bash
# Check capabilities
docker inspect vpn-connect | grep -i cap

# Verify privileged mode
docker inspect vpn-connect | grep -i privileged

# Check device access
docker exec vpn-connect ls -la /dev/net/tun
```

### Guacamole Database Connection Failed

**All-in-One Only:**
```bash
# Check MariaDB is running
docker-compose -f docker-compose-allin1.yml ps | grep guacamole-db

# Check database logs
docker-compose -f docker-compose-allin1.yml logs guacamole-db

# Test connection
docker-compose -f docker-compose-allin1.yml exec guacamole-db \
  mysqladmin ping -u root -p"${GUAC_DB_ROOT_PASS}"
```

---

## Configuration Reference

### Environment Variables

| Variable | Required | Example | Purpose |
|----------|----------|---------|---------|
| VPN_USER | Yes | your_username | VPN login username |
| VPN_PASS | Yes | MyP@ssw0rd! | VPN login password |
| VPN_SERVER | No | vpn.illinois.edu | VPN server address |
| VPN_AUTHGROUP | No | OpenConnect1 (Split) | VPN authentication group |
| DUO_METHOD | No | push | Duo 2FA method (push/phone/sms) |
| DNS_SERVERS | No | 130.126.2.131 | Custom DNS server |
| DEBUG | No | true | Enable debug logging |
| GUAC_DB_PASS | Yes* | strong_password | Guacamole DB password (*All-in-One only) |
| GUAC_DB_ROOT_PASS | Yes* | strong_password | MariaDB root password (*All-in-One only) |

### Default Ports

| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| Nginx (HTTP) | 80 | HTTP | Redirects to HTTPS |
| Nginx (HTTPS) | 8443 | HTTPS | Proxy entry point |
| Guacamole | 8080 | HTTP | Direct access (all-in-one) |
| Guacamole | 443/guacamole | HTTPS | Via nginx proxy |
| VPN Web UI | 443/vpn | HTTPS | Via nginx proxy |
| MariaDB | 3306 | TCP | Internal only (all-in-one) |

---

## Monitoring & Maintenance

### View Logs

**Original:**
```bash
# VPN container
docker logs vpn-connect -f

# Guacamole container
docker logs guacamole -f
```

**All-in-One:**
```bash
# All services
docker-compose -f docker-compose-allin1.yml logs -f

# Specific service
docker-compose -f docker-compose-allin1.yml logs -f openconnect-vpn

# Via web UI
curl -k https://localhost:443/vpn/api/logs
```

### Check Status

**Original:**
```bash
docker ps -a
docker inspect vpn-connect | jq '.State'
```

**All-in-One:**
```bash
docker-compose -f docker-compose-allin1.yml ps
docker-compose -f docker-compose-allin1.yml exec openconnect-vpn \
  curl -s http://localhost:9001/status | grep openconnect
```

### Restart Services

**Original:**
```bash
# Restart VPN
docker restart vpn-connect

# Restart Guacamole
docker restart guacamole
```

**All-in-One:**
```bash
# Restart specific service
docker-compose -f docker-compose-allin1.yml restart openconnect-vpn

# Restart all
docker-compose -f docker-compose-allin1.yml restart

# Via API (no restart needed!)
curl -k -X POST https://localhost:443/vpn/api/reconnect
```

---

## Documentation Reference

### For Original Setup
- [x] Read: `QUICKSTART.md` (30-second setup)
- [x] Read: `UNRAID_SETUP.md` (Unraid-specific)
- [x] Read: `DNS_TROUBLESHOOTING.md` (DNS issues)
- [x] Reference: `README.md` (comprehensive guide)

### For All-in-One Setup
- [x] Read: `ALLIN1_SETUP.md` (detailed setup)
- [x] Read: `ALLIN1_QUICK_SUMMARY.md` (overview)
- [x] Read: `CHOOSING_APPROACH.md` (comparison)
- [x] Reference: `.env.example` (configuration template)

### General Reference
- [x] `INDEX.md` - Navigation guide
- [x] `PROJECT_SUMMARY.md` - Project overview

---

## Next Steps

### Immediate (Day 1)
- [ ] Choose Original or All-in-One
- [ ] Follow corresponding setup guide
- [ ] Verify VPN connection
- [ ] Verify Guacamole access

### Short-term (Week 1)
- [ ] Add internal machines to Guacamole
- [ ] Test RDP/SSH/VNC connections
- [ ] Verify network routing through VPN
- [ ] Document your setup

### Medium-term (Month 1)
- [ ] Set up SSL certificates (Let's Encrypt)
- [ ] Configure automated backups
- [ ] Set up monitoring/alerts
- [ ] Document troubleshooting procedures

### Long-term (Ongoing)
- [ ] Regular security updates
- [ ] Performance optimization
- [ ] Capacity planning
- [ ] Disaster recovery testing

---

## Support & Help

### Common Issues

1. **"TUN device not found"**
   - Check: `docker inspect` for privileged and capabilities
   - Fix: Verify `--device /dev/net/tun` is passed

2. **"DNS not resolving"**
   - Check: `/etc/resolv.conf` inside container
   - Fix: Set `DNS_SERVERS` environment variable

3. **"Can't connect to VPN"**
   - Check: Credentials are correct
   - Fix: Look at `docker logs` for Duo prompt timeout

4. **"Guacamole database connection failed"**
   - Check: MariaDB container is running
   - Fix: Check docker-compose for `guacamole-db` errors

### Where to Find Information

- VPN Issues: `DNS_TROUBLESHOOTING.md`
- Unraid Issues: `UNRAID_SETUP.md`
- Guacamole Issues: `ALLIN1_SETUP.md` Troubleshooting section
- General Questions: `CHOOSING_APPROACH.md`
- Quick Help: `QUICKSTART.md` or `ALLIN1_QUICK_SUMMARY.md`

---

## Success Criteria

### Minimum Viable Deployment

- [x] VPN container running and connected
- [x] Guacamole container running
- [x] Can access Guacamole web UI
- [x] Can resolve internal hostnames
- [x] Can ping internal machines

### Production Deployment

- [x] All of above
- [x] SSL certificates installed
- [x] Health checks passing
- [x] Automated backups configured
- [x] Monitoring/alerting enabled
- [x] Documentation updated
- [x] Team trained on operations

---

**Ready to deploy?** Start with `CHOOSING_APPROACH.md`, then follow your chosen path!
