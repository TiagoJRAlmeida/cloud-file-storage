docker compose up -d minio
docker compose up -d --build api
docker compose up -d tunnel
docker compose up -d --build nginx

