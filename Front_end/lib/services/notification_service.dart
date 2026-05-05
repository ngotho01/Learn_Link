import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permission
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Notification permission granted');

        // Initialize local notifications
        await _initializeLocalNotifications();

        // Get FCM token
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          print('📱 FCM Token: $token');
          await _saveFCMToken(token);
        }

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen(_saveFCMToken);

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle background messages
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

        _isInitialized = true;
      } else {
        print('⚠️ Notification permission denied');
      }
    } catch (e) {
      print('❌ Error initializing notifications: $e');
    }
  }

  // Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fcm_token': token,
          'last_token_update': FieldValue.serverTimestamp(),
        });
        print('✅ FCM token saved to Firestore');
      }
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📩 Foreground message: ${message.notification?.title}');

    // Save to Firestore
    await _saveNotificationToFirestore(message);

    // Show local notification
    await _showLocalNotification(message);
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'learnlink_channel',
      'LearnLink Notifications',
      channelDescription: 'Notifications from LearnLink',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'LearnLink',
      body: message.notification?.body ?? 'You have a new notification',
      notificationDetails: details,
      payload: message.data.toString(),
    );
  }

  // Save notification to Firestore
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .add({
          'title': message.notification?.title ?? '',
          'body': message.notification?.body ?? '',
          'type': message.data['type'] ?? 'general',
          'data': message.data,
          'read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
        print('✅ Notification saved to Firestore');
      }
    } catch (e) {
      print('❌ Error saving notification: $e');
    }
  }

  // Handle notification tap (from background/terminated)
  void _handleNotificationTap(RemoteMessage message) {
    print('📱 Notification tapped: ${message.notification?.title}');
    // Navigate to appropriate screen based on notification type
    // This will be handled in main.dart
  }

  // Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('📱 Local notification tapped');
    // Handle navigation
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(notificationId)
            .update({'read': true});
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final batch = FirebaseFirestore.instance.batch();
        final notifications = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .where('read', isEqualTo: false)
            .get();

        for (var doc in notifications.docs) {
          batch.update(doc.reference, {'read': true});
        }

        await batch.commit();
      }
    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(notificationId)
            .delete();
      }
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  // Get unread count
  Stream<int> getUnreadCountStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get notifications stream
  Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList());
  }

  // Create local notification (for testing)
  Future<void> createTestNotification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': 'Test Notification',
        'body': 'This is a test notification from LearnLink',
        'type': 'general',
        'data': {},
        'read': false,
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background message: ${message.notification?.title}');
  // Handle background message
}