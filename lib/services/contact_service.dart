import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/trusted_contact.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import 'auth_service.dart';

class ContactService {
  static final ContactService _instance = ContactService._internal();
  factory ContactService() => _instance;
  ContactService._internal();

  final _contactsStreamController =
      StreamController<List<TrustedContact>>.broadcast();
  List<TrustedContact> _contacts = [];

  List<TrustedContact> get contacts => List.unmodifiable(_contacts);
  Future<List<TrustedContact>> getContacts() async {
    if (!_initialized) await initialize();
    return contacts;
  }
  Stream<List<TrustedContact>> get contactsStream =>
      _contactsStreamController.stream;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Load from local storage first for instant responsiveness
    await _loadFromLocalCache();

    // Listen to auth changes and sync from Firestore
    SafeHerAuthService().authStateChanges.listen((userId) {
      if (userId != null) {
        _syncFromFirestore(userId);
      }
    });

    final currentUid = SafeHerAuthService().currentUserId;
    if (currentUid != null) {
      _syncFromFirestore(currentUid);
    }
  }

  Future<void> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(AppConstants.prefLocalContacts);
      if (jsonStr != null) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        _contacts = decoded
            .map((e) => TrustedContact.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        _contactsStreamController.add(_contacts);
      }
    } catch (e) {
      debugPrint('[ContactService] Error reading local contact cache: $e');
    }
  }

  Future<void> _saveToLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listMap = _contacts.map((c) => c.toMap()).toList();
      await prefs.setString(
        AppConstants.prefLocalContacts,
        jsonEncode(listMap),
      );
    } catch (e) {
      debugPrint('[ContactService] Error saving local contact cache: $e');
    }
  }

  void _syncFromFirestore(String userId) {
    if (SafeHerAuthService().isUsingFallbackLocalAuth) return;

    try {
      FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.contactsSubcollection)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .listen(
            (snapshot) {
              final remoteContacts = snapshot.docs.map((doc) {
                return TrustedContact.fromMap(doc.data(), doc.id);
              }).toList();

              if (remoteContacts.isNotEmpty || _contacts.isEmpty) {
                _contacts = remoteContacts;
                _contactsStreamController.add(_contacts);
                _saveToLocalCache();
              }
            },
            onError: (err) {
              debugPrint('[ContactService] Firestore sync error: $err');
            },
          );
    } catch (e) {
      debugPrint('[ContactService] Firestore subscription error: $e');
    }
  }

  /// Adds a new trusted contact, checking for duplicate phone numbers
  Future<void> addContact(TrustedContact contact) async {
    final normPhone = AppValidators.normalizePhone(contact.phone);
    final isDuplicate = _contacts.any(
      (c) => AppValidators.normalizePhone(c.phone) == normPhone,
    );

    if (isDuplicate) {
      throw Exception('A contact with this phone number already exists.');
    }

    _contacts = [..._contacts, contact];
    _contactsStreamController.add(_contacts);
    await _saveToLocalCache();

    final userId = SafeHerAuthService().currentUserId;
    if (userId != null && !SafeHerAuthService().isUsingFallbackLocalAuth) {
      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .collection(AppConstants.contactsSubcollection)
            .doc(contact.id)
            .set(contact.toMap());
      } catch (e) {
        debugPrint('[ContactService] Failed to write contact to Firestore: $e');
        // Still saved locally
      }
    }
  }

  /// Updates an existing trusted contact
  Future<void> updateContact(TrustedContact contact) async {
    final index = _contacts.indexWhere((c) => c.id == contact.id);
    if (index == -1) {
      throw Exception('Contact not found');
    }

    // Check duplicate phone with others
    final normPhone = AppValidators.normalizePhone(contact.phone);
    final isDuplicate = _contacts.any(
      (c) =>
          c.id != contact.id &&
          AppValidators.normalizePhone(c.phone) == normPhone,
    );
    if (isDuplicate) {
      throw Exception('Another contact already uses this phone number.');
    }

    final updatedList = List<TrustedContact>.from(_contacts);
    updatedList[index] = contact.copyWith(updatedAt: DateTime.now());
    _contacts = updatedList;
    _contactsStreamController.add(_contacts);
    await _saveToLocalCache();

    final userId = SafeHerAuthService().currentUserId;
    if (userId != null && !SafeHerAuthService().isUsingFallbackLocalAuth) {
      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .collection(AppConstants.contactsSubcollection)
            .doc(contact.id)
            .set(updatedList[index].toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('[ContactService] Firestore update error: $e');
      }
    }
  }

  /// Deletes a contact
  Future<void> deleteContact(String contactId) async {
    _contacts = _contacts.where((c) => c.id != contactId).toList();
    _contactsStreamController.add(_contacts);
    await _saveToLocalCache();

    final userId = SafeHerAuthService().currentUserId;
    if (userId != null && !SafeHerAuthService().isUsingFallbackLocalAuth) {
      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .collection(AppConstants.contactsSubcollection)
            .doc(contactId)
            .delete();
      } catch (e) {
        debugPrint('[ContactService] Firestore delete error: $e');
      }
    }
  }
}
