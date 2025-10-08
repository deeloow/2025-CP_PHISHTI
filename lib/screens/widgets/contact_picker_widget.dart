import 'package:flutter/material.dart';
import '../../core/services/sms_integration_service.dart';

class ContactPickerWidget extends StatefulWidget {
  final Function(Contact) onContactSelected;
  final String? selectedContactId;

  const ContactPickerWidget({
    super.key,
    required this.onContactSelected,
    this.selectedContactId,
  });

  @override
  State<ContactPickerWidget> createState() => _ContactPickerWidgetState();
}

class _ContactPickerWidgetState extends State<ContactPickerWidget> {
  List<Contact> _contacts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      final hasPermissions = await SmsIntegrationService.instance.hasContactsPermissions();
      if (!hasPermissions) {
        final granted = await SmsIntegrationService.instance.requestContactsPermissions();
        if (!granted) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      final contacts = await SmsIntegrationService.instance.getContacts();
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading contacts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Contact> get _filteredContacts {
    if (_searchQuery.isEmpty) {
      return _contacts;
    }
    return _contacts.where((contact) {
      return contact.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             contact.phoneNumber.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Select Contact'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Contacts List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredContacts.isEmpty
                    ? _EmptyContactsState()
                    : ListView.builder(
                        itemCount: _filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = _filteredContacts[index];
                          final isSelected = contact.id == widget.selectedContactId;
                          
                          return _ContactTile(
                            contact: contact,
                            isSelected: isSelected,
                            onTap: () {
                              widget.onContactSelected(contact);
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final Contact contact;
  final bool isSelected;
  final VoidCallback onTap;

  const _ContactTile({
    required this.contact,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isSelected 
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: contact.photoUri.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  contact.photoUri,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.person,
                    color: isSelected 
                        ? Colors.white
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            : Icon(
                Icons.person,
                color: isSelected 
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
              ),
      ),
      title: Text(
        contact.name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(contact.phoneNumber),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }
}

class _EmptyContactsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.contacts_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Contacts Found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure you have contacts in your device',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
