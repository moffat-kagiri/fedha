---
# Fedha Development Roadmap

A phased agile checklist for tracking progress.
---
## **Phase 0: Setup & Planning**

- [ ] Finalize tech stack (Flutter, React, Django, PostgreSQL)
- [ ] Set up Git repository and branching strategy
- [ ] Design database schema (Transactions, Loans, Profiles)

---

## **Phase 1: Core Features (Sprint 1-2)**

### **Profile System**

- [ ] UUID generator for business/personal profiles
- [ ] PIN-based authentication (no personal data)
- [ ] Hive local storage setup (Flutter)

### **Transaction Tracking**

- [ ] Add/Edit/Delete income and expenses
- [ ] Categorize transactions (e.g., "Marketing", "Utilities")

---

## **Phase 2: Financial Calculators (Sprint 3)**

### **Loan Calculator**

- [ ] Simple interest repayment schedule
- [ ] Reducing balance calculator
- [ ] Interest rate solver (Newton-Raphson implementation)

### **Investment Tracking**

- [ ] ROI calculator
- [ ] Goal progress visualization

---

## **Phase 3: Sync & API (Sprint 4)**

- [ ] Django REST API for data sync
- [ ] Offline-first strategy with conflict resolution
- [ ] Secure JWT token authentication

---

## **Phase 4: UI/UX (Sprint 5)**

- [ ] Dashboard with cash flow charts
- [ ] Responsive web design (React + Chakra UI)
- [ ] Dark/light mode toggle

---

## **Phase 5: Testing & Launch (Sprint 6)**

- [ ] Cross-platform testing (Android, Web)
- [ ] Security audit (encryption, penetration testing)
- [ ] Deploy web to Vercel/Netlify
- [ ] Publish Android app to Google Play
