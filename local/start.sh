docker compose up -d minio
docker compose up -d --build api
docker compose up --build nginx

docker compose down
