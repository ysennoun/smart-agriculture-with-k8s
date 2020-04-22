from flask import Flask
from flask_cors import CORS

app = Flask(__name__)
CORS(app)


@app.route('/devices')
def get_devices():
    return '{"rows":["device1", "device2", "device3"]}'


@app.route('/devices/<string:device>/last-value')
def get_last_value(device):
    return '{"rows":[{"timestamp":"2020-04-10T12:32:33Z", "temperature":21, "moisture":54, "device":"device1"}]}'


@app.route('/devices/<string:device>/timeseries')
def get_timeseries(device):
    return '{"rows":[{"timestamp":"2020-04-10T12:32:33Z", "temperature":21, "moisture":54, "device":"device"}, {"timestamp":"2020-05-10T12:32:33Z", "temperature":22, "moisture":57, "device":"device"},{"timestamp":"2020-06-10T12:32:33Z", "temperature":19, "moisture":70, "device":"device"},{"timestamp":"2020-07-10T12:32:33Z", "temperature":27, "moisture":44, "device":"device"},{"timestamp":"2020-08-10T12:32:33Z", "temperature":7, "moisture":89, "device":"{device}"}]}'


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)