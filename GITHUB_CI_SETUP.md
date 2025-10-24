# GitHub Actions CI/CD Setup Guide

## Overview
The GitHub Actions workflow has been fixed to automatically build and push the Docker image to Docker Hub when you push to the `main` branch.

## Required GitHub Secrets

You need to configure these secrets in your GitHub repository settings:

1. **DOCKERHUB_USERNAME**
   - Your Docker Hub username
   - Go to: Repository Settings → Secrets and variables → Actions → New repository secret
   - Name: `DOCKERHUB_USERNAME`
   - Value: `bencmeyer` (your Docker Hub username)

2. **DOCKERHUB_TOKEN**
   - A Docker Hub Personal Access Token (NOT your password)
   - Create at: https://hub.docker.com/settings/security
   - Go to: Repository Settings → Secrets and variables → Actions → New repository secret
   - Name: `DOCKERHUB_TOKEN`
   - Value: `<your-personal-access-token>`

## How to Create Docker Hub Personal Access Token

1. Log in to Docker Hub (https://hub.docker.com)
2. Click your profile icon (top right) → Account Settings
3. Click "Security" in the left sidebar
4. Click "New Access Token"
5. Give it a name: `GitHub Actions` or similar
6. Select permission: "Read, Write, Delete"
7. Copy the token and save it as the `DOCKERHUB_TOKEN` secret in GitHub

## Workflow Behavior

### On Push to main:
- ✅ Builds the Docker image using `Dockerfile.allin1`
- ✅ Tags it with: `bencmeyer/ocvpn-duo-guac:latest` and `bencmeyer/ocvpn-duo-guac:<commit-sha>`
- ✅ Automatically pushes to Docker Hub

### On Pull Requests:
- ✅ Builds the Docker image (validates build works)
- ❌ Does NOT push to Docker Hub (security best practice)

## Testing the Workflow

1. Make a small commit to the `main` branch:
   ```bash
   git add .github/workflows/ci.yml
   git commit -m "Fix GitHub Actions CI/CD workflow"
   git push origin main
   ```

2. Go to GitHub → Actions tab
3. Watch the workflow execute
4. Check Docker Hub to verify the image was pushed

## Workflow File Location
`.github/workflows/ci.yml`

## Troubleshooting

If the workflow fails:
1. Check the "Actions" tab in your GitHub repository
2. Click the failed workflow run
3. View the logs for specific error messages
4. Common issues:
   - ❌ Secrets not configured
   - ❌ Docker Hub credentials invalid/expired
   - ❌ Build errors in Dockerfile

## Features of This Workflow

✅ Multi-platform builds (using buildx)  
✅ Automatic image tagging with git SHA  
✅ Only pushes on main branch (not on PRs)  
✅ Uses official docker/build-push-action (best practices)  
✅ Build date and VCS reference included in image metadata  

