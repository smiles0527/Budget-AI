# CodeQL Setup Instructions

## ⚠️ IMPORTANT: Action Required by Repository Owner

The CodeQL workflow has been successfully configured, but **it cannot run until the repository's default CodeQL setup is disabled**. This is a one-time repository configuration change.

## Current Status

✅ Custom CodeQL workflow configured for Python, Swift, and JavaScript/TypeScript  
✅ Workflow file is valid and properly configured  
❌ **Blocked**: Repository has default CodeQL setup enabled, causing conflicts

## Error Message

When the workflow runs, you'll see:
```
CodeQL analyses from advanced configurations cannot be processed when the default setup is enabled
```

## Solution (Repository Owner Must Complete)

### Step 1: Disable Default CodeQL Setup

1. Go to your repository on GitHub.com
2. Click **Settings** tab
3. In the left sidebar, click **Security** → **Code scanning**
4. Find "CodeQL analysis" with a "Default" label
5. Click the **"..."** menu button next to it
6. Select **"Switch to advanced"** or **"Disable CodeQL"**
7. Confirm the action

### Step 2: Verify the Custom Workflow Works

After disabling the default setup:
1. The existing pull request checks will automatically re-run
2. Or you can manually re-run the failed workflow from the Actions tab
3. All three language analyses should complete successfully

## What This Workflow Provides

Once enabled, you get:

- **Comprehensive Security Scanning**
  - Python code (backend + worker)
  - Swift code (iOS app + tests)
  - JavaScript/TypeScript code (web frontend)

- **Advanced Query Suites**
  - `security-extended` - Extended security analysis
  - `security-and-quality` - Code quality + security checks

- **Automated Scanning**
  - Every push to main/develop branches
  - Every pull request
  - Weekly scheduled scans (Sunday midnight UTC)

## Alternative Option

If you prefer to use GitHub's default CodeQL setup instead:
1. Keep the default setup enabled
2. Delete this custom workflow file (`.github/workflows/codeql.yml`)
3. The default setup will handle all languages automatically

**Note**: The custom workflow provides more control over query suites, build configuration, and path filtering.

## Need Help?

If you encounter issues after following these steps, check:
- Actions tab for detailed error logs
- `.github/workflows/README.md` for troubleshooting guide
- GitHub's CodeQL documentation: https://docs.github.com/en/code-security/code-scanning

## Questions?

- **Q**: Why can't both run at the same time?
  - **A**: GitHub doesn't allow custom advanced configurations when default setup is active to avoid duplicate analysis and conflicts.

- **Q**: Which setup is better?
  - **A**: Default setup is easier but less customizable. Advanced (this workflow) gives full control over queries, build process, and scanning options.

- **Q**: Will this affect my security?
  - **A**: No. After switching, you'll have the same (or better) security scanning with the custom workflow.
