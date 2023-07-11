import os

import google.auth.transport.requests
import google.oauth2.id_token
import requests
from flask import Flask, redirect, render_template

app = Flask(__name__)


@app.route("/todo", methods=["GET"])
def scan():
    back_url = os.environ["BACK_URL"]
    print(f"{back_url=}")
    response = requests.get(back_url, headers=get_headers())
    todos = response.json()
    return render_template("scan.html", todos=todos)


@app.route("/todo/new", methods=["GET"])
def new():
    return render_template("new.html")


@app.route("/todo", methods=["POST"])
def create():
    back_url = os.environ["BACK_URL"]
    todo = {"text": "hoge"}
    response = requests.post(back_url, headers=get_headers(), json=todo)
    return redirect("/")


def issue_id_token(endpoint: str) -> str:
    auth_req = google.auth.transport.requests.Request()
    id_token = google.oauth2.id_token.fetch_id_token(auth_req, endpoint)
    return id_token


def get_headers(endpoint: str) -> dict[str, str]:
    id_token = issue_id_token(endpoint)
    return {"Authorization": f"Bearer {id_token}"}
