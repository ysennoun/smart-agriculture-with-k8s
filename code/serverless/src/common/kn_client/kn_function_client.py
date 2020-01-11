import os
import requests
from common.utils.logger import Logger

logger = Logger().get_logger()


_NAMESPACE = "default"
_DOMAIN = "example"
_TIMEOUT = 7


def _get_kn_function_headers(kn_function_name, namespace, domain):
    host = f"{kn_function_name}.{namespace}.{domain}.com"
    return {"Host": host}


def _get_istio_ingressgateway_url():
    ip_address = os.environ["ISTIO_INGRESS_GATEWAY_IP_ADDRESS"]
    return f"http://{ip_address}"


def invoke_kn_function(kn_function_name, data):
    try:
        url = _get_istio_ingressgateway_url()
        headers = _get_kn_function_headers(
                kn_function_name=kn_function_name, 
                namespace=_NAMESPACE, 
                domain=_DOMAIN
            )
        result = requests.post(
                url=url, 
                headers=headers,
                data=data, 
                timeout=_TIMEOUT
            )
        logger.info(f"INVOKE Kn Function: {result.text}")
        return result
    except Exception as ex:
        logger.error(f"ERROR Kn Function: {ex}")
        raise ex
