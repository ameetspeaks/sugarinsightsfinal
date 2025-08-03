import 'dart:convert';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'notification_service.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  // final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final NotificationService _notificationService = NotificationService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> initialize() async {
    print('FCM Service: Firebase Messaging not configured - using local notifications only');
    
    // TODO: Configure Firebase Messaging when needed
    // Request permission
    // await _fcm.requestPermission(
    //   alert: true,
    //   badge: true,
    //   sound: true,
    // );

    // Get FCM token
    // String? token = await _fcm.getToken();
    // if (token != null) {
    //   await _storage.write(key: 'fcm_token', value: token);
    //   // TODO: Send token to backend
    // }

    // Listen for token refresh
    // _fcm.onTokenRefresh.listen((token) async {
    //   await _storage.write(key: 'fcm_token', value: token);
    //   // TODO: Send updated token to backend
    // });

    // Handle background messages
    // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    // FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification open
    // FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check for initial message (app opened from terminated state)
    // final initialMessage = await _fcm.getInitialMessage();
    // if (initialMessage != null) {
    //   _handleInitialMessage(initialMessage);
    // }
  }

  // Background message handler
  // static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  //   print('Handling a background message: ${message.messageId}');
  //   // Handle background message
  //   // Note: This runs in a separate isolate, so we can't use instance methods
  // }

  // Foreground message handler
  // void _handleForegroundMessage(RemoteMessage message) async {
  //   print('Got a message whilst in the foreground!');
  //   print('Message data: ${message.data}');

  //   if (message.notification != null) {
  //     await _notificationService.showNotification(
  //       id: message.hashCode,
  //       title: message.notification!.title ?? 'New Message',
  //       body: message.notification!.body ?? '',
  //       payload: json.encode(message.data),
  //     );
  //   }
  // }

  // Handle when app is opened from a notification
  // void _handleMessageOpenedApp(RemoteMessage message) {
  //   print('Message opened app: ${message.data}');
  //   // TODO: Navigate to appropriate screen based on message data
  // }

  // Handle initial message (app opened from terminated state)
  // void _handleInitialMessage(RemoteMessage message) {
  //   print('Initial message: ${message.data}');
  //   // TODO: Navigate to appropriate screen based on message data
  // }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    print('FCM Service: Subscribing to topic $topic (Firebase not configured)');
    // await _fcm.subscribeToTopic(topic);
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    print('FCM Service: Unsubscribing from topic $topic (Firebase not configured)');
    // await _fcm.unsubscribeFromTopic(topic);
  }

  // Get FCM token
  Future<String?> getFCMToken() async {
    return await _storage.read(key: 'fcm_token');
  }

  // Delete FCM token
  Future<void> deleteFCMToken() async {
    // await _fcm.deleteToken();
    await _storage.delete(key: 'fcm_token');
  }
} 