import boto3
from botocore.client import Config
import os

# Althought MinIO has it's own library, using boto3 is more interesting
# because it is more popular, as it the API to control official AWS S3 buckets,
# and as such allows more flexibility so that, if necessary, we could easilly
# change from MinIO to AWS S3 buckets.


# This is set on the docker image
MINIO_ENDPOINT = os.getenv("MINIO_ENDPOINT", "http://minio:9000")
MINIO_ACCESS = os.getenv("MINIO_ACCESS_KEY", "minioadmin")
MINIO_SECRET = os.getenv("MINIO_SECRET_KEY", "minioadmin")
BUCKET_NAME = "files"

s3 = boto3.client(
    "s3",
    endpoint_url=MINIO_ENDPOINT,
    aws_access_key_id=MINIO_ACCESS,
    aws_secret_access_key=MINIO_SECRET,
    config=Config(signature_version="s3v4"),
    region_name="us-east-1",  # MinIO ignores this but boto3 requires it
)


def ensure_bucket():
    existing = [b["Name"] for b in s3.list_buckets()["Buckets"]]
    if BUCKET_NAME not in existing:
        s3.create_bucket(Bucket=BUCKET_NAME)


def upload_file(
    username: str, file_id: str, data: bytes, filename: str, content_type: str
):
    s3.put_object(
        Bucket=BUCKET_NAME,
        Key=f"{username}/{file_id}",
        Body=data,
        ContentType=content_type,
        Metadata={"filename": filename, "owner": username},
    )


def download_file(username: str, file_id: str) -> bytes:
    obj = s3.get_object(Bucket=BUCKET_NAME, Key=f"{username}/{file_id}")
    return obj["Body"].read()


def delete_file(username: str, file_id: str):
    s3.delete_object(Bucket=BUCKET_NAME, Key=f"{username}/{file_id}")


def list_files(username: str) -> list:
    response = s3.list_objects_v2(Bucket=BUCKET_NAME, Prefix=f"{username}/")
    objects = response.get("Contents", [])
    result = []
    for obj in objects:
        file_id = obj["Key"].split("/", 1)[1]
        meta = s3.head_object(Bucket=BUCKET_NAME, Key=obj["Key"])["Metadata"]
        result.append(
            {
                "file_id": file_id,
                "filename": meta.get("filename", file_id),
                "size": obj["Size"],
                "uploaded_at": obj["LastModified"].isoformat(),
            }
        )
    return result


def get_metadata(username: str, file_id: str) -> dict:
    head = s3.head_object(Bucket=BUCKET_NAME, Key=f"{username}/{file_id}")
    meta = head["Metadata"]
    return {
        "file_id": file_id,
        "filename": meta.get("filename", file_id),
        "size": head["ContentLength"],
        "content_type": head["ContentType"],
        "uploaded_at": head["LastModified"].isoformat(),
        "owner": meta.get("owner", username),
    }


def get_user_storage_used(username: str) -> int:
    response = s3.list_objects_v2(Bucket=BUCKET_NAME, Prefix=f"{username}/")
    return sum(obj["Size"] for obj in response.get("Contents", []))


def generate_presigned_url(username: str, file_id: str, ttl_seconds: int) -> str:
    return s3.generate_presigned_url(
        "get_object",
        Params={"Bucket": BUCKET_NAME, "Key": f"{username}/{file_id}"},
        ExpiresIn=ttl_seconds,
    )
