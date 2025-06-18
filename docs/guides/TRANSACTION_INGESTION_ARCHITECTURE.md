# Transaction Ingestion Pipeline - Architecture Overview

## **System Architecture Diagram**

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                          TRANSACTION INGESTION PIPELINE                         │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│   DATA SOURCES      │    │   PROCESSING LAYER  │    │   STORAGE LAYER     │
├─────────────────────┤    ├─────────────────────┤    ├─────────────────────┤
│                     │    │                     │    │                     │
│ 📱 SMS Messages     │───►│ 🤖 NLP Engine      │───►│ 💾 Transaction DB   │
│ 📧 Email Receipts   │    │ • Entity Extract.   │    │ • Validated Data    │
│ 💬 Chat Messages    │    │ • Amount Detection  │    │ • Categories        │
│                     │    │ • Date/Time Parse   │    │ • Goal Links        │
├─────────────────────┤    │ • Vendor Recognition│    ├─────────────────────┤
│                     │    │                     │    │                     │
│ 📊 Excel Files      │───►│ 📊 File Processor  │───►│ 🔄 Sync Queue      │
│ 📄 CSV Import       │    │ • Format Validation │    │ • Pending Changes   │
│ 💳 Bank Statements  │    │ • Data Cleaning     │    │ • Conflict Res.     │
│                     │    │ • Duplicate Check   │    │                     │
└─────────────────────┘    └─────────────────────┘    └─────────────────────┘
           │                          │                          │
           │                          │                          │
           ▼                          ▼                          ▼
┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│   USER INTERFACE    │    │   CONFIRMATION      │    │   INTEGRATION       │
├─────────────────────┤    ├─────────────────────┤    ├─────────────────────┤
│                     │    │                     │    │                     │
│ 📱 Mobile App       │◄───┤ ✅ User Approval    │───►│ 🎯 Goal Updates     │
│ • Transaction Forms │    │ • Edit/Correct      │    │ • Progress Tracking │
│ • Bulk Upload UI    │    │ • Category Selection│    │ • Auto-allocation   │
│ • Smart Suggestions │    │ • Duplicate Merge   │    │                     │
│                     │    │                     │    ├─────────────────────┤
├─────────────────────┤    ├─────────────────────┤    │                     │
│                     │    │                     │    │ 📊 Budget Updates   │
│ 🌐 Web Dashboard    │◄───┤ 📝 Batch Review     │───►│ • Expense Tracking  │
│ • Business Upload   │    │ • Error Correction  │    │ • Category Totals   │
│ • File Management   │    │ • Preview Results   │    │ • Alerts & Warnings │
│ • Progress Tracking │    │                     │    │                     │
└─────────────────────┘    └─────────────────────┘    └─────────────────────┘
```

## **Data Flow Sequence**

### **Text Message Processing Flow:**
```
1. SMS Received → 2. Permission Check → 3. Content Analysis → 4. NLP Processing
                                      ↓
8. Goal/Budget Update ← 7. Save Transaction ← 6. User Confirms ← 5. Extract Entities
```

### **Bulk Upload Processing Flow:**
```
1. File Selected → 2. Format Validation → 3. Chunk Processing → 4. Data Cleaning
                                      ↓
8. Batch Complete ← 7. Store Valid Rows ← 6. Review Errors ← 5. User Review
```

## **Component Details**

### **🤖 NLP Engine Components:**

#### **Entity Recognition Pipeline:**
```python
class TransactionNLPEngine:
    def __init__(self):
        self.amount_extractor = AmountExtractor()
        self.vendor_extractor = VendorExtractor()
        self.datetime_extractor = DateTimeExtractor()
        self.category_classifier = CategoryClassifier()
    
    def process_text(self, text: str) -> TransactionCandidate:
        # Extract monetary amounts
        amounts = self.amount_extractor.find_amounts(text)
        
        # Identify vendors/recipients
        vendors = self.vendor_extractor.find_entities(text)
        
        # Parse timestamps
        timestamps = self.datetime_extractor.extract_dates(text)
        
        # Classify transaction category
        category = self.category_classifier.predict(text)
        
        return TransactionCandidate(
            amount=amounts[0] if amounts else None,
            vendor=vendors[0] if vendors else None,
            timestamp=timestamps[0] if timestamps else None,
            category=category,
            confidence=self.calculate_confidence(),
            source_text=text
        )
