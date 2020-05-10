import logging
import unittest

import requests
import requests.packages.urllib3

# logging config
logging.basicConfig(format='%(asctime)s %(levelname)-8s %(message)s', level=logging.WARNING,
                    datefmt='%Y-%m-%d %H:%M:%S')
requests.packages.urllib3.disable_warnings()

# API version under test
API_VERSION = "v0.1"
MODULE = "product-manual-test"
SERVER = "http://127.0.0.1:5000"


def validateResponseCode(self, apiResponse):
    try:
        self.assertEqual(apiResponse.status_code, 200)
        # logging.info('Response code is  200')
    except Exception as e:
        logging.error('Response code is not 200 {}'.format(apiResponse.status_code))
        exit(1)
    return


def validateResponseBody(self, apiResponse):
    if "items" in apiResponse.json():
        itemsFound = True
    else:
        itemsFound = False
    try:
        self.assertEqual(itemsFound, True)
    except Exception as e:
        logging.error('no matching items key in response error:{}'.format(e))
        exit(2)
    return


class ValidateProductGuidesService(unittest.TestCase):
    def test_get_product_manuals(self):
        logging.getLogger('get_product_manuals')
        test_url = (SERVER + '/api/' + API_VERSION + '/guides/productguides')
        print('testing {}'.format(test_url))
        headers = {'Content-Type': 'application/json', 'user-agent': MODULE}
        r = requests.get(test_url)
        validateResponseCode(self, r)
        validateResponseBody(self, r)


if __name__ == '__main__':
    unittest.main()
