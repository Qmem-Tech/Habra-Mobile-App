import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/feedback_submission.dart';
import '../bloc/feedback_cubit.dart';
import '../bloc/feedback_state.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  FeedbackType _selectedType = FeedbackType.positive;
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: BlocConsumer<FeedbackCubit, FeedbackState>(
        listener: (context, state) {
          if (state is FeedbackSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Thank you! Your feedback has been sent.'),
                backgroundColor: AppColors.success,
              ),
            );
            if (!context.mounted) return;
            Navigator.pop(context);
          }
          if (state is FeedbackError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isSubmitting = state is FeedbackSubmitting;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppResources.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Type',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppResources.spacingS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppResources.spacingM,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius:
                        BorderRadius.circular(AppResources.radiusM),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<FeedbackType>(
                      value: _selectedType,
                      isExpanded: true,
                      items: FeedbackType.values.map((type) {
                        return DropdownMenuItem<FeedbackType>(
                          value: type,
                          child: Text(type.displayName),
                        );
                      }).toList(),
                      onChanged: isSubmitting
                          ? null
                          : (FeedbackType? value) {
                              if (value != null) {
                                setState(() => _selectedType = value);
                              }
                            },
                    ),
                  ),
                ),
                const SizedBox(height: AppResources.spacingL),
                Text(
                  'Feedback',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppResources.spacingS),
                TextField(
                  controller: _textController,
                  maxLines: 6,
                  enabled: !isSubmitting,
                  decoration: InputDecoration(
                    hintText: 'Share your feedback...',
                    filled: true,
                    fillColor: AppColors.backgroundWhite,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppResources.radiusM),
                    ),
                    contentPadding: const EdgeInsets.all(
                      AppResources.spacingM,
                    ),
                  ),
                ),
                const SizedBox(height: AppResources.spacingXL),
                AppButton(
                  text: 'Send',
                  onPressed: isSubmitting
                      ? null
                      : () {
                          if (_textController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please write your feedback before sending')),
                            );
                            return;
                          }
                          if (_textController.text.trim().length < 10) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Feedback must be at least 10 characters')),
                            );
                            return;
                          }
                          context.read<FeedbackCubit>().submit(
                                type: _selectedType,
                                text: _textController.text.trim(),
                              );
                        },
                  isLoading: isSubmitting,
                  icon: Icons.arrow_forward,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