```

#### **Pattern Recognition Examples:**
```python
TRANSACTION_PATTERNS = [
    # Bank transfers
    r"(?i)sent\s+\$?(\d+(?:\.\d{2})?)\s+to\s+(.+?)(?:\s|$)",
    
    # Payment confirmations
    r"(?i)paid\s+\$?(\d+(?:\.\d{2})?)\s+(?:to\s+)?(.+?)(?:\s+on\s+(.+?))?",
    
    # Purchase notifications
    r"(?i)purchased?\s+(.+?)\s+for\s+\$?(\d+(?:\.\d{2})?)",
    
    # Bill payments
    r"(?i)bill\s+payment\s+of\s+\$?(\d+(?:\.\d{2})?)\s+to\s+(.+?)",
    
    # ATM withdrawals
    r"(?i)withdrew\s+\$?(\d+(?:\.\d{2})?)\s+from\s+(.+?)\s+ATM",
]
```

### **📊 File Processing Components:**

#### **Excel/CSV Processor:**
```python
class BulkUploadProcessor:
    def __init__(self):
        self.supported_formats = ['.xlsx', '.xls', '.csv']
        self.column_mappers = {
            'amount': ['amount', 'total', 'value', 'sum'],
            'description': ['description', 'memo', 'notes', 'details'],
            'date': ['date', 'timestamp', 'when', 'transaction_date'],
            'category': ['category', 'type', 'class', 'group'],
            'vendor': ['vendor', 'merchant', 'payee', 'recipient']
        }
    
    def process_file(self, file_path: str, user_mapping: dict) -> UploadResult:
        # Detect file format and read data
        df = self.read_file(file_path)
        
        # Apply column mapping
        mapped_df = self.apply_mapping(df, user_mapping)
        
        # Validate and clean data
        validation_results = self.validate_transactions(mapped_df)
        
        # Return results with errors and warnings
        return UploadResult(
            valid_count=validation_results.valid_count,
            error_count=validation_results.error_count,
            warnings=validation_results.warnings,
            preview_data=validation_results.preview[:10]
        )
```

### **🔒 Privacy & Security Layer:**

#### **Permission Management:**
```dart
class PrivacyManager {
  static Future<bool> requestSMSPermission() async {
    // Show privacy explanation dialog
    bool userConsent = await showPrivacyDialog();
    if (!userConsent) return false;
    
    // Request system permission
    PermissionStatus status = await Permission.sms.request();
    
    if (status.isGranted) {
      // Store user preferences
      await storePrivacyPreferences();
      return true;
    }
    
    return false;
  }
  
  static Future<void> showPrivacyDialog() async {
    // Detailed explanation of data usage
    // Clear opt-out instructions
    // Data retention policies
  }
}
```

## **Implementation Phases**

### **Phase 1: Foundation (Week 1)**
- [ ] Set up NLP processing infrastructure
- [ ] Implement basic pattern recognition
- [ ] Create file upload endpoints
- [ ] Design privacy permission flows

### **Phase 2: Core Features (Week 2)**
- [ ] SMS monitoring and extraction
- [ ] Excel/CSV processing
- [ ] User confirmation interfaces
- [ ] Basic error handling

### **Phase 3: Enhancement (Week 3)**
- [ ] Advanced NLP with machine learning
- [ ] Smart categorization
- [ ] Duplicate detection
- [ ] Performance optimization

### **Phase 4: Integration (Week 4)**
- [ ] Goal and budget integration
- [ ] Transaction validation rules
- [ ] Batch processing improvements
- [ ] User feedback learning

---

## **Performance Considerations**

### **Scalability Metrics:**
- **Text Processing**: < 500ms per message
- **File Upload**: Support up to 10,000 transactions per file
- **Concurrent Users**: Handle 100+ simultaneous uploads
- **Accuracy Target**: 85%+ for common transaction patterns

### **Resource Requirements:**
- **Mobile**: < 50MB additional storage for NLP models
- **Server**: Redis for queue management, PostgreSQL for transactions
- **API Limits**: Rate limiting for bulk operations

---

*This architecture provides a comprehensive foundation for implementing intelligent transaction ingestion while maintaining user privacy and system performance.*
