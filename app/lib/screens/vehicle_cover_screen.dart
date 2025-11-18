import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/vehicle_premium_service.dart';

class VehicleCoverScreen extends StatefulWidget {
  const VehicleCoverScreen({Key? key}) : super(key: key);

  @override
  State<VehicleCoverScreen> createState() => _VehicleCoverScreenState();
}

class _VehicleCoverScreenState extends State<VehicleCoverScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _makeController = TextEditingController();
  final _valueController = TextEditingController();
  final _repairsController = TextEditingController();

  int? _selectedYear;
  PremiumBreakdown? result;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      reverseDuration: const Duration(milliseconds: 300),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutQuint,
    ));

    _scaleAnim = Tween<double>(
      begin: 0.97,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _makeController.dispose();
    _valueController.dispose();
    _repairsController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final vehicleValue =
        double.parse(_valueController.text.replaceAll(',', '').trim());
    final repairCosts =
        double.parse(_repairsController.text.replaceAll(',', '').trim());

    final breakdown = estimatePremiumDetailed(
      vehicleValue: vehicleValue,
      make: _makeController.text.trim(),
      yearOfManufacture: _selectedYear!,
      totalRepairCostsLast3Years: repairCosts,
    );

    setState(() => result = breakdown);

    _animController.forward(from: 0); // animate reveal every time
  }

  @override
  Widget build(BuildContext context) {
    final yearOptions = generateYearOptions(spanYears: 25);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vehicle Insurance"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputCard(yearOptions),
            const SizedBox(height: 24),

            // Results animated
            if (result != null)
              FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: _buildResultCard(context, result!),
                  ),
                ),
              ),

            if (result != null) const SizedBox(height: 24),

            if (result != null) _buildActionsRow(),
          ],
        ),
      ),
    );
  }

  // FORM CARD
  Widget _buildInputCard(List<int> yearOptions) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                controller: _makeController,
                label: "Vehicle Make",
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _valueController,
                label: "Vehicle Value (KES)",
                number: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: "Year of Manufacture",
                ),
                value: _selectedYear,
                items: yearOptions
                    .map((y) => DropdownMenuItem(
                          value: y,
                          child: Text(y.toString()),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedYear = v),
                validator: (v) =>
                    v == null ? "Select year of manufacture" : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _repairsController,
                label: "Total Repair Costs (Last 3 Years)",
                number: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _calculate,
                  child: const Text("Calculate Premium"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool number = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: number ? TextInputType.number : null,
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return "Required";
        if (number) {
          final n = double.tryParse(v.replaceAll(',', '').trim());
          if (n == null || n < 0) return "Enter valid number";
        }
        return null;
      },
    );
  }

  // RESULTS CARD
  Widget _buildResultCard(BuildContext context, PremiumBreakdown b) {
    final theme = Theme.of(context);

    if (b.tpoFallback) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            "Vehicle only eligible for Third-Party Only.\n"
            "Estimated Premium: KES ${b.totalPremium.toStringAsFixed(0)}",
            style: theme.textTheme.titleMedium,
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Comprehensive Premium Breakdown",
                style: theme.textTheme.headlineMedium),
            const SizedBox(height: 12),

            _line("Category", vehicleCategoryToString(b.category)),
            _line("Base Premium", "KES ${b.basePremium.toStringAsFixed(0)}"),
            _line("Claims Loading",
                "KES ${b.claimsLoadingAmount.toStringAsFixed(0)}"),
            _line("Pre-Minimum Premium",
                "KES ${b.preMinimumPremium.toStringAsFixed(0)}"),

            if (b.isMinimumEnforced)
              _line("Minimum Premium Applied",
                  "KES ${b.minimumPremiumApplied.toStringAsFixed(0)}"),

            _line("Levies", "KES ${b.levies.toStringAsFixed(0)}"),
            const Divider(height: 30),
            _line("Total Annual Premium",
                "KES ${b.totalPremium.toStringAsFixed(0)}"),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ACTION BUTTONS
  Widget _buildActionsRow() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {},
            child: const Text("Contact an agent"),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () =>
                Navigator.pushNamed(context, "/asset_protection_home"),
            child: const Text("Next: Home"),
          ),
        ),
      ],
    );
  }
}
