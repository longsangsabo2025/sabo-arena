// Admin Guide System Models
// Dynamic, flexible guide system that auto-updates with app changes

import 'package:flutter/material.dart';

/// Guide category for organization
enum GuideCategory {
  gettingStarted,
  clubManagement,
  tournamentManagement,
  userManagement,
  notifications,
  analytics,
  advanced,
}

/// Guide step type
enum GuideStepType { info, action, tip, warning, success }

/// Single guide step in a tutorial
class GuideStep {
  final String title;
  final String description;
  final GuideStepType type;
  final String? imageUrl;
  final IconData? icon;
  final String? targetRoute; // Route to navigate for this step
  final Map<String, dynamic>? actionData; // Data needed for action
  final List<String>? keyPoints; // Bullet points
  final String? videoUrl; // Tutorial video URL

  const GuideStep({
    required this.title,
    required this.description,
    this.type = GuideStepType.info,
    this.imageUrl,
    this.icon,
    this.targetRoute,
    this.actionData,
    this.keyPoints,
    this.videoUrl,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'type': type.toString(),
        'imageUrl': imageUrl,
        'targetRoute': targetRoute,
        'actionData': actionData,
        'keyPoints': keyPoints,
        'videoUrl': videoUrl,
      };

  factory GuideStep.fromJson(Map<String, dynamic> json) => GuideStep(
        title: json['title'],
        description: json['description'],
        type: GuideStepType.values.firstWhere(
          (e) => e.toString() == json['type'],
          orElse: () => GuideStepType.info,
        ),
        imageUrl: json['imageUrl'],
        targetRoute: json['targetRoute'],
        actionData: json['actionData'],
        keyPoints: json['keyPoints'] != null
            ? List<String>.from(json['keyPoints'])
            : null,
        videoUrl: json['videoUrl'],
      );
}

/// Complete guide/tutorial
class AdminGuide {
  final String id;
  final String title;
  final String description;
  final GuideCategory category;
  final List<GuideStep> steps;
  final int estimatedMinutes; // Time to complete
  final List<String> tags; // Searchable tags
  final int priority; // Display order (0 = highest)
  final bool isNew; // Show "NEW" badge
  final String version; // App version when guide was updated
  final DateTime lastUpdated;

  const AdminGuide({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.steps,
    this.estimatedMinutes = 5,
    this.tags = const [],
    this.priority = 999,
    this.isNew = false,
    required this.version,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.toString(),
        'steps': steps.map((s) => s.toJson()).toList(),
        'estimatedMinutes': estimatedMinutes,
        'tags': tags,
        'priority': priority,
        'isNew': isNew,
        'version': version,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory AdminGuide.fromJson(Map<String, dynamic> json) => AdminGuide(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        category: GuideCategory.values.firstWhere(
          (e) => e.toString() == json['category'],
          orElse: () => GuideCategory.gettingStarted,
        ),
        steps:
            (json['steps'] as List).map((s) => GuideStep.fromJson(s)).toList(),
        estimatedMinutes: json['estimatedMinutes'] ?? 5,
        tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
        priority: json['priority'] ?? 999,
        isNew: json['isNew'] ?? false,
        version: json['version'],
        lastUpdated: DateTime.parse(json['lastUpdated']),
      );
}

/// User's progress in guides
class GuideProgress {
  final String userId;
  final String guideId;
  final int currentStep; // 0-based index
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime lastAccessedAt;

  const GuideProgress({
    required this.userId,
    required this.guideId,
    this.currentStep = 0,
    this.isCompleted = false,
    this.completedAt,
    required this.lastAccessedAt,
  });

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'guide_id': guideId,
        'current_step': currentStep,
        'is_completed': isCompleted,
        'completed_at': completedAt?.toIso8601String(),
        'last_accessed_at': lastAccessedAt.toIso8601String(),
      };

  factory GuideProgress.fromJson(Map<String, dynamic> json) => GuideProgress(
        userId: json['user_id'],
        guideId: json['guide_id'],
        currentStep: json['current_step'] ?? 0,
        isCompleted: json['is_completed'] ?? false,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'])
            : null,
        lastAccessedAt: DateTime.parse(json['last_accessed_at']),
      );
}

/// Quick help tooltip
class QuickHelp {
  final String screenId; // Screen identifier
  final String elementId; // Specific element on screen
  final String title;
  final String description;
  final String? relatedGuideId; // Link to full guide

  const QuickHelp({
    required this.screenId,
    required this.elementId,
    required this.title,
    required this.description,
    this.relatedGuideId,
  });

  Map<String, dynamic> toJson() => {
        'screen_id': screenId,
        'element_id': elementId,
        'title': title,
        'description': description,
        'related_guide_id': relatedGuideId,
      };

  factory QuickHelp.fromJson(Map<String, dynamic> json) => QuickHelp(
        screenId: json['screen_id'],
        elementId: json['element_id'],
        title: json['title'],
        description: json['description'],
        relatedGuideId: json['related_guide_id'],
      );
}
