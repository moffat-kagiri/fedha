# SMS Listener Testing Guide

This guide describes how to test the SMS transaction capture feature in the Fedha app.

## Overview

The SMS Listener feature allows the app to automatically capture financial transaction details from SMS notifications sent by banks and mobile money services (like M-PESA). These transactions are presented to the user for review before being added to their financial records.

## Prerequisites

- Android device (iOS does not allow SMS interception)
- SMS permissions granted to the app
- Test SIM card with mobile money service active

## Testing Steps

### 1. Setup

1. Install the latest version of Fedha app
2. Complete the onboarding process and login
3. Navigate to Settings > SMS Permissions
4. Grant SMS read permissions when prompted
5. Toggle the "Listen for financial SMS" option to ON

### 2. Test with Real SMS

**Option A: Receive an actual financial SMS**
1. Perform a small financial transaction (e.g., send yourself money via M-PESA)
2. Wait to receive the transaction confirmation SMS
3. The app should detect this and show a notification
4. Open the app to review the captured transaction

**Option B: Simulate with test messages (requires developer access)**
1. Launch the app in debug mode
2. Open the SMS Transaction Testing screen
3. Click "Simulate M-PESA Transaction" to generate a test notification
4. Proceed to review the simulated transaction

### 3. Transaction Review Process

1. When a financial SMS is detected, you'll see a notification
2. Tap the notification or open the app
3. Navigate to the "Pending Transactions" section
4. Review the extracted transaction details:
   - Transaction type (payment, deposit, withdrawal)
   - Amount
   - Date and time
   - Sender/recipient
5. Verify that the extracted information matches the SMS
6. You can:
   - Approve: Add the transaction to your records
   - Edit: Modify details before adding
   - Reject: Discard the transaction

### 4. Testing Different SMS Types

Test the feature with various types of financial messages:
- M-PESA transactions (send, receive)
- Bank transfers
- Bank deposits
- ATM withdrawals
- Bill payments

### 5. Troubleshooting

If transactions are not being captured:

1. Check permissions:
   - Go to device Settings > Apps > Fedha > Permissions
   - Verify SMS permissions are granted

2. Check SMS format:
   - Some non-standard message formats may not be recognized
   - Report unrecognized formats to the development team

3. Test notification settings:
   - Ensure notifications are enabled for the app

4. Restart the app:
   - Sometimes restarting the app can resolve detection issues

## For Developers

### SMS Parsing Logic

The app uses pattern matching to extract information from SMS messages:

1. First identifies the sender (M-PESA, bank name)
2. Extracts transaction type using keywords (sent, received, withdrawal)
3. Finds amount figures with currency markers (KES, Ksh)
4. Extracts reference numbers and other metadata

To add new SMS patterns, modify `TransactionParser` in `sms_listener_service.dart`.

### Testing via Debug Mode

In debug mode, the app can simulate SMS messages to test the extraction logic without having to receive actual messages. Use `flutter run --debug` to enable this feature.

### Privacy Notice

The app processes SMS messages locally on the device. Message content is never sent to external servers. Only financial transactions from known senders (banks, mobile money services) are processed.
