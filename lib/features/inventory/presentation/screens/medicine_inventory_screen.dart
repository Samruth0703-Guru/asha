import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class MedicineInventoryScreen extends StatefulWidget {
  const MedicineInventoryScreen({super.key});

  @override
  State<MedicineInventoryScreen> createState() => _MedicineInventoryScreenState();
}

class _MedicineInventoryScreenState extends State<MedicineInventoryScreen> {
  final List<_MockMedicine> _medicines = [];

  String _searchQuery = "";

  void _issueMedicineDialog(String medId, String medName, int currentStock) {
    final patientController = TextEditingController();
    final qtyController = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Issue $medName', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: patientController,
              decoration: const InputDecoration(
                labelText: 'Select Patient',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity to Issue',
                prefixIcon: Icon(Icons.unfold_more_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              int qty = int.tryParse(qtyController.text) ?? 0;
              if (qty > currentStock) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: Not enough stock available!'),
                    backgroundColor: AppTheme.dangerColor,
                  ),
                );
                return;
              }
              setState(() {
                final index = _medicines.indexWhere((m) => m.id == medId);
                if (index != -1) {
                  _medicines[index] = _medicines[index].copyWith(stock: currentStock - qty);
                }
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Issued $qty units of $medName to ${patientController.text}'),
                  backgroundColor: AppTheme.secondaryColor,
                ),
              );
            },
            child: const Text('Issue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredMedicines = _medicines
        .where((m) => m.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Medicine Inventory', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search & Filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search stock register...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? const Color(0xff1e293b) : Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),

          // Inventory List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredMedicines.length,
              itemBuilder: (ctx, idx) {
                final med = filteredMedicines[idx];
                final isLowStock = med.stock < med.threshold;
                final isAboutToExpire = med.expiry.isBefore(DateTime.now().add(const Duration(days: 120)));

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                med.name,
                                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (isLowStock)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.dangerColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'LOW STOCK',
                                  style: TextStyle(color: AppTheme.dangerColor, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Stock Count:', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
                            Text(
                              '${med.stock} Units',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isLowStock ? AppTheme.dangerColor : AppTheme.secondaryColor,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Expiry Date:', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
                            Text(
                              '${med.expiry.year}-${med.expiry.month.toString().padLeft(2, '0')}-${med.expiry.day.toString().padLeft(2, '0')}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isAboutToExpire ? AppTheme.warningColor : Colors.grey,
                                fontWeight: isAboutToExpire ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _issueMedicineDialog(med.id, med.name, med.stock),
                              icon: const Icon(Icons.outbox_rounded, size: 16),
                              label: const Text('Issue Stock'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                minimumSize: const Size(120, 36),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MockMedicine {
  final String id;
  final String name;
  final int stock;
  final int threshold;
  final DateTime expiry;

  _MockMedicine({required this.id, required this.name, required this.stock, required this.threshold, required this.expiry});

  _MockMedicine copyWith({int? stock}) {
    return _MockMedicine(
      id: id,
      name: name,
      stock: stock ?? this.stock,
      threshold: threshold,
      expiry: expiry,
    );
  }
}
