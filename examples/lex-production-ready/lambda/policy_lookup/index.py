"""
Lambda function for looking up policy details.
"""

import json


def handler(event, context):
    """Lex V2 fulfillment handler for policy lookup."""
    print(f"Received event: {json.dumps(event)}")
    
    intent = event['sessionState']['intent']
    slots = intent['slots']
    
    policy_number = get_slot_value(slots, 'PolicyNumber')
    
    # Look up policy (mock data)
    policy_info = get_policy_info(policy_number)
    
    if policy_info:
        message = (
            f"Policy {policy_number} is active. "
            f"Type: {policy_info['type']}. "
            f"Coverage: ${policy_info['coverage']:,}. "
            f"Premium: ${policy_info['premium']}/month."
        )
    else:
        message = f"Sorry, I couldn't find policy {policy_number}. Please check the number and try again."
    
    return {
        "sessionState": {
            "dialogAction": {
                "type": "Close"
            },
            "intent": {
                "name": intent['name'],
                "state": "Fulfilled" if policy_info else "Failed"
            }
        },
        "messages": [
            {
                "contentType": "PlainText",
                "content": message
            }
        ]
    }


def get_slot_value(slots, slot_name):
    """Extract interpreted value from a slot."""
    if slot_name in slots and slots[slot_name]:
        slot = slots[slot_name]
        if 'value' in slot and 'interpretedValue' in slot['value']:
            return slot['value']['interpretedValue']
    return None


def get_policy_info(policy_number):
    """
    Look up policy information.
    In production, this would query your database/API.
    """
    # Mock data
    policies = {
        "POL123456": {
            "type": "Auto Insurance",
            "coverage": 50000,
            "premium": 125
        },
        "POL789012": {
            "type": "Home Insurance",
            "coverage": 250000,
            "premium": 95
        }
    }
    
    return policies.get(policy_number)