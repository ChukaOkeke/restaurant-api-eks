#!/bin/sh
set -e

# Wait for database connectivity before running migrations (if host & port are set)
if [ "$RUN_MIGRATIONS" = "true" ] && [ -n "$DB_HOST" ] && [ -n "$DB_PORT" ]; then
    echo "Waiting for database at $DB_HOST:$DB_PORT..."
    while ! nc -z -w 1 "$DB_HOST" "$DB_PORT"; do
        echo "Database is unavailable - sleeping 1s"
        sleep 1
    done
    echo "Database is reachable."
fi

# Run migrations if explicitly enabled for this container execution
if [ "$RUN_MIGRATIONS" = "true" ]; then
    echo "Running database migrations..."
    python manage.py migrate --noinput
fi

# Collect static assets if S3 static storage upload is enabled
if [ "$COLLECT_STATIC" = "true" ]; then
    echo "Collecting static assets..."
    python manage.py collectstatic --noinput --clear
fi

# Execute the container's CMD or Kubernetes command override
exec "$@"