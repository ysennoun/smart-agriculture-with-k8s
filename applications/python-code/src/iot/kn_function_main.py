import os

from flask import Flask
from flask import request
from iot.iot_handler import handler
from iot.env import get_port

app = Flask(__name__)
HOST = '0.0.0.0'
PORT = get_port()

@app.route('/')
def post():
    data = request.form
    return handler(data)

if __name__ == "__main__":
    app.run(
        debug=True,
        host=HOST,
        port=PORT
    )