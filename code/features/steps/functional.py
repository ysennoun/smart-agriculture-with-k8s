import json
import time
from behave import *
from steps import utils, environment


@given('An IoT message is sent to the platform for device "{device}" with temperature '
       '"{temperature}" in topic "{topic}"')
def step_impl(context, device, temperature, topic):
    iot_data = json.dumps({
        "device": device,
        "timestamp": str(utils.get_current_timestamp()),
        "temperature": temperature,
        "pressure": "10",
        "moisture": "10"
    })
    mqtt_broker_url = utils.get_service_url(environment.MQTT_SERVICE_NAME)
    utils.send_mqtt_message(iot_data, topic, mqtt_broker_url)


@given('wait "{min}" min to let system handle data')
def step_impl(context, min):
    time.sleep(min * 60)


@then('For device "{device}", the temperature of the last value should be equal to "{temperature}"')
def step_impl(context, device, temperature):
    api_url = utils.get_service_url(environment.API_SERVICE_NAME)
    last_value = utils.get_endpoint_value(api_url, "/device/last-value/", device)
    assert last_value["temperature"] is temperature


@then('For device "{device}", timeseries should contain "{number_of_elements}" elements '
      'and temperatures should be in')
def step_impl(context, device, number_of_elements):
    api_url = utils.get_service_url(environment.API_SERVICE_NAME)
    timeseries = utils.get_endpoint_value(api_url, "/device/timeseries/", device)
    temperatures = [timeserie["temperature"] for timeserie in timeseries]
    assert number_of_elements is len(timeseries)
    assert temperatures is context.table


@then('For device "{device}", summarized should contain "{number_of_elements}" elements '
      'and temperatures should be in')
def step_impl(context, device, number_of_elements):
    api_url = utils.get_service_url(environment.API_SERVICE_NAME)
    summarized = utils.get_endpoint_value(api_url, "/device/summarized/", device)
    temperatures = [timeserie["temperature"] for timeserie in summarized]
    assert number_of_elements is len(summarized)
    assert temperatures is context.table