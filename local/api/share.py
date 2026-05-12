import hmac, hashlib, time, base64, json, os

SHARE_SECRET = os.environ["SHARE_SECRET"]

def generate_share_token(username: str, file_id: str, ttl_seconds: int) -> str:
    expires_at = int(time.time()) + ttl_seconds
    payload = f"{username}:{file_id}:{expires_at}"
    sig = hmac.new(SHARE_SECRET.encode(), payload.encode(), hashlib.sha256).hexdigest()
    token = base64.urlsafe_b64encode(f"{payload}:{sig}".encode()).decode()
    return f"https://local-storage-dev.t1gs.com/share/{token}"

def validate_share_token(token: str) -> tuple[str, str]:  # (username, file_id)
    decoded = base64.urlsafe_b64decode(token.encode()).decode()
    *parts, sig = decoded.split(":")
    username, file_id, expires_at = parts
    expected = hmac.new(SHARE_SECRET.encode(), ":".join(parts).encode(), hashlib.sha256).hexdigest()
    if not hmac.compare_digest(sig, expected):
        raise ValueError("Invalid signature")
    if int(time.time()) > int(expires_at):
        raise ValueError("Token expired")
    return username, file_id