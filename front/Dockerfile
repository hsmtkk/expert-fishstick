FROM python:3.11
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD flask --app front run --host=0.0.0.0 --port=$PORT
