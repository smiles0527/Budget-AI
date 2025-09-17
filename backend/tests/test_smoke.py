import os
import requests

BASE = os.environ.get("BASE_URL", "http://localhost:8000")


def test_healthz():
    r = requests.get(f"{BASE}/healthz")
    assert r.status_code == 200
    assert r.json().get("status") == "ok"


