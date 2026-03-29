import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_display_helper.dart';
import '../../../../injection/injection_container.dart' as di;
import '../bloc/reviews_cubit.dart';
import '../bloc/reviews_state.dart';

class WriteReviewPage extends StatefulWidget {
  final String businessId;
  final String businessName;

  const WriteReviewPage({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  State<WriteReviewPage> createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  /// 0 = no selection (cleared default)
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview(BuildContext context) async {
    if (_rating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating')),
      );
      return;
    }
    if (_commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a review')),
      );
      return;
    }

    if (!context.mounted) return;
    context.read<ReviewsCubit>().writeReview(
          businessId: widget.businessId,
          rating: _rating,
          comment: _commentController.text,
          photoUrls: null,
        );
  }

  void _clearForm() {
    setState(() {
      _rating = 0;
      _commentController.clear();
    });
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 5:
        return 'Excellent';
      case 4:
        return 'Good';
      case 3:
        return 'Average';
      case 2:
        return 'Poor';
      case 1:
        return 'Very Poor';
      default:
        return 'Tap stars to rate';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<ReviewsCubit>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Write Review'),
          actions: [
            TextButton(
              onPressed: _clearForm,
              child: const Text(
                'Reset',
                style: TextStyle(color: AppColors.brandSecondary),
              ),
            ),
          ],
        ),
        body: BlocListener<ReviewsCubit, ReviewsState>(
          listener: (context, state) {
            if (state is WriteReviewSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Review posted successfully!')),
              );
              Navigator.pop(context, true);
            } else if (state is WriteReviewError) {
              ErrorDisplayHelper.show(context, message: state.message, title: 'Could not post review');
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBusinessInfo(),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'Rate your experience',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildStarRating(),
                const SizedBox(height: 24),
                _buildCommentField(),
                const SizedBox(height: 32),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessInfo() {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.backgroundGrey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.store, size: 32, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.businessName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStarRating() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _rating = index + 1;
                });
              },
              child: Icon(
                Icons.star,
                size: 48,
                color: index < _rating ? Colors.amber : AppColors.backgroundGrey,
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          _getRatingText(_rating),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.brandPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.backgroundGrey),
      ),
      child: TextField(
        controller: _commentController,
        maxLines: 6,
        decoration: const InputDecoration(
          hintText: 'Share your experience...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
          hintStyle: TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<ReviewsCubit, ReviewsState>(
      builder: (context, state) {
        final isLoading = state is WriteReviewLoading;
        return AppButton(
          text: 'Post',
          isLoading: isLoading,
          onPressed: isLoading
              ? null
              : () => _submitReview(context),
        );
      },
    );
  }
}
