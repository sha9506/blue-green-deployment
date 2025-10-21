FROM python:3.10-slim
WORKDIR /app
COPY app/ /app
RUN pip install -r requirements.txt
ENV PORT=5000
EXPOSE 5000
CMD ["python", "app.py"]
