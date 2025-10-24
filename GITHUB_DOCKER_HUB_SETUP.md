# GitHub & Docker Hub Setup Guide

## Current Status

✅ **Local Repository Initialized**
- Git repository created and committed
- 37 files staged (Dockerfiles, docs, scripts, configs)
- Ready to push to GitHub

🔧 **Next: Connect to GitHub and Docker Hub**

---

## Step 1: Create GitHub Repository

### 1A. On GitHub.com

1. Go to https://github.com/new
2. Fill in:
   - **Repository name:** `openconnect-vpn` (or your preferred name)
   - **Description:** OpenConnect VPN + Guacamole all-in-one container for Unraid
   - **Visibility:** Public (so anyone can see it)
   - **Initialize:** DO NOT check "Add a README" (we already have one)
3. Click **Create repository**
4. Copy the repository URL (should look like: `https://github.com/YOUR_USERNAME/openconnect-vpn.git`)

### 1B. On Your Build Machine

```bash
cd /tmp/vpn-test-environment

# Set the remote repository (replace with your URL)
git remote add origin https://github.com/YOUR_USERNAME/openconnect-vpn.git

# Rename branch to main (GitHub default)
git branch -M main

# Push to GitHub
git push -u origin main
```

**Note:** You'll be prompted for GitHub credentials. Use:
- Username: Your GitHub username
- Password: Personal Access Token (generate at https://github.com/settings/tokens)

---

## Step 2: Create Docker Hub Repository

### 2A. On Docker Hub (https://hub.docker.com)

1. Click **Create Repository**
2. Fill in:
   - **Name:** `openconnect-vpn-all`
   - **Description:** All-in-one OpenConnect VPN + Guacamole gateway for Unraid
   - **Visibility:** Public
3. Click **Create**

### 2B. On Your Build Machine

```bash
# Login to Docker Hub
docker login

# When prompted, enter:
# - Docker ID (username)
# - Password (not access token for login)

# Tag your image for Docker Hub
docker tag openconnect-vpn-all:latest YOUR_DOCKER_HUB_USERNAME/openconnect-vpn-all:latest

# Push to Docker Hub
docker push YOUR_DOCKER_HUB_USERNAME/openconnect-vpn-all:latest

# Verify it's online
docker pull YOUR_DOCKER_HUB_USERNAME/openconnect-vpn-all:latest
```

**Time to push:** ~5-10 minutes (depending on your internet)

---

## Step 3: Update XML Template

Now that the image is on Docker Hub, update the XML template to point there:

```bash
cd /tmp/vpn-test-environment

# Edit vpn-connect.xml
# Change this line:
# <Registry>library</Registry>
# 
# To this:
# <Registry>YOUR_DOCKER_HUB_USERNAME</Registry>

# Or change the Repository line from:
# <Repository>openconnect-vpn-all:latest</Repository>
#
# To:
# <Repository>YOUR_DOCKER_HUB_USERNAME/openconnect-vpn-all:latest</Repository>
# And set <Registry>library</Registry>
```

**Example:**
- If your Docker Hub username is `john-doe`
- Repository: `john-doe/openconnect-vpn-all:latest`
- Registry: `library` (will prepend Docker Hub automatically)

---

## Step 4: Test with Unraid

Once Docker Hub image is live:

### On Unraid:

1. Copy the XML template to Unraid:
   ```bash
   scp vpn-connect.xml root@unraid-ip:/boot/config/plugins/dockerMan/templates-user/
   ```

2. Refresh Unraid UI (F5)

3. Go to **Docker → Add Container**

4. Select **openconnect-vpn** template

5. Fill in VPN credentials

6. Click **Create**

Unraid will automatically pull `your-username/openconnect-vpn-all:latest` from Docker Hub! 🎉

---

## Step 5: Set Up Automated Builds (Optional)

### GitHub Actions to Auto-Push to Docker Hub

Already included! Check `.github/workflows/ci.yml`

This workflow:
- ✅ Builds image on every push to `main`
- ✅ Tags it with git commit SHA
- ✅ Pushes to Docker Hub automatically
- ✅ Tags as `latest` on release

**To enable:**

1. Go to your GitHub repo
2. Settings → Secrets and variables → Actions
3. Create new secret: `DOCKER_HUB_USERNAME`
4. Create new secret: `DOCKER_HUB_TOKEN`
   - Get token at: https://hub.docker.com/settings/security

Then every commit will auto-build and push! 🚀

---

## Complete Command Reference

### Quick Setup Commands

```bash
# 1. Initialize git (already done)
cd /tmp/vpn-test-environment
git init

# 2. Add GitHub remote
git remote add origin https://github.com/YOUR_USERNAME/openconnect-vpn.git
git branch -M main

# 3. Push to GitHub
git push -u origin main

# 4. Login to Docker Hub and push image
docker login
docker tag openconnect-vpn-all:latest YOUR_DOCKER_HUB_USERNAME/openconnect-vpn-all:latest
docker push YOUR_DOCKER_HUB_USERNAME/openconnect-vpn-all:latest

# 5. Verify the image is online
docker pull YOUR_DOCKER_HUB_USERNAME/openconnect-vpn-all:latest

# 6. Update XML template
# (Edit vpn-connect.xml, change Registry/Repository to point to Docker Hub)

# 7. Copy template to Unraid
scp vpn-connect.xml root@unraid-ip:/boot/config/plugins/dockerMan/templates-user/
```

---

## Verification Checklist

- [ ] GitHub repository created
- [ ] Code pushed to GitHub (`git push -u origin main`)
- [ ] Docker Hub repository created
- [ ] Image pushed to Docker Hub (`docker push username/openconnect-vpn-all:latest`)
- [ ] XML template updated with Docker Hub username
- [ ] XML template copied to Unraid
- [ ] Unraid UI shows "openconnect-vpn" template
- [ ] Template deployment succeeds

---

## Sharing Your Project

### README for GitHub

Your README.md is complete! It includes:
- ✅ Features overview
- ✅ Quick start guide
- ✅ Deployment options (Docker Compose, Unraid template, manual)
- ✅ Configuration reference
- ✅ Troubleshooting
- ✅ License

### Share Link

Once live, share this link:
```
https://github.com/YOUR_USERNAME/openconnect-vpn
```

Users can:
1. Fork your repository
2. Use your Unraid template
3. Pull your Docker Hub image
4. Contribute improvements

---

## After Publishing

### Monitor & Support

- Watch for GitHub issues and pull requests
- Update Docker image tags as needed
- Keep documentation current

### Next Steps

1. **Announce** on:
   - Reddit: r/unraid, r/OpenConnect, r/Docker
   - Unraid Forums
   - Your blog/social media

2. **Community** contributions:
   - Accept pull requests for improvements
   - Add Duo 2FA enhancements
   - Support additional VPN providers

3. **Future features** to consider:
   - Multi-VPN failover
   - Web UI for configuration
   - Prometheus metrics export
   - Kubernetes support

---

## Useful Links

| Resource | Link |
|----------|------|
| GitHub Docs | https://docs.github.com |
| Docker Hub | https://hub.docker.com |
| Unraid Templates | https://github.com/selfhosted/unraid-templates |
| OpenConnect | https://www.infradead.org/openconnect/ |
| Guacamole | https://guacamole.apache.org/ |

---

## Support

**Having issues?**

1. Check `.github/workflows/ci.yml` - verify build workflow is correct
2. Verify Docker Hub credentials are correct
3. Check XML template syntax (must be valid XML)
4. Test locally first: `docker run -d --privileged YOUR_USERNAME/openconnect-vpn-all:latest`

**Success! 🎉**

Your project is now:
- ✅ On GitHub (discoverable, version controlled)
- ✅ On Docker Hub (publicly available)
- ✅ Ready for Unraid deployment
- ✅ Set up for automated builds
