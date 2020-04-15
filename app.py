from flask import Flask
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

@app.route('/hello')
def helloIndex():
    return '{"rows":[{"timestamp":"2020-04-10T12:32:33Z", "temperature":21, "moisture":54, "device":"device1"}]}'

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080)