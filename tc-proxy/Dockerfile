FROM python:3.11-slim

WORKDIR /app

# 安裝 curl（用於健康檢查）和 Python 依賴
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

EXPOSE 10096

CMD ["python", "main.py"]
