import logging
from os import environ

# DAX
import amazondax
import boto3
import botocore.session

# logging config
logging.basicConfig(format='%(asctime)s %(levelname)-8s %(message)s', level=logging.DEBUG, datefmt='%Y-%m-%d %H:%M:%S')
logger = logging.getLogger(__name__)

# globals
MODULE = "dynamodb-helper"
PROFILE = "qa-admin"
REGION = "us-east-1"
DYNAMODB_TABLE = "productManuals"
INDEX = "pfamily-contenttype-index"
ENDPOINT = "mydaxcluster.lxh32w.clustercfg.dax.euw1.cache.amazonaws.com:8111"


def createClient(region):
    if environ.get('IS_RUNNING_LOCAL') is False:
        return boto3.client('dynamodb', region_name=region)
    else:
        logging.info('using profile {}'.format(PROFILE))
        session = boto3.Session(profile_name=PROFILE)
        return session.client('dynamodb', region_name=region)


def createDAXClient(region, endpoint):
    if environ.get('CODEBUILD_BUILD_ID') is not None:
        return amazondax.AmazonDaxClient(region_name=region, endpoints=[endpoint])
    else:
        logging.info('using profile {}'.format(PROFILE))
        session = botocore.session.Session(profile=PROFILE)
        return amazondax.AmazonDaxClient(session, region_name=region, endpoints=[endpoint])


def simplyDDBData(item):
    result = {}
    for mkey in item.keys():
        for key, value in item[mkey].items():
            result[mkey] = value
    return result


def getTable(client, table):
    results = {}
    items = []
    try:
        data = client.scan(TableName=table)
        if data is not None:
            for item in data['Items']:
                result = simplyDDBData(item)
                items.append(result)
        results['items'] = items
    except Exception as e:
        logging.error('error getting results from table:{} error:{}'.format(table, e))
        results['error'] = "scan error"
    return results


def queryIndex(client, table, index, pfamily):
    results = {}
    items = []
    try:
        data = client.query(TableName=table, IndexName=index, KeyConditionExpression='pfamily = :f',
                            ExpressionAttributeValues={":f": {"S": pfamily}})
        if data != None:
            for item in data['Items']:
                result = simplyDDBData(item)
                items.append(result)
        results['items'] = items
    except Exception as e:
        logging.error('error getting results from table:{} error:{}'.format(table, e))
        results['error'] = "query error"
    return results
