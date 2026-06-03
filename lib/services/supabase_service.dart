import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';

/// Service for interacting with Supabase backend
class SupabaseService {
  SupabaseService._();

  static final instance = SupabaseService._();

  SupabaseClient get client => supabase;

  // ============ AUTH ============

  /// Get current user
  User? get currentUser => client.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Sign up with email and password
  /// [data] is optional metadata (first_name, last_name, phone, onboarding answers)
  /// stored in auth.users.raw_user_meta_data and readable by the handle_new_user trigger.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Send a password reset email
  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  /// Delete the current user's account and all associated data.
  /// Uses a security-definer RPC that deletes from auth.users,
  /// which cascades to public.users and story_progress.
  Future<void> deleteAccount() async {
    await client.rpc('delete_own_account');
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // ============ USERS ============

  /// Get or create user profile
  Future<Map<String, dynamic>?> getOrCreateUserProfile() async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    // Try to get existing profile
    final response =
        await client.from('users').select().eq('id', userId).maybeSingle();

    if (response != null) return response;

    // Create new profile
    await client.from('users').insert({
      'id': userId,
      'email': currentUser!.email,
    });

    return await client.from('users').select().eq('id', userId).single();
  }

  /// Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await client
        .from('users')
        .update({...data, 'updated_at': DateTime.now().toIso8601String()}).eq(
            'id', userId);
  }

  // ============ SURAHS ============

  /// Get all surahs ordered by id (surah number)
  Future<List<Map<String, dynamic>>> getSurahs() async {
    return await client.from('surahs').select().order('id', ascending: true);
  }

  /// Get surah by id (id = surah number, 1-114)
  Future<Map<String, dynamic>?> getSurah(int id) async {
    return await client.from('surahs').select().eq('id', id).maybeSingle();
  }

  // ============ QUIZ ============

  /// Get quiz questions for a surah (surah_mastery category).
  /// Uses the get_quiz_questions_for_user RPC so it skips questions
  /// the current user has already answered and cycles back to the
  /// oldest-answered ones once the fresh pool is exhausted.
  Future<List<Map<String, dynamic>>> getSurahQuizQuestions(int surahId) async {
    final userId = currentUser?.id;
    if (userId == null) {
      // Fallback for unauthenticated state — plain random sample
      return await client
          .from('quiz_questions')
          .select()
          .eq('surah_id', surahId)
          .eq('category', 'surah_mastery')
          .limit(12);
    }

    final result = await client.rpc(
      'get_quiz_questions_for_user',
      params: {
        'p_user_id': userId,
        'p_category': 'surah_mastery',
        'p_surah_id': surahId,
        'p_limit': 12,
      },
    );
    return List<Map<String, dynamic>>.from(result as List);
  }

  /// Get practice questions by category (quran, seerah, prophets, etc.).
  /// Uses the get_quiz_questions_for_user RPC so it skips questions
  /// the current user has already answered.
  Future<List<Map<String, dynamic>>> getPracticeQuestions(
      String category) async {
    final userId = currentUser?.id;
    if (userId == null) {
      return await client
          .from('quiz_questions')
          .select()
          .eq('category', category)
          .limit(15);
    }

    final result = await client.rpc(
      'get_quiz_questions_for_user',
      params: {
        'p_user_id': userId,
        'p_category': category,
        'p_surah_id': null,
        'p_limit': 15,
      },
    );
    return List<Map<String, dynamic>>.from(result as List);
  }

  /// Record that the user answered a question (correct or not).
  /// Powers the "don't repeat" logic and feeds future analytics.
  Future<void> logQuestionAnswered({
    required String questionId,
    required bool wasCorrect,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await client.from('user_question_history').upsert(
      {
        'user_id': userId,
        'question_id': questionId,
        'was_correct': wasCorrect,
        'answered_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,question_id',
    );
  }

  /// Get today's daily challenge
  Future<Map<String, dynamic>?> getTodayDailyChallenge() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return await client
        .from('daily_challenges')
        .select()
        .eq('challenge_date', today)
        .maybeSingle();
  }

  /// Get questions by their IDs (for daily challenges)
  Future<List<Map<String, dynamic>>> getQuestionsByIds(
      List<String> questionIds) async {
    return await client
        .from('quiz_questions')
        .select()
        .inFilter('id', questionIds);
  }

  // ============ AUDIO STORIES ============

  /// Get all audio stories
  Future<List<Map<String, dynamic>>> getAudioStories() async {
    return await client
        .from('audio_stories')
        .select()
        .order('order_index', ascending: true);
  }

  /// Get story by ID
  Future<Map<String, dynamic>?> getAudioStory(String id) async {
    return await client
        .from('audio_stories')
        .select()
        .eq('id', id)
        .maybeSingle();
  }

  /// Get story progress
  Future<Map<String, dynamic>?> getStoryProgress(String storyId) async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    return await client
        .from('story_progress')
        .select()
        .eq('user_id', userId)
        .eq('story_id', storyId)
        .maybeSingle();
  }

  /// Update story progress (save playback position)
  Future<void> updateStoryProgress({
    required String storyId,
    required int positionSeconds,
    bool completed = false,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await client.from('story_progress').upsert(
      {
        'user_id': userId,
        'story_id': storyId,
        'playback_position_seconds': positionSeconds,
        'completed': completed,
        'completed_at': completed ? DateTime.now().toIso8601String() : null,
      },
      onConflict: 'user_id,story_id',
    );
  }

  // ============ SUBSCRIPTION ============

  /// Update subscription status in Supabase
  /// Called by RevenueCat sync to keep Supabase aware of premium/expired status
  Future<void> updateSubscriptionStatus({
    required String status,
    DateTime? expiresAt,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await client.from('users').update({
      'subscription_status': status,
      'subscription_expires_at': expiresAt?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  // ============ STREAKS ============

  /// Call the database function to update streak
  /// Should be called after a user completes a daily challenge
  Future<void> updateStreak() async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await client.rpc('update_user_streak', params: {'p_user_id': userId});
  }
}
