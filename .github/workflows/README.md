# CodeQL Configuration

This directory contains the CodeQL security scanning workflow for the Budget-AI project.

## Workflow Overview

The `codeql.yml` workflow performs automated security analysis on three languages:

- **Python** - Backend API (`backend/`) and background worker (`worker/`)
- **Swift** - iOS application (`BudgetAI/`, `BudgetAITests/`, `BudgetAIUITests/`, `testapp/`)
- **JavaScript/TypeScript** - Next.js web frontend (`web/`)

## Triggers

- **Push/Pull Requests**: Runs on all pushes and PRs to `main` and `develop` branches
- **Weekly Scan**: Scheduled to run every Sunday at midnight UTC

## Query Suites

The workflow uses two comprehensive query suites:
- `security-extended` - Extended security queries
- `security-and-quality` - Combined security and code quality checks

## Important Setup Note

⚠️ **GitHub Default CodeQL Setup Conflict**

If you see errors like:
```
CodeQL analyses from advanced configurations cannot be processed when the default setup is enabled
```

This means the repository has GitHub's default CodeQL setup enabled. To use this custom workflow:

1. Go to repository **Settings** → **Security** → **Code scanning**
2. Find "CodeQL analysis" with "Default" label
3. Click the **"..."** menu → **"Disable CodeQL"** or **"Switch to advanced"**
4. The custom workflow will then work without conflicts

## Build Configuration

- **Python & JavaScript/TypeScript**: No build required (interpreted languages)
- **Swift**: Manual build using `xcodebuild` with:
  - Generic iOS Simulator destination for compatibility
  - Code signing disabled (`CODE_SIGNING_ALLOWED=NO`)
  - 360-minute timeout to accommodate build time

## Benefits

✅ Comprehensive multi-language security scanning  
✅ Detects vulnerabilities across entire codebase  
✅ Automated weekly security audits  
✅ Runs on every code change  
✅ Uses advanced security query suites  

## Troubleshooting

### Swift Build Timeout
If the Swift build times out, consider:
- Using a faster macOS runner
- Reducing the scope of files to analyze
- Caching build dependencies

### Analysis Failures
Check the Actions tab for detailed logs. Common issues:
- Build errors in Swift code
- Syntax errors in source files
- Configuration conflicts with default setup
