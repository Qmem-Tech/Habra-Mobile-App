import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
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
  int _rating = 4;
  final TextEditingController _commentController = TextEditingController();
  final List<String> _photos = [];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
        return 'Good';
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
              onPressed: () {
                _rating = 4;
                _commentController.clear();
                _photos.clear();
                setState(() {});
              },
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
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
                const SizedBox(height: 24),
                _buildPhotoSection(),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.businessName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ethiopian Cuisine • Bole, Addis Ababa',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
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

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Add Photos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${_photos.length}/5',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            // Handle photo selection
            if (_photos.length < 5) {
              setState(() {
                _photos.add('photo_${_photos.length + 1}');
              });
            }
          },
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.backgroundGrey),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo, color: AppColors.brandPrimary, size: 32),
                const SizedBox(height: 8),
                const Text(
                  'Add',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
              : () {
                  if (_commentController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please write a review')),
                    );
                    return;
                  }
                  context.read<ReviewsCubit>().writeReview(
                        businessId: widget.businessId,
                        rating: _rating,
                        comment: _commentController.text,
                        photoUrls: _photos.isEmpty ? null : _photos,
                      );
                },
        );
      },
    );
  }
}
