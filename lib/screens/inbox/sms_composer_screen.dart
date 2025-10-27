import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/services/sms_integration_service.dart';
import '../widgets/contact_picker_widget.dart';

class SmsComposerScreen extends StatefulWidget {
  const SmsComposerScreen({super.key});

  @override
  State<SmsComposerScreen> createState() => _SmsComposerScreenState();
}

class _SmsComposerScreenState extends State<SmsComposerScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _messageFocus = FocusNode();
  
  bool _isLoading = false;
  bool _isMms = false;
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();
  Contact? _selectedContact;

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    _phoneFocus.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_phoneController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      _showSnackBar('Please enter both phone number and message', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool success = false;
      
      if (_isMms && _imagePath != null) {
        // MMS sending not implemented yet
        _showSnackBar('MMS sending not implemented yet', Colors.orange);
        return;
      } else {
        // SMS sending not implemented yet
        _showSnackBar('SMS sending not implemented yet', Colors.orange);
        return;
      }

      // Success handling removed since we return early above
    } catch (e) {
      _showSnackBar('Error sending message: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
        _showSnackBar('Image selected successfully', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', Colors.red);
    }
  }

  Future<void> _pickContact() async {
    try {
      final contact = await Navigator.of(context).push<Contact>(
        MaterialPageRoute(
          builder: (context) => ContactPickerWidget(
            onContactSelected: (contact) {},
            selectedContactId: _selectedContact?.id,
          ),
        ),
      );
      
      if (contact != null) {
        setState(() {
          _selectedContact = contact;
          _phoneController.text = contact.phoneNumber;
        });
        _showSnackBar('Contact selected: ${contact.name}', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Error picking contact: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('New Message'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _sendMessage,
              child: const Text('Send'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Phone Number Field
            TextField(
              controller: _phoneController,
              focusNode: _phoneFocus,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(15),
              ],
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: _selectedContact != null 
                    ? _selectedContact!.name 
                    : 'Enter phone number',
                prefixIcon: const Icon(Icons.phone),
                suffixIcon: IconButton(
                  onPressed: _pickContact,
                  icon: const Icon(Icons.contacts),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _messageFocus.requestFocus(),
            ),
            
            const SizedBox(height: 16),
            
            // Message Type Toggle
            Row(
              children: [
                Expanded(
                  child: FilterChip(
                    label: const Text('SMS'),
                    selected: !_isMms,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _isMms = false;
                          _imagePath = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    label: const Text('MMS'),
                    selected: _isMms,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _isMms = true;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Image Picker (for MMS)
            if (_isMms) ...[
              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _imagePath != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_imagePath!),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _imagePath = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 32,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add Image',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Message Field
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocus,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  labelText: 'Message',
                  hintText: 'Type your message here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Character Count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Characters: ${_messageController.text.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                if (_isMms)
                  Text(
                    'MMS',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
