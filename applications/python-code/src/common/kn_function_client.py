import requests
from common.logger import get_logger

logger = get_logger()

_NAMESPACE = "default"
_DOMAIN = "example"
_TIMEOUT = 7


def _get_kn_function_url(kn_function_name, namespace, domain):
    return f"http://{kn_function_name}.{namespace}.{domain}.com"


def invoke_kn_function(kn_function_name, data):
    try:
        with open('somefile2.txt', 'a') as the_file:
            the_file.write('invoke \n')
        url = _get_kn_function_url(
                kn_function_name=kn_function_name, 
                namespace=_NAMESPACE, 
                domain=_DOMAIN
            )
        result = requests.post(
                url=url, 
                data=data, 
                timeout=_TIMEOUT
            )
        with open('somefile2.txt', 'a') as the_file:
            the_file.write('invoke ' + result + '\n')


        logger.info(f"INVOKE Kn Function: {result.text}")
    except Exception as ex:
        with open('somefile3.txt', 'a') as the_file:
            the_file.write(f"ERROR Kn Function: {ex}\n")
        logger.error(f"ERROR Kn Function: {ex}")