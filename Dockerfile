FROM python:3.11-slim

# Runtime dependencies only (no dev/test/viz tools)
RUN pip install --no-cache-dir \
    pandas==1.5.3 \
    numpy==1.24.3 \
    scikit-learn==1.2.2 \
    xgboost==1.7.5 \
    fastapi==0.95.2 \
    uvicorn==0.22.0 \
    pyyaml==6.0 \
    joblib==1.3.1

WORKDIR /app
COPY src/api/ ./src/api/
COPY models/trained/ ./models/trained/
EXPOSE 8000
CMD ["uvicorn", "src.api.main:app", "--host", "0.0.0.0", "--port", "8000"]