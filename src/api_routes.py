from src import app

import json
import logging
import timeit

from flask import Response, request

import src.helpers.dynamoDBHelper as db
# logging config

logging.basicConfig(format='%(asctime)s %(levelname)-8s %(message)s', level=logging.DEBUG, datefmt='%Y-%m-%d %H:%M:%S')
logger = logging.getLogger(__name__)

# globals
MODULE = "health-db"
CURRENT_VERSION = "v0.1"
PROFILE = "qa-admin"
REGION = "us-east-1"
TABLE_MAPPER = {"productguides": "productManuals"}
CONTENT_MAPPER = {"product": "pfamily-contenttype-index"}
DEFAULT_TABLE = "productManuals"

# initialize flask
ddb = db.createClient(REGION)


@app.route('/api/<string:version>/health', methods=['GET'])
def health(version):
    if version == CURRENT_VERSION:
        status = 200
        response = {"health": "ok", "response": "ok"}
    else:
        status = 400
        response = {"error": "invalid API version", "response": "ok"}
    return Response(json.dumps(response), status=status, mimetype='application/json')


@app.route('/api/<string:version>/guides/<string:mtype>', methods=["GET"])
def getProductGuides(version, mtype):
    """get a list of product manuals and their S3 location"""
    if mtype in TABLE_MAPPER:
        start = timeit.timeit()
        HTTPResponse = db.getTable(ddb, TABLE_MAPPER[mtype])
        stop = timeit.timeit()
        HTTPResponse['timing'] = stop - start
        if 'error' not in HTTPResponse:
            status = 200
            HTTPResponse['request'] = 'ok'
        else:
            status = 500
            HTTPResponse['request'] = 'fail'
    else:
        status = 404
        HTTPResponse = {"error": "invalid resource", "request": "fail"}
    return Response(json.dumps(HTTPResponse), status=status, mimetype='application/json')


@app.route('/api/<string:version>/content/guides/<string:ctype>', methods=["GET"])
def getFamilyContent(version, ctype):
    """get a list of content types for a product family"""
    try:
        family = request.args.get('product-family')
        if ctype in CONTENT_MAPPER:
            start = timeit.timeit()
            HTTPResponse = db.queryIndex(ddb, DEFAULT_TABLE, CONTENT_MAPPER[ctype], family)
            stop = timeit.timeit()
            HTTPResponse['timing'] = stop - start
            if 'error' not in HTTPResponse:
                status = 200
                HTTPResponse['request'] = 'ok'
            else:
                status = 500
                HTTPResponse['request'] = 'fail'
        else:
            status = 404
            HTTPResponse = {"error": "invalid resource", "request": "fail"}
    except Exception as e:
        status = 400
        HTTPResponse = {"error": "invalid query string", "request": "fail"}
    return Response(json.dumps(HTTPResponse), status=status, mimetype='application/json')
