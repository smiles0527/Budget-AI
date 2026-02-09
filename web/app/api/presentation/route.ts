import { NextResponse } from "next/server";
import { Redis } from "@upstash/redis";

const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD;
const KV_KEY = "snapbudget:presentation-url";

/* Fall back gracefully if Redis isn't configured yet */
function getRedis(): Redis | null {
  const url = process.env.KV_REST_API_URL;
  const token = process.env.KV_REST_API_TOKEN;
  if (!url || !token) return null;
  return new Redis({ url, token });
}

/** GET — read the current global presentation URL */
export async function GET() {
  const redis = getRedis();
  if (!redis) {
    return NextResponse.json({ url: "" });
  }

  const url = await redis.get<string>(KV_KEY);
  return NextResponse.json({ url: url ?? "" });
}

/** POST — admin sets a new global presentation URL */
export async function POST(request: Request) {
  const body = await request.json();
  const { url, password } = body as { url?: string; password?: string };

  if (!ADMIN_PASSWORD) {
    return NextResponse.json(
      { error: "ADMIN_PASSWORD env var not set" },
      { status: 500 }
    );
  }
  if (password !== ADMIN_PASSWORD) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const redis = getRedis();
  if (!redis) {
    return NextResponse.json(
      { error: "Redis not configured. Add KV_REST_API_URL and KV_REST_API_TOKEN env vars." },
      { status: 500 }
    );
  }

  if (url) {
    await redis.set(KV_KEY, url);
  } else {
    await redis.del(KV_KEY);
  }

  return NextResponse.json({ ok: true, url: url ?? "" });
}
