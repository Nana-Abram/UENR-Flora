// lib/core/learn_content.dart
import 'package:flutter/material.dart';
import 'theme.dart';
import '../models/learn_article.dart';

/// Static editorial content for the Learn section's article-detail pages.
/// Shared by the Learn screen's grids (which link into these articles) and
/// the article-detail screen itself.
const List<LearnArticle> kLearnArticles = [
  LearnArticle(
    id: 'bird-species',
    heroAsset: 'assets/images/hero_carousel/hero_02.jpg',
    category: 'Wildlife',
    categoryColor: Color(0xFF993556),
    minutes: '4 min read',
    date: 'Jun 15, 2026',
    title: 'How UENR Forest Supports 200+ Bird Species',
    paragraphs: [
      "Ghana's remarkable biodiversity is both a natural heritage and a "
          "scientific resource. The University of Energy and Natural "
          "Resources sits within one of West Africa's most biodiverse "
          'transitional zones, making the campus a living laboratory for '
          'environmental science students and researchers.',
      'Through systematic botanical surveys and citizen science '
          'initiatives, UENR has documented a growing catalogue of plant '
          'species on campus alone — each representing a thread in the '
          'ecological fabric of the Brong-Ahafo region. These species '
          'range from towering hardwoods like Teak and Shea to understory '
          'medicinal herbs like Moringa and Aloe Vera.',
      'Conservation education like UENR Flora transforms passive '
          'observers into active stewards. When students can name and '
          'understand the ecological roles of the trees they walk past '
          'daily, they are far more likely to advocate for their '
          'protection — both on campus and in their communities.',
    ],
    insightTitle: 'Key Insight',
    insightBody:
        'One mature tree can absorb approximately 22 kg of carbon '
        'dioxide annually — equivalent to driving a car 88 kilometres. '
        "UENR's campus forest, with hundreds of mature trees, sequesters "
        'several tonnes of carbon every year.',
  ),
  LearnArticle(
    id: 'carbon-sequestration',
    heroAsset: 'assets/images/hero_carousel/hero_05.jpg',
    category: 'Climate',
    categoryColor: Color(0xFF185FA5),
    minutes: '6 min read',
    date: 'Jun 10, 2026',
    title: 'Carbon Sequestration in Ghanaian Tropical Forests',
    paragraphs: [
      'Tropical forests are among the most effective natural carbon '
          "sinks on the planet, and Ghana's transitional forest zones — "
          "including the vegetation found around UENR's Sunyani campus — "
          "play a quiet but significant role in the country's climate "
          'resilience.',
      'Photosynthesis allows mature trees to draw down atmospheric '
          'carbon dioxide and store it in woody biomass and soil for '
          'decades. Mixed canopy structures, like those found across the '
          'Brong-Ahafo region, tend to sequester carbon more effectively '
          'than single-species plantations because of their layered root '
          'systems and diverse leaf cover.',
      'Protecting and expanding tree cover on campus and across the '
          'wider region is one of the most direct, low-cost actions '
          'available for mitigating climate change locally — which is '
          'part of why UENR Flora exists: helping people recognise the '
          'trees around them is a first step toward valuing and '
          'protecting them.',
    ],
  ),
  LearnArticle(
    id: 'traditional-knowledge',
    heroAsset: 'assets/images/hero_carousel/hero_09.jpg',
    category: 'Culture & ecology',
    categoryColor: kAccent,
    minutes: '5 min read',
    date: 'Jun 3, 2026',
    title: 'Traditional Plant Knowledge of the Brong-Ahafo Region',
    paragraphs: [
      'Long before formal botanical classification reached Ghana, '
          'communities across the Brong-Ahafo region had already '
          'developed detailed, generational knowledge of the plants '
          'growing around them — which ones healed, which ones fed, and '
          'which ones held cultural significance.',
      'In Twi-speaking communities, many trees and herbs carry names '
          'that describe their use or character directly, embedding '
          'practical knowledge into everyday language. This oral '
          'tradition of plant knowledge has historically been passed '
          'down through elders, healers, and farmers rather than '
          'written texts.',
      'Digital tools like UENR Flora complement — rather than replace — '
          'this traditional knowledge, offering a way to cross-reference '
          'local names and uses with documented botanical data, helping '
          'preserve it for future generations of students and '
          'researchers.',
    ],
  ),
  LearnArticle(
    id: 'neem-agriculture',
    heroAsset: 'assets/images/hero_carousel/hero_12.jpg',
    category: 'Agriculture',
    categoryColor: kGreen,
    minutes: '3 min read',
    date: 'May 28, 2026',
    title: 'The Role of Neem in Sustainable Organic Agriculture',
    paragraphs: [
      'Neem (Azadirachta indica) is one of the most widely used plants '
          'in organic farming across West Africa, valued for properties '
          'that go well beyond its shade-giving canopy.',
      'Extracts from neem leaves and seeds are commonly used as a '
          'natural pest deterrent, offering smallholder farmers an '
          'alternative to synthetic pesticides. Its fast growth and '
          'tolerance of poor soils have also made it a popular choice '
          'for reforestation and erosion control projects.',
      'For students studying sustainable agriculture, Neem is a useful '
          'case study in how a single, common species can support food '
          'security, soil health, and biodiversity goals at the same '
          'time.',
    ],
  ),
  LearnArticle(
    id: 'shea-butter',
    heroAsset: 'assets/images/hero_carousel/hero_14.jpg',
    category: 'Economy',
    categoryColor: Color(0xFF8A6D3B),
    minutes: '7 min read',
    date: 'May 20, 2026',
    title: 'Shea Butter: Linking Biodiversity to Rural Livelihoods',
    paragraphs: [
      "The shea tree (Vitellaria paradoxa) is one of Ghana's most "
          'economically important indigenous species, supporting '
          'livelihoods across the northern and transitional savanna '
          'zones long before shea butter became a global cosmetics '
          'export.',
      'Shea trees are rarely cultivated in plantations — most shea '
          'butter is harvested from naturally occurring, often '
          'centuries-old trees left standing within farmland, making '
          'the industry unusually dependent on preserving existing '
          'biodiversity rather than clearing it.',
      "This relationship between conservation and livelihood is a "
          'recurring theme in Ghanaian botany: protecting a species’ '
          'natural habitat and supporting the rural economy can be the '
          'same action, not competing priorities.',
    ],
  ),
  LearnArticle(
    id: 'bamboo-climate',
    heroAsset: 'assets/images/hero_carousel/hero_16.jpg',
    category: 'Climate',
    categoryColor: Color(0xFF185FA5),
    minutes: '4 min read',
    date: 'May 14, 2026',
    title: 'Bamboo as a Climate Solution in West Africa',
    paragraphs: [
      'Bamboo is technically a grass, not a tree, but it is '
          'increasingly recognised across West Africa as one of the '
          'fastest and most practical tools for climate mitigation and '
          'land restoration.',
      'Its rapid growth cycle means bamboo can be harvested repeatedly '
          'without replanting, unlike timber trees that take decades to '
          'mature — making it attractive for both construction '
          'materials and reforestation projects on degraded land.',
      'As interest in climate-resilient agriculture grows across '
          'Ghana, bamboo is worth watching as a species that bridges '
          'environmental and economic priorities, much like shea and '
          'neem already do.',
    ],
  ),
];

LearnArticle learnArticleById(String id) =>
    kLearnArticles.firstWhere((a) => a.id == id, orElse: () => kLearnArticles.first);
