import json
import logging
from random import randint
from behave import *
from steps import utils


@given('An IoT message is sent to the platform for device {device} with temperature '
       '{temperature} in topic {topic}')
def step_impl(context, device, temperature, topic):
    logging.info("given mqtt")
    iot_data = json.dumps({
        "device": device,
        "timestamp": utils.get_current_timestamp(),
        "temperature": int(temperature),
        "pressure": 10,
        "moisture": 10
    })
    utils.send_mqtt_payload(topic, iot_data)


@when('Request through API the {endpoint_type} for device {device}')
def step_impl(context, endpoint_type, device):
    logging.info(f"Request through API the {endpoint_type} for device {device}")


@then('For device {device}, the temperature of the last value should be equal to {temperature}')
def step_impl(context, device, temperature):
    back_end_response = utils.get_back_end_response(f"/devices/{device}/lastValue")
    result = json.loads(back_end_response.replace("\'", "\""))
    assert (result["rows"][0]["temperature"] == int(temperature))


@then('For device {device}, timeseries should contain {number_of_elements} elements and temperatures should be')
def step_impl(context, device, number_of_elements):
    timeseries_uri = f"/devices/{device}/timeseries?from_date={utils.get_past_timestamp(15)}&to_date={utils.get_current_timestamp()}"
    back_end_response = utils.get_back_end_response(timeseries_uri)
    result = json.loads(back_end_response.replace("\'", "\""))
    temperatures = [element["temperature"] for element in result["rows"]]
    logging.info([int(row['temperatures']) for row in context.table])
    assert (len(result["rows"]) == int(number_of_elements))
    assert (temperatures == [int(row['temperatures']) for row in context.table])