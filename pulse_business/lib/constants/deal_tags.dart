import 'package:flutter/material.dart';
class DealTag {
  final String id;
  final String label;
  final String emoji;
  final Color color;

  const DealTag({
    required this.id,
    required this.label,
    required this.emoji,
    required this.color,
  });
}

class DealTags {
  static const List<DealTag> all = [
    DealTag(id: 'new_item',       label: 'New Item',       emoji: '🆕', color: Color(0xFF4CAF50)),
    DealTag(id: 'event_special',  label: 'Event Special',  emoji: '🎉', color: Color(0xFFE91E63)),
    DealTag(id: 'flash_sale',     label: 'Flash Sale',     emoji: '⚡', color: Color(0xFFFF9800)),
    DealTag(id: 'seasonal',       label: 'Seasonal',       emoji: '🍂', color: Color(0xFF795548)),
    DealTag(id: 'limited_time',   label: 'Limited Time',   emoji: '⏰', color: Color(0xFFF44336)),
    DealTag(id: 'grand_opening',  label: 'Grand Opening',  emoji: '🎊', color: Color(0xFF9C27B0)),
    DealTag(id: 'happy_hour',     label: 'Happy Hour',     emoji: '🍻', color: Color(0xFFFF5722)),
    DealTag(id: 'lunch_special',  label: 'Lunch Special',  emoji: '🌮', color: Color(0xFFFF6F00)),
    DealTag(id: 'combo',          label: 'Combo Deal',     emoji: '🍱', color: Color(0xFF00BCD4)),
    DealTag(id: 'bogo',           label: 'BOGO',           emoji: '🎁', color: Color(0xFF8BC34A)),
    DealTag(id: 'game_day',       label: 'Game Day',       emoji: '⚽', color: Color(0xFF3F51B5)),
    DealTag(id: 'staff_pick',     label: 'Staff Pick',     emoji: '⭐', color: Color(0xFFFFC107)),
  ];

  static DealTag? getById(String id) =>
      all.where((t) => t.id == id).firstOrNull;
}