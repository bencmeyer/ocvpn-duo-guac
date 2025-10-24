# Unraid Setup for Persistent VPN Connection

## On Unraid Server

SSH into your Unraid and run these commands:

```bash
# Load the updated Docker image
docker load -i /tmp/vpn-test.tar

# Copy the XML template to the correct location
cp /tmp/vpn-connect.xml /boot/config/plugins/dockerMan/templates-user/

# Verify image is loaded
docker images | grep vpn-test
```

## In Unraid Web UI

1. **Stop the old container** if it's still running:
   - Go to **Docker** tab
   - Find the vpn-connect container and click the **X** to remove it

2. **Create a new container from the updated template**:
   - Click **Add Container**
   - Select `vpn-connect` from the template dropdown
   - Enter your VPN credentials:
     - **VPN Username**: your-username
     - **VPN Password**: your-password
   - Click **Create**

3. **Start the container**:
   - It should start automatically or click the green play button
   - Check the logs to verify it connects

## What's Changed

✅ **Runs as root** - Required for TUN device access  
✅ **NET_ADMIN capability** - Allows network configuration  
✅ **Persistent connection** - Container stays running  
✅ **Uses `interact`** - Hands off to interactive mode after connection  
✅ **Host network mode** - VPN accessible to other containers

## Using with Other Containers

To route another container through this VPN, in your other container:

```bash
docker run --network container:vpn-connect <your-other-image>
```

Or in Unraid web UI:
- When creating a container, set **Network Type** to: `Container: vpn-connect`

This makes the other container use the VPN container's network stack, routing all traffic through the VPN.

## Verify VPN Connection

Once the container is running:

```bash
docker exec vpn-connect ip route
```

You should see VPN routes, indicating the connection is active.
