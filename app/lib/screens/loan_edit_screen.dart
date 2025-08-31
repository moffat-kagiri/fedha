import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../services/auth_service.dart';

class LoanEditScreen extends StatefulWidget {
  final Loan loan;

  const LoanEditScreen({
    Key? key,
    required this.loan,
  }) : super(key: key);

  @override
  State<LoanEditScreen> createState() => _LoanEditScreenState();
}

class _LoanEditScreenState extends State<LoanEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _principalController;
  late TextEditingController _interestController;
  late TextEditingController _termController;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.loan.name);
    _principalController = TextEditingController(
      text: (widget.loan.principalMinor / 100).toString(),
    );
    _interestController = TextEditingController(
      text: widget.loan.interestRate.toString(),
    );
    _startDate = widget.loan.startDate;
    _endDate = widget.loan.endDate;
    
    // Calculate term in months
    final months = _endDate.difference(_startDate).inDays ~/ 30;
    _termController = TextEditingController(text: months.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _principalController.dispose();
    _interestController.dispose();
    _termController.dispose();
    super.dispose();
  }

  Future<void> _updateLoan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final principal = double.parse(_principalController.text);
      final interestRate = double.parse(_interestController.text);
      final termMonths = int.parse(_termController.text);
      
      final endDate = _startDate.add(Duration(days: termMonths * 30));
      
      final db = Provider.of<AppDatabase>(context, listen: false);
      
      await (db.update(db.loans)..where((t) => t.id.equals(widget.loan.id))).write(
        LoansCompanion(
          name: Value(_nameController.text),
          principalMinor: Value((principal * 100).toInt()),
          interestRate: Value(interestRate),
          startDate: Value(_startDate),
          endDate: Value(endDate),
        ),
      );
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Loan updated successfully'),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating loan: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // Update end date based on term
        final termMonths = int.tryParse(_termController.text) ?? 0;
        _endDate = picked.add(Duration(days: termMonths * 30));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Loan'),
        backgroundColor: const Color(0xFF007A39),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Loan Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a loan name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _principalController,
                decoration: InputDecoration(
                  labelText: 'Principal Amount (${widget.loan.currency})',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the principal amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _interestController,
                decoration: const InputDecoration(
                  labelText: 'Annual Interest Rate (%)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the interest rate';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid rate';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _termController,
                      decoration: const InputDecoration(
                        labelText: 'Term (Months)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the loan term';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number of months';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        // Update end date when term changes
                        final months = int.tryParse(value) ?? 0;
                        setState(() {
                          _endDate = _startDate.add(Duration(days: months * 30));
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectStartDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                      const Icon(Icons.calendar_today, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'End Date (Calculated)',
                  border: OutlineInputBorder(),
                ),
                child: Text(DateFormat('MMM dd, yyyy').format(_endDate)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007A39),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isSaving ? null : _updateLoan,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Update Loan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
