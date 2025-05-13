def test_full_flow():
    # 1. Create Profile
    profile_id = create_profile(is_business=True, pin="1234")
    
    # 2. Add Transaction Offline (Flutter)
    add_transaction(profile_id, amount=1000, type="income")
    
    # 3. Sync Data
    sync_response = sync_data(profile_id)
    
    # 4. Verify Backend Received Data
    transactions = get_transactions(profile_id)
    assert len(transactions) == 1
    assert transactions[0]["amount"] == 1000
    
    # 5. Calculate Loan via API
    repayment = calculate_repayment(
        principal=10000,
        interest_rate=5,
        frequency="monthly"
    )
    assert repayment ≈ 188.71  # Validate calculation precision