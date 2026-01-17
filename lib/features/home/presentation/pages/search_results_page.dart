import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/repositories/search_repository.dart';
import '../widgets/event_card.dart';
import '../widgets/business_card.dart';
import '../widgets/job_card.dart';

class SearchResultsPage extends StatelessWidget {
  final SearchResults results;
  final String query;
  final SearchCategory category;

  const SearchResultsPage({
    super.key,
    required this.results,
    required this.query,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildResultsHeader(),
        Expanded(
          child: _buildResultsContent(),
        ),
      ],
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.backgroundGrey)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${results.totalCount} Results found.',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          DropdownButton<String>(
            value: 'Relevance',
            items: const ['Relevance', 'Distance', 'Rating'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) {
              // TODO: Implement sort
            },
            underline: Container(),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsContent() {
    if (category == SearchCategory.all) {
      return _buildAllResults();
    } else if (category == SearchCategory.events) {
      return _buildEventsResults();
    } else if (category == SearchCategory.business) {
      return _buildBusinessesResults();
    } else {
      return _buildJobsResults();
    }
  }

  Widget _buildAllResults() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (results.events.isNotEmpty) ...[
          _buildSectionTitle('Events'),
          const SizedBox(height: 12),
          ...results.events.map((event) => EventCard(event: event)),
          const SizedBox(height: 24),
        ],
        if (results.businesses.isNotEmpty) ...[
          _buildSectionTitle('Businesses'),
          const SizedBox(height: 12),
          ...results.businesses.map((business) => BusinessCard(business: business)),
          const SizedBox(height: 24),
        ],
        if (results.jobs.isNotEmpty) ...[
          _buildSectionTitle('Jobs'),
          const SizedBox(height: 12),
          ...results.jobs.map((job) => JobCard(job: job)),
        ],
      ],
    );
  }

  Widget _buildEventsResults() {
    if (results.events.isEmpty) {
      return _buildEmptyState('No events found');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      children: results.events.map((event) => EventCard(event: event)).toList(),
    );
  }

  Widget _buildBusinessesResults() {
    if (results.businesses.isEmpty) {
      return _buildEmptyState('No businesses found');
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: results.businesses.length,
      itemBuilder: (context, index) {
        final business = results.businesses[index];
        return _buildBusinessGridItem(business);
      },
    );
  }

  Widget _buildJobsResults() {
    if (results.jobs.isEmpty) {
      return _buildEmptyState('No jobs found');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: results.jobs.map((job) => JobCard(job: job)).toList(),
    );
  }

  Widget _buildBusinessGridItem(dynamic business) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.backgroundGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              business.imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  color: AppColors.backgroundGrey,
                  child: const Icon(Icons.business, size: 32),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        business.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (business.isVerified)
                      const Icon(Icons.verified, size: 14, color: AppColors.brandPrimary),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      business.rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      ' (${business.reviewCount})',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${business.category} • ${business.distance.toStringAsFixed(1)} mi',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                if (business.status != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    business.status!,
                    style: const TextStyle(fontSize: 11, color: AppColors.brandPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
