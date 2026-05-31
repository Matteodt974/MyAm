FROM python:3.11-slim

WORKDIR /app

# Évite les .pyc et bufferise pas les logs (utile pour voir les logs Render en direct)
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

EXPOSE 8000

# Forme shell (et non exec) pour que ${PORT} soit interprété.
# Render injecte automatiquement la variable PORT ; en local on retombe sur 8000.
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
