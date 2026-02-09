# ⚠️ ATTENTION: CodeQL Workflow Requires Your Action

## The Error You're Seeing

```
CodeQL analyses from advanced configurations cannot be processed 
when the default setup is enabled
```

## What This Means

**YOU** (the repository owner) need to change a setting in your repository. I cannot do this for you because it's a repository configuration, not code.

## How to Fix (2 Minutes)

### Option 1: Use the Custom Workflow (Recommended)

1. Open your repository on GitHub.com
2. Click **Settings** → **Security** → **Code security and analysis**
3. Find "CodeQL analysis" with a **"Default"** label
4. Click the **"..."** menu → **"Switch to advanced"**
5. Done! The workflow will now work.

📖 **See `.github/CODEQL_SETUP.md` for detailed step-by-step instructions**

### Option 2: Use GitHub's Default Setup

If you don't want the custom workflow:
1. Delete `.github/workflows/codeql.yml`
2. Keep the default setup enabled
3. Done!

## Why This Happens

- GitHub doesn't allow **both** default setup **and** custom workflows
- You must choose one or the other
- This is intentional to avoid duplicate analyses

## Current Status

| Item | Status |
|------|--------|
| Workflow code | ✅ Correct and ready |
| Configuration | ✅ Valid |
| **Your action needed** | ❌ **Repository setting** |

**The workflow is perfectly configured. It just can't run until you change the repository setting.**

---

**Questions?** Read `.github/CODEQL_SETUP.md` or check the PR description for more details.
