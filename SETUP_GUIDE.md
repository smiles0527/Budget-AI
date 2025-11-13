# Complete Setup Guide - Get Everything Running

## Step 1: Install Docker Desktop

### On macOS:
1. **Download Docker Desktop:**
   - Go to: https://www.docker.com/products/docker-desktop/
   - Click "Download for Mac"
   - Choose the right version (Intel or Apple Silicon/M1/M2)

2. **Install:**
   - Open the downloaded `.dmg` file
   - Drag Docker to Applications folder
   - Open Docker from Applications
   - Follow the setup wizard
   - **Important:** You may need to enter your password

3. **Verify it's running:**
   - Look for the Docker whale icon in your menu bar (top right)
   - If it's running, you'll see it there
   - Click it → "Docker Desktop is running" ✅

### Troubleshooting:
- **"Docker Desktop requires privileged access"** → Enter your Mac password
- **Can't start Docker** → Make sure virtualization is enabled in System Settings
- **Still having issues?** → Check Docker Desktop status in menu bar

## Step 2: Start the Backend Services

Once Docker is running:

```bash
# Navigate to your project folder
cd /home/yuqiao/codes/Budget-AI

# Start database and storage first
docker compose up -d db minio

# Wait for database to be ready (about 10 seconds)
sleep 10

# Apply database migrations (creates all tables)
docker exec snapbudget-postgres sh -c "mkdir -p /migrations"
for file in db/migrations/*.sql; do
  echo "Applying $(basename $file)..."
  docker cp "$file" snapbudget-postgres:/migrations/$(basename "$file")
  docker exec -e PGPASSWORD=password snapbudget-postgres psql -h 127.0.0.1 -U app -d appdb -f "/migrations/$(basename "$file")" || true
done

# Now start API and worker
docker compose up -d api worker
```

**What this does:**
- `-d` = runs in background (detached mode)
- Starts: Database, Storage, then API and Worker
- Applies database migrations to create all tables

**Wait about 30 seconds** for everything to start up.

## Step 3: Verify Backend is Running

Check if the API is working:

```bash
# Test the API health endpoint
curl http://localhost:8000/healthz
```

**Expected response:** `{"status":"ok"}` or similar

**Or open in browser:**
- http://localhost:8000/healthz
- Should show `{"status":"ok"}`

## Step 4: Run Your iOS App

```bash
# Open the Xcode project
open testapp.xcodeproj
```

**In Xcode:**
1. Select **iPhone 15 Pro** (or any simulator) from the device dropdown
2. Press **⌘R** (or click the Play button)
3. App should launch!

## Step 5: Test It!

1. **Sign up** with a test email
2. **Login** with your credentials
3. **Try uploading a receipt** (use photo library on simulator)
4. **Create a budget**
5. **Check the dashboard**

## Common Issues & Solutions

### Issue: "Cannot connect to server"
**Solution:**
```bash
# Check if Docker is running
docker ps

# Should show 4 containers running:
# - snapbudget-postgres
# - snapbudget-api
# - snapbudget-minio
# - snapbudget-worker

# If not running, start them:
docker compose up -d db minio api worker

# Check logs if something's wrong:
docker compose logs api
```

### Issue: "Port 8000 already in use"
**Solution:**
```bash
# Find what's using port 8000
lsof -i :8000

# Stop Docker containers
docker compose down

# Start again
docker compose up -d db minio api worker
```

### Issue: Docker Desktop won't start
**Solutions:**
- Restart your Mac
- Check System Settings → Privacy & Security → Allow Docker
- Make sure you have enough disk space (Docker needs ~5GB)

### Issue: "Database connection failed"
**Solution:**
```bash
# Restart everything
docker compose down
docker compose up -d db minio api worker

# Wait 30 seconds, then check:
docker compose logs api
```

## Daily Workflow

**Every time you want to work:**

1. **Start Docker Desktop** (if not already running)
   - Look for whale icon in menu bar

2. **Start backend:**
   ```bash
   docker compose up -d db minio api worker
   ```

3. **Open Xcode:**
   ```bash
   open testapp.xcodeproj
   ```

4. **Press ⌘R** to run

**When you're done:**
```bash
# Stop backend (optional - saves resources)
docker compose down
```

## Quick Commands Reference

```bash
# Start everything
docker compose up -d db minio api worker

# Stop everything
docker compose down

# View logs
docker compose logs api
docker compose logs worker

# Check what's running
docker ps

# Restart if something breaks
docker compose restart
```

## Need Help?

**Check if Docker is running:**
- Menu bar → Docker icon → Should say "Docker Desktop is running"

**Check if backend is running:**
```bash
curl http://localhost:8000/healthz
```

**Check Docker containers:**
```bash
docker ps
```

**View error logs:**
```bash
docker compose logs
```

---

## TL;DR - Quick Start

1. Install Docker Desktop (download from docker.com)
2. Open Docker Desktop (wait for it to start)
3. Run: `docker compose up -d db minio api worker`
4. Open: `open testapp.xcodeproj`
5. Press ⌘R in Xcode
6. Done! 🎉

