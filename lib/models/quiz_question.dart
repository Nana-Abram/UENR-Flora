// lib/models/quiz_question.dart
import 'package:flutter/material.dart';

class QuizQuestion {
  final Color cardColor;
  final Color iconColor;
  final IconData icon;
  final String answer;       // exact correct answer string
  final List<String> options; // exactly 4; will be shuffled at runtime
  final String funFact;

  const QuizQuestion({
    required this.cardColor,
    required this.iconColor,
    required this.icon,
    required this.answer,
    required this.options,
    required this.funFact,
  });
}

// ─────────────────────────────────────────────────────────────
// Hard-coded question bank — expand as more species are added
// ─────────────────────────────────────────────────────────────
const List<QuizQuestion> kQuizBank = [
  QuizQuestion(
    cardColor: Color(0xFFD8EDDA),
    iconColor: Color(0xFF1A3C2D),
    icon: Icons.eco_outlined,
    answer: 'Neem Tree',
    options: ['Weeping Fig', 'Neem Tree', 'Teak', 'Flamboyant Tree'],
    funFact: 'Neem (Azadirachta indica) is called the "village pharmacy" — '
        'its leaves, bark, and seeds are used in Ghanaian traditional '
        'medicine and as a natural pesticide.',
  ),
  QuizQuestion(
    cardColor: Color(0xFFFAEEDA),
    iconColor: Color(0xFFBA7517),
    icon: Icons.park_outlined,
    answer: 'Flamboyant Tree',
    options: ['African Tulip', 'Flamboyant Tree', 'Coconut Palm', 'Mango Tree'],
    funFact: 'Delonix regia produces spectacular flame-red flowers and is '
        'native to Madagascar, yet has become one of the most iconic '
        'ornamental trees across West African university campuses.',
  ),
  QuizQuestion(
    cardColor: Color(0xFFFAC775),
    iconColor: Color(0xFF633806),
    icon: Icons.yard_outlined,
    answer: 'Mango Tree',
    options: ['Papaya', 'Mango Tree', 'Breadfruit', 'Cashew Tree'],
    funFact: 'Mangifera indica trees can live over 300 years. The '
        'Brong-Ahafo Region — UENR\'s home — is one of Ghana\'s '
        'primary mango-producing zones.',
  ),
  QuizQuestion(
    cardColor: Color(0xFFE1F5EE),
    iconColor: Color(0xFF0F6E56),
    icon: Icons.forest_outlined,
    answer: 'Weeping Fig',
    options: ['Weeping Fig', 'Teak', 'Coconut Palm', 'Breadfruit'],
    funFact: 'Ficus benjamina is one of the most effective trees for air '
        'purification, absorbing benzene and xylene from the surrounding '
        'atmosphere.',
  ),
];
