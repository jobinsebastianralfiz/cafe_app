import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/models/user_model.dart';
import '../../viewmodels/address_viewmodel.dart';

/// Screen to add or edit an address
class AddEditAddressScreen extends ConsumerStatefulWidget {
  final AddressModel? address; // null for add, non-null for edit

  const AddEditAddressScreen({
    super.key,
    this.address,
  });

  @override
  ConsumerState<AddEditAddressScreen> createState() =>
      _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _addressLine1Controller;
  late TextEditingController _addressLine2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _landmarkController;

  String _selectedLabel = 'Home';
  bool _isDefault = false;
  bool _isLoading = false;

  final List<String> _addressLabels = ['Home', 'Work', 'Hotel', 'Other'];

  @override
  void initState() {
    super.initState();
    _addressLine1Controller =
        TextEditingController(text: widget.address?.addressLine1 ?? '');
    _addressLine2Controller =
        TextEditingController(text: widget.address?.addressLine2 ?? '');
    _cityController = TextEditingController(text: widget.address?.city ?? '');
    _stateController = TextEditingController(text: widget.address?.state ?? '');
    _pincodeController =
        TextEditingController(text: widget.address?.pincode ?? '');
    _landmarkController =
        TextEditingController(text: widget.address?.landmark ?? '');

    if (widget.address != null) {
      _selectedLabel = widget.address!.label;
      _isDefault = widget.address!.isDefault;
    }
  }

  @override
  void dispose() {
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.address == null) {
        // Add new address
        await ref.read(addressViewModelProvider.notifier).addAddress(
              label: _selectedLabel,
              addressLine1: _addressLine1Controller.text.trim(),
              addressLine2: _addressLine2Controller.text.trim().isEmpty
                  ? null
                  : _addressLine2Controller.text.trim(),
              city: _cityController.text.trim(),
              addressState: _stateController.text.trim(),
              pincode: _pincodeController.text.trim(),
              landmark: _landmarkController.text.trim().isEmpty
                  ? null
                  : _landmarkController.text.trim(),
              isDefault: _isDefault,
            );
      } else {
        // Update existing address
        final updatedAddress = widget.address!.copyWith(
          label: _selectedLabel,
          addressLine1: _addressLine1Controller.text.trim(),
          addressLine2: _addressLine2Controller.text.trim().isEmpty
              ? null
              : _addressLine2Controller.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          pincode: _pincodeController.text.trim(),
          landmark: _landmarkController.text.trim().isEmpty
              ? null
              : _landmarkController.text.trim(),
          isDefault: _isDefault,
        );

        await ref
            .read(addressViewModelProvider.notifier)
            .updateAddress(updatedAddress);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.address == null
                ? 'Address added successfully'
                : 'Address updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.address != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Address' : 'Add New Address'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Address Label Selection
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Save Address As',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: _addressLabels.map((label) {
                        final isSelected = _selectedLabel == label;
                        return ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedLabel = label);
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Address Form
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Address Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Address Line 1
                    TextFormField(
                      controller: _addressLine1Controller,
                      decoration: InputDecoration(
                        labelText: 'Flat / House No. / Building *',
                        hintText: 'Enter house/flat number',
                        prefixIcon: const Icon(Icons.home_outlined),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter house/flat number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Address Line 2
                    TextFormField(
                      controller: _addressLine2Controller,
                      decoration: InputDecoration(
                        labelText: 'Area / Street / Sector',
                        hintText: 'Enter area or street',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Landmark
                    TextFormField(
                      controller: _landmarkController,
                      decoration: InputDecoration(
                        labelText: 'Landmark',
                        hintText: 'E.g. Near City Mall',
                        prefixIcon: const Icon(Icons.location_searching),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // City and State
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: InputDecoration(
                              labelText: 'City *',
                              hintText: 'Enter city',
                              prefixIcon: const Icon(Icons.location_city),
                              filled: true,
                              fillColor: AppColors.surfaceVariant,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _stateController,
                            decoration: InputDecoration(
                              labelText: 'State *',
                              hintText: 'Enter state',
                              prefixIcon: const Icon(Icons.map),
                              filled: true,
                              fillColor: AppColors.surfaceVariant,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Pincode
                    TextFormField(
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: 'Pincode *',
                        hintText: 'Enter 6-digit pincode',
                        prefixIcon: const Icon(Icons.pin_drop),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter pincode';
                        }
                        if (value.trim().length != 6) {
                          return 'Pincode must be 6 digits';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Default Address Toggle
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: SwitchListTile(
                  title: const Text(
                    'Set as default address',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'This address will be used for deliveries by default',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _isDefault,
                  onChanged: (value) {
                    setState(() => _isDefault = value);
                  },
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
              ),

              const SizedBox(height: 100), // Space for button
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isEdit ? 'Update Address' : 'Save Address',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
