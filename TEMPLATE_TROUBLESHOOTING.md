# Template Troubleshooting Guide

## Problem: Template Didn't Show After Adding

### Root Cause
The XML file was **malformed** - it had duplicate sections and a misplaced closing tag that broke the XML parsing.

### ✅ Solution Applied
I've **fixed the vpn-connect.xml** file. The corrected file is now:
- ✅ Valid XML (tested with Python XML parser)
- ✅ No duplicate sections
- ✅ Proper opening and closing tags
- ✅ 175 lines of clean configuration

### How to Verify the Fix

**Option 1: Check file on Unraid (if already copied)**
```bash
# SSH into Unraid
ssh root@unraid-ip

# Verify XML is valid
python3 << 'EOF'
import xml.etree.ElementTree as ET
try:
    tree = ET.parse('/boot/config/plugins/dockerMan/templates-user/vpn-connect.xml')
    print("✅ XML is valid!")
except ET.ParseError as e:
    print(f"❌ XML error: {e}")
