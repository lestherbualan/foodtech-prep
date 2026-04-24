import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin Review Persistence Service
// ─────────────────────────────────────────────────────────────────────────────

/// Thin wrapper around [SharedPreferences] for admin review session storage.
///
/// Each session is stored as a JSON string under the key
/// `admin_review_session_{sessionKey}`.  The [sessionKey] is the subtopic name.
///
/// All methods are static so no instance is needed — callers just call
/// `AdminReviewPersistence.write(key, json)` etc.
class AdminReviewPersistence {
  AdminReviewPersistence._();

  static const _prefix = 'admin_review_session_';

  // ── Write ────────────────────────────────────────────────────────────────────

  static Future<void> write(
    String sessionKey,
    Map<String, dynamic> json,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefix$sessionKey', jsonEncode(json));
    } catch (e) {
      debugPrint('[AdminReviewPersistence] write failed for $sessionKey: $e');
    }
  }

  // ── Read one ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> read(String sessionKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$sessionKey');
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[AdminReviewPersistence] read failed for $sessionKey: $e');
      return null;
    }
  }

  // ── Read all ─────────────────────────────────────────────────────────────────

  /// Returns all stored sessions as `{sessionKey: rawJson}`.
  static Future<Map<String, Map<String, dynamic>>> readAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = <String, Map<String, dynamic>>{};
      for (final prefKey in prefs.getKeys()) {
        if (!prefKey.startsWith(_prefix)) continue;
        final sessionKey = prefKey.substring(_prefix.length);
        final raw = prefs.getString(prefKey);
        if (raw == null) continue;
        try {
          result[sessionKey] = jsonDecode(raw) as Map<String, dynamic>;
        } catch (_) {
          // Corrupt entry — silently skip; will be cleaned up on next save.
        }
      }
      return result;
    } catch (e) {
      debugPrint('[AdminReviewPersistence] readAll failed: $e');
      return {};
    }
  }

  // ── Delete ───────────────────────────────────────────────────────────────────

  static Future<void> delete(String sessionKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefix$sessionKey');
    } catch (e) {
      debugPrint('[AdminReviewPersistence] delete failed for $sessionKey: $e');
    }
  }
}
