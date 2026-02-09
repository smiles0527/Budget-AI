# ⚠️ CRITICAL: CodeQL Setup Instructions

## 🚨 ACTION REQUIRED - Repository Owner Must Complete This Step

**The CodeQL workflow CANNOT run until you disable the default CodeQL setup.**

### Current Error

```
Code Scanning could not process the submitted SARIF file:
CodeQL analyses from advanced configurations cannot be processed 
when the default setup is enabled
```

### What This Means

Your repository has GitHub's **default CodeQL setup** enabled. This setting **completely blocks** any custom CodeQL workflows from working. The workflow configuration is correct, but GitHub will not process the results until you change this setting.

---

## 🔧 How to Fix (5 Minutes)

### Step 1: Navigate to Code Scanning Settings

1. Go to your repository on GitHub.com
2. Click the **Settings** tab (top right)
3. In the left sidebar, scroll down to **Security**
4. Click **Code security and analysis**
5. Scroll to the **Code scanning** section

### Step 2: Disable Default Setup

You'll see "CodeQL analysis" with a **"Default"** badge or label:

1. Click the **"..."** menu (three dots) next to "CodeQL analysis"
2. You'll see options:
   - **"Switch to advanced"** (recommended) - Use this if you want to keep using CodeQL
   - **"Disable CodeQL"** - Use this if you want to completely disable it

3. Click **"Switch to advanced"**
4. Confirm the action

### Step 3: Verify It Works

After switching to advanced:
- The PR checks will automatically re-run
- Or you can manually trigger them from the Actions tab
- All three language analyses (Python, Swift, JavaScript/TypeScript) should complete successfully

---

## ✅ What Happens After You Fix This

Once you complete the steps above:

✅ **Python analysis** will scan your backend (`backend/`) and worker (`worker/`)  
✅ **Swift analysis** will scan your iOS app and tests  
✅ **JavaScript/TypeScript analysis** will scan your web frontend (`web/`)  
✅ **Automated security scans** will run on every push and PR  
✅ **Weekly security audits** will run automatically  

---

## 🤔 Why Can't Both Run?

GitHub doesn't allow default and advanced (custom) CodeQL setups to run simultaneously because:
- It would create duplicate analyses
- Results would conflict
- It would waste CI minutes

You must choose one or the other.

---

## 📊 What You Get with This Custom Workflow

The custom workflow (already configured) provides:

### Advanced Query Suites
- `security-extended` - Extended security vulnerability detection
- `security-and-quality` - Code quality + security analysis

### Multi-Language Coverage
- **Python**: Backend API + background worker
- **Swift**: iOS app + all test suites  
- **JavaScript/TypeScript**: Next.js web frontend

### Automated Triggers
- Every push to `main` or `develop` branches
- Every pull request
- Weekly scheduled scans (Sunday midnight UTC)

### Custom Build Configuration
- Optimized Swift builds for CI
- Generic simulator destination for compatibility
- 360-minute timeout for complex builds

---

## ❓ Frequently Asked Questions

### Q: Will this affect my repository's security?
**A**: No! After switching, you'll have the same (or better) security coverage with the custom workflow.

### Q: Can I switch back to default setup later?
**A**: Yes, but you'll need to delete the custom workflow file first.

### Q: What if I want to use the default setup instead?
**A**: Delete the `.github/workflows/codeql.yml` file and keep the default setup enabled.

### Q: How do I know if I've done it correctly?
**A**: After switching to advanced, go to the Actions tab and look for the "CodeQL Analysis" workflow running. It should complete without the configuration error.

### Q: Who can make this change?
**A**: Only repository owners or administrators with "Write" or "Admin" permissions can change code scanning settings.

---

## 🆘 Still Having Issues?

If you've completed the steps above and still see errors:

1. **Check the Actions tab** for detailed error logs
2. **Review** `.github/workflows/README.md` for troubleshooting
3. **Verify** you have the correct permissions (Settings tab should be visible)
4. **Wait** a few minutes after changing settings for GitHub to sync

---

## 📚 Additional Resources

- [GitHub Code Scanning Documentation](https://docs.github.com/en/code-security/code-scanning)
- [Switching to Advanced Setup](https://docs.github.com/en/code-security/code-scanning/automatically-scanning-your-code-for-vulnerabilities-and-errors/configuring-code-scanning-for-a-repository)
- [CodeQL Action Documentation](https://github.com/github/codeql-action)
