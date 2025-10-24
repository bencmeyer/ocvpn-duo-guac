# Transfer VPN Container to Unraid

## File Ready
✅ **vpn-test.tar** (180MB) - Ready to transfer

## Step 1: Transfer to Unraid

Choose one method:

### Option A: Via Network (SMB/NFS Share)
```bash
# From your current machine, copy to Unraid share
cp vpn-test.tar /path/to/unraid/share/
```

### Option B: Via SCP (if SSH is enabled on Unraid)
```bash
scp vpn-test.tar root@unraid-ip:/tmp/
```

### Option C: Via USB Drive
1. Mount a USB drive
2. Copy `vpn-test.tar` to it
3. Insert into Unraid and copy to a persistent location

---

## Step 2: Load Image into Docker on Unraid

SSH into Unraid:
```bash
ssh root@unraid-ip
```

Then load the image:
```bash
docker load -i /tmp/vpn-test.tar
```

Verify it loaded:
```bash
docker images | grep vpn-test
```

You should see: `vpn-test    latest    <image-id>    <date>    180MB`

---

## Step 3A: Install App Template (Easiest Method)

1. **Copy the app template to Unraid**:
   ```bash
   scp vpn-connect.xml root@unraid-ip:/boot/config/plugins/dockerMan/templates-user/
   ```

2. Go to **Docker** tab in Unraid web interface
3. Click **Add Container**
4. In the **Template** dropdown, look for `vpn-connect`
5. Fill in your credentials:
   - **VPN Username**: your-username
   - **VPN Password**: your-password-with-special-chars
6. Click **Create**

---

## Step 3B: Manual Container Creation

If you don't want to use the template:

1. Go to **Docker** tab in Unraid web interface
2. Click **Add Container**
3. Fill in settings:
   - **Name**: `vpn-connect` (or your preference)
   - **Repository**: `vpn-test:latest`
   - **Console**: `Shell` or `Unspecified`

4. **Add Environment Variables** (click "Add another Path/Variable"):
   - **Name**: `VPN_USER` | **Value**: `your-username`
   - **Name**: `VPN_PASS` | **Value**: `your-password-with-special-chars`

5. Click **Create**

---

## Step 4: Run the Container

### Option A: From Web UI
- Click the container, then click **Start**
- View logs to see connection status

### Option B: From Command Line
```bash
docker run --rm -e VPN_USER='your-username' -e VPN_PASS='your-password' vpn-test:latest
```

---

## Troubleshooting

### Container starts but exits immediately
Check logs:
```bash
docker logs container-name
```

Common issues:
- Missing `VPN_USER` or `VPN_PASS` environment variables
- Special characters in password need single quotes: `'P@ss!word'`

### Connection test
Once running, you can check if VPN is active:
```bash
ip route  # Should show VPN routes
```

---

## Notes

- The container runs the connection script and exits (it doesn't stay running as a service)
- For persistent VPN, you'd need a wrapper script with auto-reconnect logic
- All output is logged in Unraid's Docker logs for debugging
- The `--dump-http-traffic` flag provides debug output
