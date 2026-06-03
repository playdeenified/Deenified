import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../services/supabase_service.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final int surahId;
  final String? category;

  const QuizScreen({super.key, required this.surahId, this.category});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  int? _selectedAnswerIndex;
  bool _answerSubmitted = false;
  bool _quizComplete = false;
  bool _isLoading = true;
  String? _errorMessage;
  List<_ParsedQuestion> _questions = [];

  /// Whether this is a daily challenge quiz (surahId == 0 and no category)
  bool get _isDailyChallenge => widget.surahId == 0 && widget.category == null;

  /// Whether this is a practice quiz
  bool get _isPractice => widget.category != null;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<Map<String, dynamic>> rawQuestions;

      if (_isPractice) {
        rawQuestions = await SupabaseService.instance
            .getPracticeQuestions(widget.category!);
      } else if (_isDailyChallenge) {
        // Get today's daily challenge and fetch those specific questions
        final challenge =
            await SupabaseService.instance.getTodayDailyChallenge();
        if (challenge == null) {
          setState(() {
            _errorMessage = 'No daily challenge available today.';
            _isLoading = false;
          });
          return;
        }
        final questionIds = (challenge['question_ids'] as List<dynamic>)
            .map((e) => e.toString())
            .toList();
        rawQuestions =
            await SupabaseService.instance.getQuestionsByIds(questionIds);
      } else {
        // surahId is now the direct PK (1-114)
        rawQuestions = await SupabaseService.instance
            .getSurahQuizQuestions(widget.surahId);
      }

      if (rawQuestions.isEmpty) {
        setState(() {
          _errorMessage = 'No questions available yet for this quiz.';
          _isLoading = false;
        });
        return;
      }

      // Parse questions from DB rows
      _questions = rawQuestions.map((row) {
        final options = (row['options'] as List<dynamic>?) ?? [];
        final parsed = <_OptionData>[];

        for (int i = 0; i < options.length; i++) {
          final opt = options[i] as Map<String, dynamic>;
          parsed.add(_OptionData(
            text: opt['text'] as String? ?? 'Option ${i + 1}',
            correct: opt['correct'] == true,
          ));
        }

        // Randomize option order
        parsed.shuffle();
        final correctIdx = parsed.indexWhere((o) => o.correct);

        return _ParsedQuestion(
          id: row['id'] as String? ?? '',
          question: row['question_text'] as String? ?? 'Question',
          options: parsed.map((o) => o.text).toList(),
          correctIndex: correctIdx >= 0 ? correctIdx : 0,
          explanation: row['explanation'] as String?,
        );
      }).toList();

      // Shuffle for variety
      _questions.shuffle();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load questions: $e';
        _isLoading = false;
      });
    }
  }

  void _selectAnswer(int index) {
    if (_answerSubmitted) return;

    HapticFeedback.lightImpact();
    setState(() {
      _selectedAnswerIndex = index;
    });
  }

  void _submitAnswer() {
    if (_selectedAnswerIndex == null) return;

    final question = _questions[_currentQuestionIndex];
    final wasCorrect = _selectedAnswerIndex == question.correctIndex;

    HapticFeedback.mediumImpact();
    setState(() {
      _answerSubmitted = true;
      if (wasCorrect) {
        _correctAnswers++;
      }
    });

    // Record this answer so the user doesn't see the same question again.
    if (question.id.isNotEmpty) {
      SupabaseService.instance.logQuestionAnswered(
        questionId: question.id,
        wasCorrect: wasCorrect,
      );
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _answerSubmitted = false;
      });
    } else {
      // Quiz complete — update streak if daily challenge
      if (_isDailyChallenge) {
        SupabaseService.instance.updateStreak();
      }
      setState(() {
        _quizComplete = true;
      });
    }
  }

  double get _scorePercentage =>
      _questions.isEmpty ? 0 : _correctAnswers / _questions.length;
  bool get _passed => _scorePercentage >= 0.8;

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.richBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.metallicGold),
        ),
      );
    }

    // Error state
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.richBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz_outlined,
                    size: 64, color: AppColors.textTertiary),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                PremiumButton(text: 'GO BACK', onPressed: () => context.pop()),
              ],
            ),
          ),
        ),
      );
    }

    // Results screen
    if (_quizComplete) {
      return _buildResultsScreen(context);
    }

    // Quiz screen
    final question = _questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: AppColors.richBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isDailyChallenge ? 'Daily Challenge' : 'Trivia',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
              style: const TextStyle(
                color: AppColors.metallicGold,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Bar
              LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / _questions.length,
                backgroundColor: AppColors.deepCharcoal,
                color: AppColors.metallicGold,
                minHeight: 8,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Question
              Text(
                question.question,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Options
              Expanded(
                child: ListView.separated(
                  itemCount: question.options.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedAnswerIndex == index;
                    final isCorrect = question.correctIndex == index;

                    Color borderColor = AppColors.glassBorder;
                    Color bgColor = AppColors.deepCharcoal;

                    if (_answerSubmitted) {
                      if (isCorrect) {
                        borderColor = AppColors.success;
                        bgColor = AppColors.success.withValues(alpha: 0.1);
                      } else if (isSelected && !isCorrect) {
                        borderColor = AppColors.error;
                        bgColor = AppColors.error.withValues(alpha: 0.1);
                      }
                    } else if (isSelected) {
                      borderColor = AppColors.metallicGold;
                    }

                    return GestureDetector(
                      onTap: () => _selectAnswer(index),
                      child: AnimatedContainer(
                        duration: AppDurations.fast,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: borderColor, width: 2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? borderColor
                                    : Colors.transparent,
                                border: Border.all(color: borderColor),
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + index), // A, B, C, D
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.richBlack
                                        : borderColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                question.options[index],
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            if (_answerSubmitted && isCorrect)
                              const Icon(Icons.check_circle,
                                  color: AppColors.success),
                            if (_answerSubmitted && isSelected && !isCorrect)
                              const Icon(Icons.cancel, color: AppColors.error),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Explanation (shown after submit)
              if (_answerSubmitted &&
                  question.explanation != null &&
                  question.explanation!.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.metallicGold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.metallicGold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: AppColors.metallicGold, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          question.explanation!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Submit/Next Button
              PremiumButton(
                text: _answerSubmitted
                    ? (_currentQuestionIndex < _questions.length - 1
                        ? 'NEXT'
                        : 'SEE RESULTS')
                    : 'SUBMIT',
                onPressed: _selectedAnswerIndex == null
                    ? () {}
                    : (_answerSubmitted ? _nextQuestion : _submitAnswer),
                isOutlined: _selectedAnswerIndex == null && !_answerSubmitted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.richBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Result Icon
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _passed
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  border: Border.all(
                    color: _passed ? AppColors.success : AppColors.error,
                    width: 3,
                  ),
                ),
                child: Icon(
                  _passed ? Icons.celebration : Icons.refresh,
                  size: 64,
                  color: _passed ? AppColors.success : AppColors.error,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                _passed ? 'Congratulations!' : 'Keep Practicing!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          _passed ? AppColors.success : AppColors.textPrimary,
                    ),
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'You scored $_correctAnswers out of ${_questions.length}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),

              const SizedBox(height: AppSpacing.sm),

              Text(
                '${(_scorePercentage * 100).toInt()}%',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _passed
                          ? AppColors.metallicGold
                          : AppColors.textPrimary,
                    ),
              ),

              if (_passed) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_open, color: AppColors.success),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _isDailyChallenge
                            ? 'Challenge Complete!'
                            : 'Next Surah Unlocked!',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              PremiumButton(
                text: _passed ? 'CONTINUE' : 'TRY AGAIN',
                onPressed: () {
                  if (_passed) {
                    context.pop();
                  } else {
                    setState(() {
                      _currentQuestionIndex = 0;
                      _correctAnswers = 0;
                      _selectedAnswerIndex = null;
                      _answerSubmitted = false;
                      _quizComplete = false;
                    });
                  }
                },
              ),

              const SizedBox(height: AppSpacing.md),

              TextButton(
                onPressed: () => context.pop(),
                child:
                    Text(_isDailyChallenge ? 'Back to Home' : 'Back to Surahs'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.deepCharcoal,
        title: const Text('Exit Quiz?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close the dialog
              context.pop(); // Pop the quiz screen
            },
            child: const Text('Exit', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ParsedQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;

  _ParsedQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
  });
}

class _OptionData {
  final String text;
  final bool correct;

  _OptionData({required this.text, required this.correct});
}
