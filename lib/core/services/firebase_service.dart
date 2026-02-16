import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:recording_app/features/cage/data/models/cage_data.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/reminder/data/models/reminder_data.dart';
import '../../features/dashboard/data/models/recording_data.dart';
import '../../features/user/data/models/user_data.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper: Get current user UID
  String get _currentUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return uid;
  }

  // ============================================================================
  // USER PROFILE METHODS
  // ============================================================================

  /// Get user profile dari users/{uid}/profile map
  Future<UserProfile> getUserProfile([String? uid]) async {
    try {
      final userId = uid ?? _currentUid;
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists || doc.data() == null) {
        return const UserProfile();
      }

      final data = doc.data()!;
      return UserProfile.fromJson(data['profile'] as Map<String, dynamic>?);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(UserProfile profile, [String? uid]) async {
    try {
      final userId = uid ?? _currentUid;
      await _firestore.collection('users').doc(userId).set({
        'profile': profile.toJson(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Create user document saat signup
  Future<void> createUserDocument(String uid, UserProfile profile, CageData cage) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'profile': profile.toJson(),
        'cage': cage.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create user document: $e');
    }
  }

  // ============================================================================
  // CAGE METHODS
  // ============================================================================

  /// Get cage data dari users/{uid}/cage map
  Future<CageData> getCage([String? uid]) async {
    try {
      final userId = uid ?? _currentUid;
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists || doc.data() == null) {
        return const CageData();
      }

      final data = doc.data()!;
      return CageData.fromJson(data['cage'] as Map<String, dynamic>?);
    } catch (e) {
      throw Exception('Failed to get cage: $e');
    }
  }

  /// Update cage data
  Future<void> updateCage(CageData cage, [String? uid]) async {
    try {
      final userId = uid ?? _currentUid;
      await _firestore.collection('users').doc(userId).set({
        'cage': cage.toJson(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update cage: $e');
    }
  }

  // ============================================================================
  // PERIOD METHODS
  // ============================================================================

  /// Create new period
  Future<String> createPeriod(PeriodData period, [String? uid]) async {
    try {
      final userId = uid ?? _currentUid;
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('periods')
          .add(period.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create period: $e');
    }
  }

  /// Get active period
  Future<PeriodData?> getActivePeriod([String? uid]) async {
    try {
      final userId = uid ?? _currentUid;
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('periods')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return PeriodData.fromJson(doc.data(), docId: doc.id);
    } catch (e) {
      throw Exception('Failed to get active period: $e');
    }
  }

  /// Get all periods stream
  Stream<List<PeriodData>> getPeriodsStream([String? uid]) {
    try {
      final userId = uid ?? _currentUid;
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('periods')
          .orderBy('startDate', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => PeriodData.fromJson(doc.data(), docId: doc.id))
              .toList());
    } catch (e) {
      throw Exception('Failed to get periods stream: $e');
    }
  }

  /// Get specific period
  Future<PeriodData?> getPeriod(String periodId, [String? uid]) async {
    try {
      final userId = uid ?? _currentUid;
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('periods')
          .doc(periodId)
          .get();

      if (!doc.exists) return null;
      return PeriodData.fromJson(doc.data(), docId: doc.id);
    } catch (e) {
      throw Exception('Failed to get period: $e');
    }
  }

  /// Close period with summary
  Future<void> closePeriod(String periodId, PeriodSummary summary, [String? uid]) async {
    try {
      final userId = uid ?? _currentUid;
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('periods')
          .doc(periodId)
          .update({
        'isActive': false,
        'endDate': FieldValue.serverTimestamp(),
        'summary': summary.toJson(),
      });
    } catch (e) {
      throw Exception('Failed to close period: $e');
    }
  }

  /// Update period
  Future<void> updatePeriod(String periodId, PeriodData period, [String? uid]) async {
    try {
      final userId = uid ?? _currentUid;
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('periods')
          .doc(periodId)
          .update(period.toJson());
    } catch (e) {
      throw Exception('Failed to update period: $e');
    }
  }

  // ============================================================================
  // RECORDING METHODS (nested in periods)
  // ============================================================================

  /// Add recording to specific period
  Future<void> addRecording(String periodId, RecordingData recording, [String? uid]) async {
    try {
      final userId = uid ?? _currentUid;
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('periods')
          .doc(periodId)
          .collection('recordings')
          .add(recording.toJson());
    } catch (e) {
      throw Exception('Failed to add recording: $e');
    }
  }

  /// Get recordings stream for specific period
  Stream<List<RecordingData>> getRecordingsStream(String periodId, [String? uid]) {
    try {
      final userId = uid ?? _currentUid;
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('periods')
          .doc(periodId)
          .collection('recordings')
          .orderBy('day')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => RecordingData.fromJson(doc.data(), docId: doc.id))
              .toList());
    } catch (e) {
      throw Exception('Failed to get recordings stream: $e');
    }
  }

  /// Get weight data stream for chart (FlSpot)
  Stream<List<FlSpot>> getWeightStream(String periodId, [String? uid]) {
    try {
      final userId = uid ?? _currentUid;
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('periods')
          .doc(periodId)
          .collection('recordings')
          .orderBy('day')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => RecordingData.fromJson(doc.data(), docId: doc.id))
              .map((recording) => FlSpot(
                    recording.day.toDouble(),
                    recording.avgWeightGram.toDouble(),
                  ))
              .toList());
    } catch (e) {
      throw Exception('Failed to get weight stream: $e');
    }
  }

  /// Delete recording
  Future<void> deleteRecording(String periodId, String recordingId, [String? uid]) async {
    try {
      final userId = uid ?? _currentUid;
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('periods')
          .doc(periodId)
          .collection('recordings')
          .doc(recordingId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete recording: $e');
    }
  }

  // ============================================================================
  // REMINDER METHODS (optional - bisa di users/{uid}/reminders)
  // ============================================================================

  /// Add reminder
  Future<void> addReminder(ReminderData reminder, [String? uid]) async {
    try {
      final userId = uid ?? _currentUid;
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('reminders')
          .add(reminder.toJson());
    } catch (e) {
      throw Exception('Failed to add reminder: $e');
    }
  }

  /// Delete reminder
  Future<void> deleteReminder(String reminderId, [String? uid]) async {
    try {
      final userId = uid ?? _currentUid;
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('reminders')
          .doc(reminderId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete reminder: $e');
    }
  }

  /// Get reminders stream
  Stream<List<ReminderData>> getReminderStream([String? uid]) {
    try {
      final userId = uid ?? _currentUid;
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('reminders')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ReminderData.fromJson(doc.data()))
              .toList());
    } catch (e) {
      throw Exception('Failed to get reminder stream: $e');
    }
  }
}

