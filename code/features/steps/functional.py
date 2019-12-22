import json
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


@then('For device "{device}", the temperature of the last value should be equal to "{temperature}"')
def step_impl(context, device, temperature):
    api_url = utils.get_service_url(environment.API_SERVICE_NAME)
    last_value = utils.get_last_value(api_url, device)
    assert last_value["temperature"] is temperature


@then('For device "{device}", timeseries should contain "{number_of_elements}" elements '
      'and temperatures should be "{temperatures}"')
def step_impl(context, device, number_of_elements, temperatures):
    api_url = utils.get_service_url(environment.API_SERVICE_NAME)
    timeseries = utils.get_timeseries(api_url, device)
    temperatures = timeseries["temperature"]
    assert context is temperatures
