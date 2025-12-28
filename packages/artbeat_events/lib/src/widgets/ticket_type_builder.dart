import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/ticket_type.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_input_decoration.dart';
import '../widgets/gradient_cta_button.dart';
import '../widgets/glass_chip.dart';

class TicketTypeBuilder extends StatefulWidget {
  final TicketType ticketType;
  final Function(TicketType) onChanged;
  final VoidCallback onRemove;

  const TicketTypeBuilder({
    super.key,
    required this.ticketType,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<TicketTypeBuilder> createState() => _TicketTypeBuilderState();
}

class _TicketTypeBuilderState extends State<TicketTypeBuilder> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;

  late TicketCategory _selectedCategory;

  List<String> _benefits = [];
  final TextEditingController _benefitController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.ticketType.name);
    _descriptionController = TextEditingController(
      text: widget.ticketType.description,
    );
    _priceController = TextEditingController(
      text: widget.ticketType.price.toString(),
    );
    _quantityController = TextEditingController(
      text: widget.ticketType.quantity.toString(),
    );

    _selectedCategory = widget.ticketType.category;
    _benefits = List.from(widget.ticketType.benefits);

    _nameController.addListener(_updateTicketType);
    _descriptionController.addListener(_updateTicketType);
    _priceController.addListener(_updateTicketType);
    _quantityController.addListener(_updateTicketType);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _benefitController.dispose();
    super.dispose();
  }

  void _updateTicketType() {
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final quantity = int.tryParse(_quantityController.text) ?? 0;

    final updated = widget.ticketType.copyWith(
      name: _nameController.text,
      description: _descriptionController.text,
      category: _selectedCategory,
      price: _selectedCategory == TicketCategory.free ? 0.0 : price,
      quantity: quantity,
      benefits: _benefits,
    );

    widget.onChanged(updated);
  }

  void _addBenefit(String benefit) {
    final clean = benefit.trim();
    if (clean.isEmpty || _benefits.contains(clean)) return;

    setState(() {
      _benefits.add(clean);
      _benefitController.clear();
    });

    _updateTicketType();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tr('tickets.section_title'),
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onRemove,
                tooltip: tr('tickets.remove'),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
            ],
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<TicketCategory>(
            initialValue: _selectedCategory,
            dropdownColor: Colors.black,
            decoration: glassInputDecoration(labelText: tr('tickets.category')),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedCategory = value;
                if (value == TicketCategory.free) {
                  _priceController.text = '0.0';
                }
              });
              _updateTicketType();
            },
            items: TicketCategory.values.map((c) {
              return DropdownMenuItem(
                value: c,
                child: Text(
                  c.displayName,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _nameController,
            decoration: glassInputDecoration(
              labelText: tr('tickets.name'),
              hintText: tr('tickets.name_hint'),
            ),
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: glassInputDecoration(
              labelText: tr('tickets.description'),
              hintText: tr('tickets.description_hint'),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  enabled: _selectedCategory != TicketCategory.free,
                  decoration: glassInputDecoration(
                    labelText: tr('tickets.price'),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  decoration: glassInputDecoration(
                    labelText: tr('tickets.quantity'),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (_selectedCategory == TicketCategory.vip ||
              _benefits.isNotEmpty) ...[
            Text(
              tr('tickets.benefits'),
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            Column(
              children: _benefits.asMap().entries.map((entry) {
                final index = entry.key;
                final benefit = entry.value;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            benefit,
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () {
                            setState(() => _benefits.removeAt(index));
                            _updateTicketType();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _benefitController,
                    decoration: glassInputDecoration(
                      hintText: tr('tickets.add_benefit'),
                      isDense: true,
                    ),
                    onFieldSubmitted: _addBenefit,
                  ),
                ),
                const SizedBox(width: 8),
                GradientCTAButton(
                  height: 44,
                  onPressed: () => _addBenefit(_benefitController.text),
                  text: tr('actions.add'),
                ),
              ],
            ),
          ],

          if (_selectedCategory == TicketCategory.vip) ...[
            const SizedBox(height: 12),
            Text(
              tr('tickets.quick_add'),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  [
                    'Early entry',
                    'Meet & greet with artist',
                    'Complimentary drinks',
                    'Exclusive merchandise',
                    'Private viewing area',
                    'Artist workshop access',
                  ].map((b) {
                    return GlassChip(
                      label: b,
                      onTap: () {
                        if (_benefits.contains(b)) return;
                        setState(() => _benefits.add(b));
                        _updateTicketType();
                      },
                    );
                  }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
