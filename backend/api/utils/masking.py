"""Masking utilities for PII display and logs."""

def mask_email(email: str, visible_chars: int = 2) -> str:
    if not email or '@' not in email:
        return None
    local, domain = email.split('@', 1)
    if len(local) <= visible_chars:
        masked_local = '*' * len(local)
    else:
        masked_local = local[:visible_chars] + '*' * (len(local) - visible_chars)
    return f"{masked_local}@{domain}"


def mask_phone(phone: str, visible_digits: int = 4) -> str:
    if not phone:
        return None
    digits = ''.join(c for c in phone if c.isdigit())
    if len(digits) <= visible_digits:
        return '*' * len(digits)
    return '*' * (len(digits) - visible_digits) + digits[-visible_digits:]


def mask_name(name: str, visible_chars: int = 1) -> str:
    if not name:
        return None
    parts = name.split()
    masked = []
    for part in parts:
        if len(part) <= visible_chars:
            masked.append('*' * len(part))
        else:
            masked.append(part[:visible_chars] + '*' * (len(part) - visible_chars))
    return ' '.join(masked)


def mask_account_number(account: str, visible_digits: int = 4) -> str:
    if not account:
        return None
    if len(account) <= visible_digits:
        return '*' * len(account)
    return '*' * (len(account) - visible_digits) + account[-visible_digits:]
