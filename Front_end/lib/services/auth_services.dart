// lib/services/auth_services.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _auth.currentUser;

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // User model data (loaded from Firestore)
  Map<String, dynamic>? userModel;

  // Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Set error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Load user profile
        await loadUserProfile();

        // Update last active timestamp
        await _firestore.collection('users').doc(result.user!.uid).update({
          'last_active': FieldValue.serverTimestamp(),
        });

        _setLoading(false);
        return true;
      }

      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);

      switch (e.code) {
        case 'user-not-found':
          _setError('No user found with this email');
          break;
        case 'wrong-password':
          _setError('Incorrect password');
          break;
        case 'invalid-email':
          _setError('Invalid email address');
          break;
        case 'user-disabled':
          _setError('This account has been disabled');
          break;
        case 'too-many-requests':
          _setError('Too many failed attempts. Please try again later');
          break;
        case 'network-request-failed':
          _setError('Network error. Please check your connection');
          break;
        default:
          _setError('Login failed. Please try again');
      }
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('An unexpected error occurred');
      return false;
    }
  }

  // Sign up with email and password
  Future<User?> signUp(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _setLoading(false);
      return result.user;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);

      switch (e.code) {
        case 'email-already-in-use':
          _setError('An account already exists with this email');
          break;
        case 'invalid-email':
          _setError('Invalid email address');
          break;
        case 'operation-not-allowed':
          _setError('Email/password accounts are not enabled');
          break;
        case 'weak-password':
          _setError('Password is too weak. Please use a stronger password');
          break;
        default:
          _setError('Sign up failed. Please try again');
      }
      return null;
    } catch (e) {
      _setLoading(false);
      _setError('An unexpected error occurred');
      return null;
    }
  }

  // Complete profile (for signup flow - matches your skills_course_page.dart)
  Future<bool> completeProfile({
    required String name,
    required String field,
    required List<String> skills,
    String? profilePictureUrl,
  }) async {
    try {
      if (currentUser == null) {
        _setError('No user logged in');
        return false;
      }

      _setLoading(true);
      _setError(null);

      await _firestore.collection('users').doc(currentUser!.uid).set({
        'uid': currentUser!.uid,
        'email': currentUser!.email,
        'name': name,
        'field': field,
        'skills': skills,
        'profilePicture': profilePictureUrl,
        'created_at': FieldValue.serverTimestamp(),
        'last_active': FieldValue.serverTimestamp(),
      });

      // Load the newly created profile
      await loadUserProfile();

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to complete profile. Please try again');
      return false;
    }
  }

  // Create user profile in Firestore (alternative method)
  Future<bool> createUserProfile({
    required String uid,
    required String email,
    required String name,
    required String field,
    required List<String> skills,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name,
        'field': field,
        'skills': skills,
        'created_at': FieldValue.serverTimestamp(),
        'last_active': FieldValue.serverTimestamp(),
      });

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to create profile. Please try again');
      return false;
    }
  }

  // Load user profile from Firestore
  Future<void> loadUserProfile() async {
    try {
      if (currentUser == null) return;

      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();

      if (doc.exists) {
        userModel = doc.data();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _setError(null);

      await _auth.sendPasswordResetEmail(email: email);

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);

      switch (e.code) {
        case 'user-not-found':
          _setError('No account found with this email');
          break;
        case 'invalid-email':
          _setError('Invalid email address');
          break;
        default:
          _setError('Failed to send reset email. Please try again');
      }
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('An unexpected error occurred');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      userModel = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to sign out');
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      _setError('Failed to send verification email');
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    String? name,
    String? field,
    List<String>? skills,
  }) async {
    try {
      if (currentUser == null) return false;

      _setLoading(true);
      _setError(null);

      Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (field != null) updates['field'] = field;
      if (skills != null) updates['skills'] = skills;
      updates['last_active'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(currentUser!.uid).update(updates);

      // Reload user profile
      await loadUserProfile();

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to update profile');
      return false;
    }
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUser == null) return null;

      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      _setError('Failed to load profile');
      return null;
    }
  }
}