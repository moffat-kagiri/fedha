"""
Data classification registry mapping models and fields to sensitivity and encryption rules.
"""

DATA_CLASSIFICATION = {
    'profile': {
        'name': {'sensitivity': 'CONFIDENTIAL', 'encrypt': True, 'pii_type': 'NAME'},
        'email': {'sensitivity': 'CONFIDENTIAL', 'encrypt': True, 'pii_type': 'EMAIL', 'searchable': True},
        'user_id': {'sensitivity': 'INTERNAL', 'encrypt': False, 'pii_type': 'IDENTIFIER'},
        'pin_hash': {'sensitivity': 'RESTRICTED', 'encrypt': False, 'pii_type': 'AUTH'},
    },
    'client': {
        'name': {'sensitivity': 'CONFIDENTIAL', 'encrypt': True, 'pii_type': 'NAME'},
        'email': {'sensitivity': 'CONFIDENTIAL', 'encrypt': True, 'pii_type': 'EMAIL', 'searchable': True},
        'phone': {'sensitivity': 'CONFIDENTIAL', 'encrypt': True, 'pii_type': 'PHONE'},
        'address_line1': {'sensitivity': 'CONFIDENTIAL', 'encrypt': True, 'pii_type': 'ADDRESS'},
        'tax_id': {'sensitivity': 'RESTRICTED', 'encrypt': True, 'pii_type': 'TAX_ID'},
    },
    'enhancedtransaction': {
        'reference_number': {'sensitivity': 'CONFIDENTIAL', 'encrypt': True},
        'receipt_url': {'sensitivity': 'CONFIDENTIAL', 'encrypt': True},
    },
    'loan': {
        'account_number': {'sensitivity': 'RESTRICTED', 'encrypt': True, 'pii_type': 'ACCOUNT_NUMBER'},
    },
    'auditlog': {
        'ip_address': {'sensitivity': 'CONFIDENTIAL', 'encrypt': True, 'hash_for_display': True},
        'user_agent': {'sensitivity': 'CONFIDENTIAL', 'encrypt': True, 'anonymize': True},
        'field_changes': {'sensitivity': 'RESTRICTED', 'encrypt': True},
    },
}
