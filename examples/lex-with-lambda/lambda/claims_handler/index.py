"""
Lambda function for handling insurance claim submissions.
Demonstrates Lex V2 fulfillment integration.
"""

import json
import uuid
from datetime import datetime


def handler(event, context):
    """
    Lex V2 fulfillment handler for filing insurance claims.
    
    Args:
        event: Lex V2 event containing session state and slots
        context: Lambda context
        
    Returns:
        Lex V2 response with fulfillment status
    """
    print(f"Received event: {json.dumps(event)}")
    
    # Extract intent and slots
    intent = event['sessionState']['intent']
    slots = intent['slots']
    
    # Get slot values
    policy_number = get_slot_value(slots, 'PolicyNumber')
    claim_type = get_slot_value(slots, 'ClaimType')
    incident_date = get_slot_value(slots, 'IncidentDate')
    
    # Process claim (this would typically call your backend API)
    claim_id = process_claim(policy_number, claim_type, incident_date)
    
    # Return success response
    return {
        "sessionState": {
            "dialogAction": {
                "type": "Close"
            },
            "intent": {
                "name": intent['name'],
                "state": "Fulfilled"
            }
        },
        "messages": [
            {
                "contentType": "PlainText",
                "content": f"Your {claim_type} claim has been submitted successfully. "
                          f"Claim ID: {claim_id}. We'll review it and contact you within 24 hours."
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


def process_claim(policy_number, claim_type, incident_date):
    """
    Process the insurance claim.
    In production, this would:
    - Validate policy number
    - Check policy coverage
    - Create claim in database
    - Trigger claim processing workflow
    
    For demo purposes, returns a mock claim ID.
    """
    claim_id = f"CLM-{uuid.uuid4().hex[:8].upper()}"
    
    print(f"Processing claim: {claim_id}")
    print(f"Policy: {policy_number}")
    print(f"Type: {claim_type}")
    print(f"Date: {incident_date}")
    
    # TODO: Add your business logic here
    # - Database insert
    # - API calls
    # - Workflow triggers
    
    return claim_id


# For local testing
if __name__ == "__main__":
    test_event = {
        "sessionState": {
            "intent": {
                "name": "FileClaimIntent",
                "slots": {
                    "PolicyNumber": {
                        "value": {
                            "interpretedValue": "POL123456"
                        }
                    },
                    "ClaimType": {
                        "value": {
                            "interpretedValue": "Accident"
                        }
                    },
                    "IncidentDate": {
                        "value": {
                            "interpretedValue": "2025-04-01"
                        }
                    }
                }
            }
        }
    }
    
    result = handler(test_event, None)
    print(json.dumps(result, indent=2))