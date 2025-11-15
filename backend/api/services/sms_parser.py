"""
SMS Transaction Parser Service
Provides rule-based parsing strategies with sender identification and bank-specific patterns.
"""

import re
from typing import Dict, Any, Optional
from decimal import Decimal
import logging

logger = logging.getLogger(__name__)


class RuleBasedSMSParser:
    """Rule-based SMS parser for transaction extraction."""
    
    # Sender/bank identification patterns (checked first)
    SENDER_PATTERNS = {
        'mpesa': r'(SAFARICOM|M-PESA|MPESA|TK\w{8}|TJV\w{6}|TKD\w{6})',
        'equity': r'(EQUITY|EQBNK)',
        'kcb': r'(KCB|KCBKENYA)',
        'coop': r'(CO-OP|COOP)',
        'airtel': r'(AIRTEL|AIRTELMON)',
        'stanbic': r'(STANBIC)',
        'absa': r'(ABSA|ABSAKENYA)',
        'diamond': r'(DIAMOND|DIAMONDBANK)',
        'I&M': r'(I&M|IM-BANK)',
    }
    
    # Bank-specific transaction patterns (matched after sender identified)
    BANK_PATTERNS = {
        'mpesa': {
            'withdrawal': r'Confirmed\.\s+You have withdrawn Ksh([\d,]+\.?\d*)',
            'deposit': r'You have received Ksh([\d,]+\.?\d*) from',
            # Fuliza repayment - special tracking
            'fuliza_recovery': r'Ksh ([\d,]+\.?\d*) from your M-PESA has been used to (?:partially |)pay your outstanding Fuliza',
            # Payment to till/merchant (includes transaction cost in separate field)
            'payment_till': r'Confirmed\. Ksh([\d,]+\.?\d*) paid to',
            # Paybill payment (includes transaction cost in separate field)
            'payment_paybill': r'Confirmed\. Ksh([\d,]+\.?\d*) sent to (?!.+M-PESA user)',
            # Airtime purchase
            'airtime': r'(?:confirmed|Confirmed)\. You bought Ksh([\d,]+\.?\d*) of airtime',
            # Transfer to another M-PESA user
            'transfer': r'Confirmed\. Ksh([\d,]+\.?\d*) sent to [A-Z\s]+ on',
        },
        'equity': {
            'deposit': r'Deposit of KES ([\d,]+\.?\d*)',
            'withdrawal': r'Withdrawal of KES ([\d,]+\.?\d*)',
            'credit': r'credited with KES ([\d,]+\.?\d*)',
            'debit': r'debited with KES ([\d,]+\.?\d*)',
        },
        'kcb': {
            'deposit': r'Deposit of KES ([\d,]+\.?\d*)',
            'withdrawal': r'Withdrawal of KES ([\d,]+\.?\d*)',
            'credit': r'credited with KES ([\d,]+\.?\d*)',
            'debit': r'debited with KES ([\d,]+\.?\d*)',
        },
        'coop': {
            'deposit': r'You have received KES ([\d,]+\.?\d*)',
            'withdrawal': r'You have sent KES ([\d,]+\.?\d*)',
            'credit': r'credited with KES ([\d,]+\.?\d*)',
            'debit': r'debited with KES ([\d,]+\.?\d*)',
        },
        'stanbic': {
            'deposit': r'successfully transferred KES ([\d,]+\.?\d*) from your MPESA',
            'transfer_mpesa': r'successfully transferred KES ([\d,]+\.?\d*) to MPESA',
            'transfer': r'successfully transferred KES ([\d,]+\.?\d*)',
            'debit': r'has been DEBITED with KES ([\d,]+\.?\d*)',
            'credit': r'credited with KES ([\d,]+\.?\d*)',
        },
        'airtel': {
            'withdrawal': r'Withdrawal of KES ([\d,]+\.?\d*)',
            'deposit': r'Deposit of KES ([\d,]+\.?\d*)',
            'credit': r'credited with KES ([\d,]+\.?\d*)',
            'debit': r'debited with KES ([\d,]+\.?\d*)',
        },
        'absa': {
            'deposit': r'Deposit of KES ([\d,]+\.?\d*)',
            'withdrawal': r'Withdrawal of KES ([\d,]+\.?\d*)',
            'credit': r'credited with KES ([\d,]+\.?\d*)',
            'debit': r'debited with KES ([\d,]+\.?\d*)',
        },
        'diamond': {
            'deposit': r'Deposit of KES ([\d,]+\.?\d*)',
            'withdrawal': r'Withdrawal of KES ([\d,]+\.?\d*)',
            'credit': r'credited with KES ([\d,]+\.?\d*)',
            'debit': r'debited with KES ([\d,]+\.?\d*)',
        },
        'I&M': {
            'deposit': r'Deposit of KES ([\d,]+\.?\d*)',
            'withdrawal': r'Withdrawal of KES ([\d,]+\.?\d*)',
            'credit': r'credited with KES ([\d,]+\.?\d*)',
            'debit': r'debited with KES ([\d,]+\.?\d*)',
        },
    }
    
    # Transaction type mappings
    TRANSACTION_TYPES = {
        'withdrawal': ('expense', 'Withdrawal'),
        'transfer': ('expense', 'Transfer'),
        'transfer_mpesa': ('expense', 'Transfer to M-PESA'),
        'debit': ('expense', 'Debit'),
        'payment': ('expense', 'Payment'),
        'payment_till': ('expense', 'Payment to Merchant'),
        'payment_paybill': ('expense', 'Paybill Payment'),
        'airtime': ('expense', 'Airtime Purchase'),
        'deposit': ('income', 'Deposit'),
        'credit': ('income', 'Credit'),
        'fuliza_recovery': ('expense', 'Fuliza Repayment'),
    }
    
    # Confidence scores by bank
    BANK_CONFIDENCE = {
        'mpesa': 0.90,
        'equity': 0.80,
        'kcb': 0.80,
        'coop': 0.80,
        'stanbic': 0.80,
        'airtel': 0.75,
        'absa': 0.75,
        'diamond': 0.75,
        'I&M': 0.75,
    }
    
    @staticmethod
    def _identify_sender(sms_text: str) -> Optional[str]:
        """Identify which bank/sender sent the SMS."""
        for bank, pattern in RuleBasedSMSParser.SENDER_PATTERNS.items():
            if re.search(pattern, sms_text, re.IGNORECASE):
                return bank
        return None
    
    @staticmethod
    def _extract_mpesa_metadata(sms_text: str) -> Dict[str, Any]:
        """Extract M-PESA specific metadata: balance, transaction cost, daily limit, Fuliza limit."""
        metadata = {}
        
        # Extract M-PESA balance
        balance_match = re.search(r'New M-PESA balance is Ksh([\d,]+\.?\d*)', sms_text)
        if balance_match:
            metadata['mpesa_balance'] = float(balance_match.group(1).replace(',', ''))
        
        # Extract transaction cost
        cost_match = re.search(r'Transaction cost[,:]?\s*Ksh([\d,]+\.?\d*)', sms_text)
        if cost_match:
            metadata['transaction_cost'] = float(cost_match.group(1).replace(',', ''))
        
        # Extract daily transaction limit
        limit_match = re.search(r'Amount you can transact within the day is ([\d,]+\.?\d*)', sms_text)
        if limit_match:
            metadata['daily_limit'] = float(limit_match.group(1).replace(',', ''))
        
        # Extract Fuliza limit
        fuliza_match = re.search(r'Your available Fuliza[^\d]*([\d,]+\.?\d*)', sms_text)
        if fuliza_match:
            metadata['fuliza_limit'] = float(fuliza_match.group(1).replace(',', ''))
        
        return metadata
    
    @staticmethod
    def _extract_transaction_date(sms_text: str) -> Optional[str]:
        """Extract transaction date and time from SMS."""
        # Matches format like "on 13/11/25 at 5:01 PM" or "on 4/11/25 at 9:08 PM"
        date_match = re.search(r'on (\d{1,2}/\d{1,2}/\d{2,4})', sms_text)
        if date_match:
            return date_match.group(1)
        
        # Simple date only format DD/MM/YY
        simple_date = re.search(r'(\d{1,2}/\d{1,2}/\d{2,4})', sms_text)
        if simple_date:
            return simple_date.group(1)
        
        return None
    
    @staticmethod
    def _extract_reference(sms_text: str) -> Optional[str]:
        """Extract transaction reference/code from SMS."""
        # M-PESA transaction code (e.g., TK40Q9C6ER, TKD6MA2HOC)
        mpesa_ref = re.search(r'(T[A-Z0-9]{8})', sms_text)
        if mpesa_ref:
            return mpesa_ref.group(1)
        
        # Generic Ref format
        generic_ref = re.search(r'Ref[:\s]*([A-Za-z0-9\-]+)', sms_text)
        if generic_ref:
            return generic_ref.group(1)
        
        # RefID format
        ref_id = re.search(r'RefID[:\s]*([A-Za-z0-9\-]+)', sms_text)
        if ref_id:
            return ref_id.group(1)
        
        return None
    
    @staticmethod
    def _calculate_total_amount_mpesa(transaction_type: str, base_amount: float, metadata: Dict[str, Any]) -> float:
        """
        For M-PESA outgoing transactions, calculate total as base_amount + transaction_cost.
        For incoming transactions, return base_amount as-is.
        """
        # Income transactions - return as is
        if transaction_type in ('deposit', 'fuliza_recovery'):
            return base_amount
        
        # For outgoing transactions, add transaction cost if available
        if 'transaction_cost' in metadata:
            total = base_amount + metadata['transaction_cost']
            return total
        
        return base_amount
    
    @staticmethod
    def parse(sms_text: str, profile_id: str) -> Dict[str, Any]:
        """Parse SMS using sender-aware, bank-specific patterns."""
        # Step 1: Identify the sender/bank
        sender = RuleBasedSMSParser._identify_sender(sms_text)
        if not sender:
            return {
                'success': False,
                'method': 'rule_based',
                'error': 'Unable to identify sender',
                'raw_sms': sms_text,
            }
        
        # Step 2: Extract M-PESA metadata if applicable
        mpesa_metadata = {} if sender == 'mpesa' else {}
        if sender == 'mpesa':
            mpesa_metadata = RuleBasedSMSParser._extract_mpesa_metadata(sms_text)
        
        # Step 3: Try to match transaction patterns for this bank
        bank_patterns = RuleBasedSMSParser.BANK_PATTERNS.get(sender, {})
        for transaction_type, pattern in bank_patterns.items():
            match = re.search(pattern, sms_text, re.IGNORECASE)
            if match:
                try:
                    amount_str = match.group(1).replace(',', '')
                    amount = Decimal(amount_str)
                    
                    # Get transaction type mapping
                    trans_type, description_label = RuleBasedSMSParser.TRANSACTION_TYPES.get(
                        transaction_type, ('unknown', transaction_type)
                    )
                    
                    # For M-PESA outgoing transactions, add transaction cost to base amount
                    if sender == 'mpesa' and transaction_type in ('payment_till', 'payment_paybill', 'transfer', 'airtime'):
                        final_amount = RuleBasedSMSParser._calculate_total_amount_mpesa(
                            transaction_type, float(amount), mpesa_metadata
                        )
                    else:
                        final_amount = float(amount)
                    
                    # Extract optional metadata
                    reference = RuleBasedSMSParser._extract_reference(sms_text)
                    date = RuleBasedSMSParser._extract_transaction_date(sms_text)
                    
                    # Balance extraction
                    balance = None
                    bal_match = re.search(r'Balance[:\s]*(?:Ksh|KES)\s?([\d,]+\.?\d*)', sms_text)
                    if bal_match:
                        balance = float(bal_match.group(1).replace(',', ''))
                    elif 'mpesa_balance' in mpesa_metadata:
                        balance = mpesa_metadata['mpesa_balance']
                    
                    result = {
                        'success': True,
                        'method': 'rule_based',
                        'sender': sender,
                        'transaction_type': transaction_type,
                        'amount': final_amount,
                        'description': f'{sender.upper()} {description_label}',
                        'type': trans_type,
                        'confidence': RuleBasedSMSParser.BANK_CONFIDENCE.get(sender, 0.70),
                        'reference': reference,
                        'date': date,
                        'balance': balance,
                        'raw_sms': sms_text,
                    }
                    
                    # Add M-PESA specific metadata
                    if sender == 'mpesa':
                        if 'transaction_cost' in mpesa_metadata:
                            result['transaction_cost'] = mpesa_metadata['transaction_cost']
                        if 'daily_limit' in mpesa_metadata:
                            result['daily_limit'] = mpesa_metadata['daily_limit']
                        if 'fuliza_limit' in mpesa_metadata:
                            result['fuliza_limit'] = mpesa_metadata['fuliza_limit']
                    
                    return result
                    
                except (ValueError, IndexError) as e:
                    logger.warning(f"Failed to parse {sender} {transaction_type}: {str(e)}")
                    continue
        
        # No transaction pattern matched for this sender
        # --- Generalized fallback for all banks ---
        fallback_patterns = [
            # Expense keywords
            (r'(sent|withdrawn|debited)[^\d]*([\d,]+\.?\d*)', 'expense'),
            # Income keywords
            (r'(received|credited|deposited)[^\d]*([\d,]+\.?\d*)', 'income'),
        ]
        for pattern, trans_type in fallback_patterns:
            match = re.search(pattern, sms_text, re.IGNORECASE)
            if match:
                try:
                    amount_str = match.group(2).replace(',', '')
                    amount = float(amount_str)
                    description = f"{sender.upper()} {match.group(1).capitalize()}"
                    reference = RuleBasedSMSParser._extract_reference(sms_text)
                    date = RuleBasedSMSParser._extract_transaction_date(sms_text)
                    balance = None
                    bal_match = re.search(r'Balance[:\s]*(?:Ksh|KES)\s?([\d,]+\.?\d*)', sms_text)
                    if bal_match:
                        balance = float(bal_match.group(1).replace(',', ''))
                    return {
                        'success': True,
                        'method': 'rule_based',
                        'sender': sender,
                        'transaction_type': match.group(1).lower(),
                        'amount': amount,
                        'description': description,
                        'type': trans_type,
                        'confidence': 0.65,
                        'reference': reference,
                        'date': date,
                        'balance': balance,
                        'raw_sms': sms_text,
                    }
                except Exception as e:
                    logger.warning(f"Generalized fallback failed: {str(e)}")
                    continue
        # --- End fallback ---
        return {
            'success': False,
            'method': 'rule_based',
            'sender': sender,
            'error': f'No transaction pattern matched for {sender}',
            'raw_sms': sms_text,
        }


