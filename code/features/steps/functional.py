import json
import time
from random import randint
from behave import *
from steps import utils


@given('An IoT message is sent to the platform for device {device} with temperature '
       '{temperature} in topic {topic}')
def step_impl(context, device, temperature, topic):
    iot_data = json.dumps({
        "device": device,
        "timestamp": utils.get_current_timestamp(),
        "temperature": int(temperature),
        "pressure": 10,
        "moisture": 10
    })
    mqtt_pod_name = f"mqtt-pod-{randint(0, 10000)}"
    core_v1 = utils.get_core_v1()
    mqtt_pod_manifest = utils.get_mqtt_pod_manifest(mqtt_pod_name, iot_data, topic)
    utils.run_pod(core_v1, mqtt_pod_name, mqtt_pod_manifest)
    utils.delete_pod(core_v1, mqtt_pod_name)


@given('wait {min} min to let system handle data')
def step_impl(context, min):
    time.sleep(min * 60)


@then('For device {device}, the temperature of the last value should be equal to {temperature}')
def step_impl(context, device, temperature):
    core_v1 = utils.get_core_v1()
    back_end_pod_name = f"back-end-pod-{randint(0, 10000)}"
    back_end_pod_manifest = utils.get_back_end_pod_manifest(back_end_pod_name, f"/device/last-value/{device}")
    result = utils.run_pod(core_v1, back_end_pod_name, back_end_pod_manifest)
    utils.delete_pod(core_v1, back_end_pod_name)
    assert json.loads(result)["rows"][0]["temperature"] is temperature


@then('For device {device}, timeseries should contain {number_of_elements} elements '
      'and temperatures should be in')
def step_impl(context, device, number_of_elements):
    core_v1 = utils.get_core_v1()
    back_end_pod_name = f"back-end-pod-{randint(0, 10000)}"
    back_end_pod_manifest = utils.get_back_end_pod_manifest(back_end_pod_name, f"/device/timeseries/{device}")
    result = utils.run_pod(core_v1, back_end_pod_name, back_end_pod_manifest)
    utils.delete_pod(core_v1, back_end_pod_name)
    timeseries = json.loads(result)["rows"]
    temperatures = [element["temperature"] for element in timeseries]
    assert number_of_elements is len(timeseries)
    assert temperatures is context.table
