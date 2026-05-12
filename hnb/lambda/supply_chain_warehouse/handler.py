import os
import sys

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.handler_logic import process_lambda

def lambda_handler(event, context):
    return process_lambda('supply_chain_warehouse', event)

