import json
import time
from random import randint
from behave import *
from steps import utils


@given('An IoT message is sent to the platform for device {device} with temperature '
       '{temperature} in topic {topic}')
def step_impl(context, device, temperature, topic):
    print("given mqtt")
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


@when('Request through API the {endpoint_type} for device {device}')
def step_impl(context, endpoint_type, device):
    print(f"Request through API the {endpoint_type} for device {device}")


@then('For device {device}, the temperature of the last value should be equal to {temperature}')
def step_impl(context, device, temperature):
    core_v1 = utils.get_core_v1()
    back_end_pod_name = f"back-end-pod-{randint(0, 10000)}"
    back_end_pod_manifest = utils.get_back_end_pod_manifest(back_end_pod_name, f"/device/last-value/{device}")
    raw_result = utils.run_pod(core_v1, back_end_pod_name, back_end_pod_manifest)
    result = json.loads(raw_result.replace("\'", "\""))
    print(f"result: {result}")
    print(f"temperature: {temperature}")
    print(f'temperature in row: {result["rows"][0]["temperature"]}')
    print(f"type temperature: {type(temperature)}")
    print(f'type temperature in row: {type(result["rows"][0]["temperature"])}')
    #utils.delete_pod(core_v1, back_end_pod_name)
    assert (result["rows"][0]["temperature"] == int(temperature))



@then('For device {device}, timeseries should contain {number_of_elements} elements and temperatures should be')
def step_impl(context, device, number_of_elements):
    core_v1 = utils.get_core_v1()
    back_end_pod_name = f"back-end-pod-{randint(0, 10000)}"
    timeseries_uri = f"/device/timeseries/{device}?from_date={utils.get_past_timestamp(12)}&to_date={utils.get_current_timestamp()}"
    back_end_pod_manifest = utils.get_back_end_pod_manifest(back_end_pod_name, timeseries_uri)
    raw_result = utils.run_pod(core_v1, back_end_pod_name, back_end_pod_manifest)
    #utils.delete_pod(core_v1, back_end_pod_name)
    print(f"result: {raw_result}")
    result = json.loads(raw_result.replace("\'", "\""))
    temperatures = [element["temperature"] for element in result["rows"]]
    print(f"result: {result}")
    print(f"temperatures: {temperatures}")
    print([int(row['temperatures']) for row in context.table])
    assert (len(result["rows"]) == int(number_of_elements))
    assert temperatures is [int(row['temperatures']) for row in context.table]


