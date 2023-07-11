import os
import urllib.request

import google.auth.transport.requests
import google.oauth2.id_token
import requests
from flask import Flask, render_template

app = Flask(__name__)


@app.route("/test")
def test():
    render_template("test.html")


@app.route("/create", methods=["POST"])
def create():
    back_url = os.environ["BACK_URL"]
    print(f"{back_url=}")
    requests.post(back_url, headers=get_headers(), json={"text": "hoge"})


@app.route("/")
def hello_world():
    return "<p>Hello, World!</p>"


def issue_id_token(endpoint: str) -> str:
    auth_req = google.auth.transport.requests.Request()
    id_token = google.oauth2.id_token.fetch_id_token(auth_req, endpoint)
    return id_token


def get_headers(endpoint: str) -> dict[str, str]:
    id_token = issue_id_token(endpoint)
    headers = dict()
    headers["Authorization"] = f"Bearer {id_token}"
    return headers
