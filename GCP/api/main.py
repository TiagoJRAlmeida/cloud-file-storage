from fastapi import FastAPI, Depends, HTTPException, UploadFile, File, Query
from fastapi.responses import Response
from pydantic import BaseModel
from contextlib import asynccontextmanager
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from auth import (
    USERS,
    USER_QUOTA,
    verify_password,
    create_access_token,
    get_current_user,
)
from storage import (
    ensure_bucket,
    upload_file,
    download_file,
    delete_file,
    list_files,
    get_metadata,
    get_user_storage_used,
    generate_presigned_url,
)
import uuid
import time


# Runs before the API starts
@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        ensure_bucket()
    except Exception as e:
        print(f"WARNING: Could not ensure bucket on startup: {e}")
    yield


app = FastAPI(title="Cloud File Storage API", version="1.0.0", lifespan=lifespan)


# --- Prometheus metrics ---
REQUEST_COUNT = Counter(
    "api_requests_total", "Total requests", ["method", "endpoint", "status"]
)
REQUEST_LATENCY = Histogram(
    "api_request_latency_seconds", "Request latency", ["endpoint"]
)


# --- Auth ---
## Example Login with Curl:
"""
curl -X POST http://storage.t1gs.com:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "alice", "password": "password123"}'
"""


class LoginRequest(BaseModel):
    username: str
    password: str


@app.post("/auth/login", tags=["Auth"])
def login(body: LoginRequest):
    hashed = USERS.get(body.username)
    if not hashed or not verify_password(body.password, hashed):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    token = create_access_token(body.username)  # Create the JWT
    return {"access_token": token, "token_type": "bearer"}


# --- Files ---
## Example Upload of a file with Curl
"""
TOKEN=$(curl -s -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "alice", "password": "password123"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

# Then use it in subsequent requests
curl -X POST http://localhost:8000/files/upload \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/home/tiago/pictures/tuff_goose.jpeg"
"""


@app.post("/files/upload", tags=["Files"])
def upload(file: UploadFile = File(...), username: str = Depends(get_current_user)):
    start = time.time()
    data = file.file.read()

    # Quota check
    used = get_user_storage_used(username)
    if used + len(data) > USER_QUOTA:
        raise HTTPException(
            status_code=413,
            detail=f"Storage quota exceeded. Used: {used}. len(data): {len(data)}. USER_QUOTA: {USER_QUOTA}",
        )

    file_id = str(uuid.uuid4())
    filename = file.filename or "unnamed"
    file_content_type = file.content_type or "application/octet-stream"
    try:
        upload_file(
            username,
            file_id,
            data,
            filename,
            file_content_type,
        )
    except Exception:
        raise HTTPException(status_code=500, detail="Upload failed")

    REQUEST_LATENCY.labels("/files/upload").observe(time.time() - start)
    REQUEST_COUNT.labels("POST", "/files/upload", "200").inc()
    return {"file_id": file_id, "filename": file.filename, "size": len(data)}


@app.get("/files", tags=["Files"])
def list_user_files(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    username: str = Depends(get_current_user),
):
    all_files = list_files(username)
    start = (page - 1) * page_size
    end = start + page_size
    return {
        "files": all_files[start:end],
        "total": len(all_files),
        "page": page,
        "page_size": page_size,
    }


@app.get("/files/{file_id}", tags=["Files"])
def download(file_id: str, username: str = Depends(get_current_user)):
    try:
        data = download_file(username, file_id)
        meta = get_metadata(username, file_id)
        return Response(
            content=data,
            media_type=meta["content_type"],
            headers={
                "Content-Disposition": f'attachment; filename="{meta["filename"]}"'
            },
        )
    except Exception:
        raise HTTPException(status_code=404, detail="File not found")


@app.delete("/files/{file_id}", tags=["Files"])
def delete(file_id: str, username: str = Depends(get_current_user)):
    try:
        delete_file(username, file_id)
        return {"message": "File deleted"}
    except Exception:
        raise HTTPException(status_code=404, detail="File not found")


@app.post("/files/{file_id}/share", tags=["Files"])
def share(
    file_id: str, ttl_seconds: int = 3600, username: str = Depends(get_current_user)
):
    try:
        url = generate_presigned_url(username, file_id, ttl_seconds)
        return {"presigned_url": url, "expires_in_seconds": ttl_seconds}
    except Exception:
        raise HTTPException(status_code=404, detail="File not found")


@app.get("/files/{file_id}/meta", tags=["Files"])
def metadata(file_id: str, username: str = Depends(get_current_user)):
    try:
        return get_metadata(username, file_id)
    except Exception:
        raise HTTPException(status_code=404, detail="File not found")


# --- System ---
@app.get("/health", tags=["System"])
def health():
    return {"status": "ok"}
