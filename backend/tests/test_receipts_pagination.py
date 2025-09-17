import os
import requests

BASE = os.environ.get("BASE_URL", "http://localhost:8000")


def signup_and_login(email: str, password: str) -> str:
    r = requests.post(f"{BASE}/v1/auth/signup", json={"email": email, "password": password})
    assert r.status_code in (200, 409)
    r = requests.post(f"{BASE}/v1/auth/login", json={"email": email, "password": password})
    assert r.status_code == 200
    return r.json()["token"]


def create_manual_txn(token: str, total: int = 100):
    headers = {"Authorization": f"Bearer {token}"}
    r = requests.post(
        f"{BASE}/v1/transactions/manual",
        headers=headers,
        json={"txn_date": "2025-01-01", "total_cents": total},
    )
    assert r.status_code == 200


def test_transactions_pagination():
    token = signup_and_login("ci2@example.com", "secret")
    # Seed over a page
    for i in range(60):
        create_manual_txn(token, total=100 + i)
    headers = {"Authorization": f"Bearer {token}"}

    r = requests.get(f"{BASE}/v1/transactions?limit=25", headers=headers)
    assert r.status_code == 200
    page1 = r.json()
    assert len(page1["items"]) <= 25
    assert page1.get("next_cursor") is not None

    r = requests.get(f"{BASE}/v1/transactions?limit=25&cursor={page1['next_cursor']}", headers=headers)
    assert r.status_code == 200
    page2 = r.json()
    assert len(page2["items"]) <= 25

