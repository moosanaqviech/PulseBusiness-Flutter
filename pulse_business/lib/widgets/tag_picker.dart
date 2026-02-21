// pulse_business/lib/widgets/tag_picker.dart

import 'package:flutter/material.dart';
import '../constants/deal_tags.dart';
import '../utils/theme.dart';

class TagPicker extends StatelessWidget {
  final List<String> selectedTags;
  final ValueChanged<List<String>> onChanged;
  final int maxTags;

  const TagPicker({
    super.key,
    required this.selectedTags,
    required this.onChanged,
    this.maxTags = 3,
  });

  void _toggleTag(BuildContext context, String tagId) {
    final updated = List<String>.from(selectedTags);

    if (updated.contains(tagId)) {
      updated.remove(tagId);
    } else {
      if (updated.length >= maxTags) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maximum $maxTags tags allowed per deal'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      updated.add(tagId);
    }

    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Icon(Icons.label_outline, size: 20, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(
              'Add Tags',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(optional)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textHint,
              ),
            ),
            const Spacer(),
            // Counter
            if (selectedTags.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${selectedTags.length}/$maxTags',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Help customers find your deal faster',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textHint,
          ),
        ),
        const SizedBox(height: 12),

        // Tag chips - horizontal scroll
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: DealTags.all.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final tag = DealTags.all[index];
              final isSelected = selectedTags.contains(tag.id);
              return _TagChip(
                tag: tag,
                isSelected: isSelected,
                onTap: () => _toggleTag(context, tag.id),
              );
            },
          ),
        ),

        // Selected tags summary
        if (selectedTags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, 
                  size: 16, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tags: ${selectedTags.map((id) => DealTags.getById(id)?.label ?? id).join(', ')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final DealTag tag;
  final bool isSelected;
  final VoidCallback onTap;

  const _TagChip({
    required this.tag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? tag.color.withOpacity(0.15) 
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? tag.color 
                : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tag.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              tag.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? tag.color : AppTheme.textSecondary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(Icons.close, size: 14, color: tag.color),
            ],
          ],
        ),
      ),
    );
  }
}