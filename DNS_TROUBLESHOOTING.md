# DNS and Network Troubleshooting for VPN Container

## Quick Fix: Guacamole DNS Not Working

If Guacamole shows "connection timed out; no servers could be reached":

### Step 1: Stop Guacamole
```bash
docker stop ApacheGuacamole
docker rm ApacheGuacamole
```

### Step 2: Recreate with Explicit DNS

In Unraid Docker UI:
1. Create new container from Guacamole template
2. Set **Network Type** to: `Container: vpn-connect`
3. Go to **Extra Parameters** and add:
   ```
   --dns=8.8.8.8 --dns=8.8.4.4
   ```
4. Create and start the container

### Step 3: Test
```bash
docker exec ApacheGuacamole nslookup fandsu025.ad.uillinois.edu
```

**Important**: If the above doesn't work, you likely need the Illinois VPN's internal DNS servers. Contact your IT department for these addresses and replace `8.8.8.8` with them.

---

## Full Diagnosis Steps

### 1. Check if DNS is working in the VPN container

SSH into Unraid and run:

```bash
# Install dig/nslookup tools if not present
docker exec vpn-connect apt-get update && apt-get install -y dnsutils

# Test DNS resolution
docker exec vpn-connect nslookup fandsu025.ad.uillinois.edu

# Test ping (might be blocked but worth trying)
docker exec vpn-connect ping -c 1 fandsu025.ad.uillinois.edu

# Check DNS config in the container
docker exec vpn-connect cat /etc/resolv.conf

# Check routing
docker exec vpn-connect ip route

# Check if connected
docker exec vpn-connect ip addr show
```

### 2. Check Guacamole container's DNS

When you created the Guacamole container with `network_mode: container:vpn-connect`:

```bash
# Check if Guacamole can resolve DNS
docker exec guacamole-container nslookup fandsu025.ad.uillinois.edu

# If nslookup not available, try:
docker exec guacamole-container cat /etc/resolv.conf
```

### 3. Likely Issue: DNS not inherited through VPN

When using `--network container:vpn-connect`, the container shares the network namespace but may not have proper DNS. Check:

```bash
docker inspect vpn-connect | grep -A 5 '"Dns"'
```

---

## Solutions

### Solution 1: Add DNS to VPN Container (Recommended)

Update `vpn-connect.xml` to specify DNS servers:

In the `<Environment>` section, add:

```xml
<Variable>
  <Name>DNS_SERVERS</Name>
  <Value>8.8.8.8 8.8.4.4</Value>
  <Description>DNS servers to use (space-separated)</Description>
</Variable>
```

Then in `connect-vpn.sh`, add before running openconnect:

```bash
# Configure DNS if specified
if [ -n "$DNS_SERVERS" ]; then
  for dns in $DNS_SERVERS; do
    echo "nameserver $dns" >> /etc/resolv.conf
  done
fi
```

### Solution 2: Use Unraid's DNS

In the Unraid Docker UI for `vpn-connect`:
1. Under **Network**, set **Extra Parameters** to:
   ```
   --dns=unraid-ip
   ```
   (Or use 8.8.8.8 for Google DNS)

### Solution 3: Add DNS to Guacamole Container

When creating the Guacamole container in Unraid UI:
1. Set **Extra Parameters** to:
   ```
   --network container:vpn-connect --dns=unraid-ip
   ```

---

---

## What DNS to Use?

**Option A: Google Public DNS** (default, works for most external sites)
- `8.8.8.8` and `8.8.4.4`

**Option B: Illinois VPN Internal DNS** (required for `ad.uillinois.edu` domains)
- Contact Illinois IT department
- Typically looks like: `128.174.x.x` or `192.17.x.x`
- May be provided in VPN connection documentation

**Option C: Unraid's DNS**
- Use your Unraid server IP (e.g., `192.168.1.100`)

---

## Most Likely Issue

The domain `fandsu025.ad.uillinois.edu` is an **internal Active Directory domain** that:
- Only resolves through the VPN's internal DNS servers
- NOT available through public DNS (Google, Cloudflare, etc.)
- Requires specific DNS servers provided by Illinois IT

### Action Items:
1. Check your VPN connection documentation for DNS server addresses
2. Or ask Illinois IT for the internal DNS servers
3. Use those instead of `8.8.8.8` in the `--dns` parameters
