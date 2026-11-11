from flask import Flask
from waitress import serve
import os

app = Flask(__name__)

@app.route("/")
def index():
    return f"<h1>Hello Remco from STACKIT</h1><p>Version: {os.getenv('APP_VERSION', 'dev')}</p>"

@app.route("/healthz")
def health():
    return "ok", 200

if __name__ == "__main__":
    serve(app, host="0.0.0.0", port=8080)