class TransactionCandidateFactory:
    """Factory for creating transaction candidates from parsed SMS."""
    
    @staticmethod
    def from_parsed_sms(parsed_data: Dict[str, Any], profile_id: str) -> Dict[str, Any]:
        """
        Convert parsed SMS data to transaction candidate.
        
        Args:
            parsed_data: Output from parse()
            profile_id: Profile UUID
        
        Returns:
            Transaction candidate dict ready for review/approval
        """
        
        if not parsed_data.get('success'):
            return {'error': parsed_data.get('errors', ['Unknown error'])}
        
        candidate = {
            'profile_id': profile_id,
            'raw_sms': parsed_data.get('raw_sms', ''),
            'amount': parsed_data.get('amount'),
            'description': parsed_data.get('description'),
            'type': parsed_data.get('type'),
            'confidence': parsed_data.get('confidence', 0.0),
            'sender': parsed_data.get('sender'),
            'transaction_type': parsed_data.get('transaction_type'),
            'reference': parsed_data.get('reference'),
            'date': parsed_data.get('date'),
            'balance': parsed_data.get('balance'),
            'status': 'pending_review',
        }
        
        # Add M-PESA specific fields if present
        if 'transaction_cost' in parsed_data:
            candidate['transaction_cost'] = parsed_data['transaction_cost']
        if 'daily_limit' in parsed_data:
            candidate['daily_limit'] = parsed_data['daily_limit']
        if 'fuliza_limit' in parsed_data:
            candidate['fuliza_limit'] = parsed_data['fuliza_limit']
            # If this is a Fuliza recovery transaction, mark it for reconciliation
            if parsed_data.get('transaction_type') == 'fuliza_recovery':
                candidate['reconciliation_flag'] = 'fuliza_repayment'
        
        return candidate
