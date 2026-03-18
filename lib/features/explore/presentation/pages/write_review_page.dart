import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/services/image_picker_service.dart';
import '../../../../core/services/storage_service.dart';
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
  final List<File> _photoFiles = [];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview(BuildContext context) async {
    if (_commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a review')),
      );
      return;
    }

    List<String>? photoUrls;
    if (_photoFiles.isNotEmpty) {
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anon';
        final pathPrefix = '$userId/${widget.businessId}';
        photoUrls = await di.sl<StorageService>().uploadImages(
          SupabaseBuckets.reviews,
          pathPrefix,
          _photoFiles,
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo upload failed: $e')),
        );
        return;
      }
    }

    if (!context.mounted) return;
    context.read<ReviewsCubit>().writeReview(
          businessId: widget.businessId,
          rating: _rating,
          comment: _commentController.text,
          photoUrls: photoUrls,
        );
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
                _photoFiles.clear();
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
              '${_photoFiles.length}/5',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ..._photoFiles.asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          e.value,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _photoFiles.removeAt(e.key));
                          },
                          child: const Icon(Icons.close, size: 20, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (_photoFiles.length < 5)
                GestureDetector(
                  onTap: () async {
                    final file = await di.sl<ImagePickerService>().pickImage(context);
                    if (file != null && mounted) {
                      setState(() => _photoFiles.add(file));
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
              : () => _submitReview(context),
        );
      },
    );
  }
}
