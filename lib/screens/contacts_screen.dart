import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../app/theme.dart';
import '../models/trusted_contact.dart';
import '../services/alert_service.dart';
import '../services/contact_service.dart';
import '../utils/validators.dart';
import '../widgets/empty_state.dart';
import '../widgets/shared_widgets.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final List<String> _relationshipOptions = [
    'Mother',
    'Father',
    'Sister',
    'Brother',
    'Partner',
    'Friend',
    'Roommate',
    'Colleague',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-populate with reference examples if list is empty for immediate demonstration
    _seedDefaultContactsIfEmpty();
  }

  Future<void> _seedDefaultContactsIfEmpty() async {
    final current = ContactService().contacts;
    if (current.isEmpty) {
      final now = DateTime.now();
      final defaultList = [
        TrustedContact(
          id: const Uuid().v4(),
          name: 'Mom',
          phone: '+91 98765 43210',
          relationship: 'Mother',
          createdAt: now,
          updatedAt: now,
        ),
        TrustedContact(
          id: const Uuid().v4(),
          name: 'Sister',
          phone: '+91 87654 32109',
          relationship: 'Sister',
          createdAt: now,
          updatedAt: now,
        ),
        TrustedContact(
          id: const Uuid().v4(),
          name: 'Best Friend',
          phone: '+91 76543 21098',
          relationship: 'Friend',
          createdAt: now,
          updatedAt: now,
        ),
        TrustedContact(
          id: const Uuid().v4(),
          name: 'Roommate',
          phone: '+91 65432 10987',
          relationship: 'Roommate',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      for (final c in defaultList) {
        try {
          await ContactService().addContact(c);
        } catch (_) {}
      }
    }
  }

  void _showContactDialog([TrustedContact? existingContact]) {
    final isEditing = existingContact != null;
    final nameController = TextEditingController(
      text: existingContact?.name ?? '',
    );
    final phoneController = TextEditingController(
      text: existingContact?.phone ?? '',
    );
    final emailController = TextEditingController(
      text: existingContact?.email ?? '',
    );
    String selectedRelationship = existingContact?.relationship ?? 'Friend';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEditing
                                ? 'Edit Trusted Contact'
                                : 'Add Trusted Contact',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: SafeHerColors.primaryText,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Contact Name *',
                          hintText: 'e.g. Mom, Sister, Sarah',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: AppValidators.validateName,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number *',
                          hintText: '+91 98765 43210',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: AppValidators.validatePhone,
                      ),
                      const SizedBox(height: 14),

                      DropdownButtonFormField<String>(
                        initialValue: selectedRelationship,
                        decoration: const InputDecoration(
                          labelText: 'Relationship *',
                          prefixIcon: Icon(Icons.family_restroom_outlined),
                        ),
                        items: _relationshipOptions.map((rel) {
                          return DropdownMenuItem(value: rel, child: Text(rel));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedRelationship = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address (Optional)',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: AppValidators.validateEmail,
                      ),
                      const SizedBox(height: 24),

                      SafeHerPrimaryButton(
                        text: isEditing ? 'Save Changes' : 'Add Contact',
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final now = DateTime.now();
                          try {
                            if (isEditing) {
                              final updated = existingContact.copyWith(
                                name: nameController.text.trim(),
                                phone: phoneController.text.trim(),
                                relationship: selectedRelationship,
                                email: emailController.text.trim().isEmpty
                                    ? null
                                    : emailController.text.trim(),
                                updatedAt: now,
                              );
                              await ContactService().updateContact(updated);
                            } else {
                              final newContact = TrustedContact(
                                id: const Uuid().v4(),
                                name: nameController.text.trim(),
                                phone: phoneController.text.trim(),
                                relationship: selectedRelationship,
                                email: emailController.text.trim().isEmpty
                                    ? null
                                    : emailController.text.trim(),
                                createdAt: now,
                                updatedAt: now,
                              );
                              await ContactService().addContact(newContact);
                            }

                            if (!context.mounted) return;
                            Navigator.pop(ctx);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$e'),
                                backgroundColor: SafeHerColors.emergencyRed,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(TrustedContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Contact?'),
        content: Text(
          'Remove ${contact.name} from your trusted emergency circle?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SafeHerColors.emergencyRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ContactService().deleteContact(contact.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SafeHerColors.surfaceWhite,
      appBar: SafeHerAppBar(
        title: 'Trusted Contacts',
        isDark: true,
        trailing: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.add, color: Colors.white, size: 22),
            onPressed: () => _showContactDialog(),
          ),
        ),
      ),
      body: StreamBuilder<List<TrustedContact>>(
        stream: ContactService().contactsStream,
        initialData: ContactService().contacts,
        builder: (context, snapshot) {
          final contacts = snapshot.data ?? [];

          if (contacts.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.people_outline,
              title: 'No Trusted Contacts Yet',
              description: 'Add trusted friends or family who will receive your emergency alert link.',
              buttonText: '+ Add Contact',
              onButtonPressed: () => _showContactDialog(),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  itemCount: contacts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return _buildContactCard(contact);
                  },
                ),
              ),

              // Bottom Fixed "+ Add Contact" Button matching Screen 7
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: SafeHerPrimaryButton(
                  text: '+ Add Contact',
                  onPressed: () => _showContactDialog(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContactCard(TrustedContact contact) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SafeHerColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar circle
          CircleAvatar(
            radius: 24,
            backgroundColor: SafeHerColors.palePink,
            child: Text(
              contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: SafeHerColors.primaryRose,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name, Phone, and Relationship
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: SafeHerColors.primaryText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  contact.phone,
                  style: const TextStyle(
                    fontSize: 13,
                    color: SafeHerColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contact.relationship,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF988C9F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Call Icon Button
          IconButton(
            icon: const Icon(
              Icons.phone_outlined,
              color: SafeHerColors.primaryText,
              size: 21,
            ),
            onPressed: () => AlertService().launchEmergencyCall(contact.phone),
          ),

          // Message/SMS Icon Button
          IconButton(
            icon: const Icon(
              Icons.chat_bubble_outline,
              color: SafeHerColors.primaryText,
              size: 20,
            ),
            onPressed: () => AlertService().launchSmsApp(
              phoneNumbers: [contact.phone],
              message:
                  'SafeHer Alert: Live location update from ${contact.name}\'s safety network.',
            ),
          ),

          // More Options (Edit / Delete)
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: SafeHerColors.secondaryText,
              size: 20,
            ),
            onSelected: (val) {
              if (val == 'edit') _showContactDialog(contact);
              if (val == 'delete') _confirmDelete(contact);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Delete',
                  style: TextStyle(color: SafeHerColors.emergencyRed),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
