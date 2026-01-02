/// Represents a support ticket with message thread functionality
class SupportTicket {
  final String id;
  final String userId;
  final String subject;
  final String category;
  final String priority;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TicketMessage> messages;
  final bool hasUnreadUpdates;

  const SupportTicket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
    this.hasUnreadUpdates = false,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subject: json['subject'] as String,
      category: json['category'] as String,
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      messages: json['messages'] != null
          ? (json['messages'] as List)
              .map((m) => TicketMessage.fromJson(m as Map<String, dynamic>))
              .toList()
          : [],
      hasUnreadUpdates: json['has_unread_updates'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subject': subject,
      'category': category,
      'priority': priority,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
      'has_unread_updates': hasUnreadUpdates,
    };
  }

  /// Check if ticket is open
  bool get isOpen => status == 'open';

  /// Check if ticket is in progress
  bool get isInProgress => status == 'in_progress';

  /// Check if ticket is awaiting response
  bool get isAwaitingResponse => status == 'awaiting_response';

  /// Check if ticket is resolved
  bool get isResolved => status == 'resolved';

  /// Check if ticket is closed
  bool get isClosed => status == 'closed';

  /// Check if user can reply (ticket not closed)
  bool get canReply => !isClosed && !isResolved;

  /// Get status display name
  String get statusDisplayName {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'awaiting_response':
        return 'Awaiting Response';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  /// Get category display name
  String get categoryDisplayName {
    switch (category) {
      case 'billing':
        return 'Billing Issue';
      case 'technical':
        return 'Technical Problem';
      case 'feature_request':
        return 'Feature Request';
      case 'bug_report':
        return 'Bug Report';
      case 'account':
        return 'Account Issue';
      case 'other':
        return 'Other';
      default:
        return category;
    }
  }

  /// Get priority display name
  String get priorityDisplayName {
    switch (priority) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'urgent':
        return 'Urgent';
      default:
        return priority;
    }
  }

  /// Get ticket number for display (e.g., #TKT-001234)
  String get ticketNumber => '#TKT-${id.substring(0, 6).toUpperCase()}';

  /// Get last message preview
  String? get lastMessagePreview {
    if (messages.isEmpty) return null;
    final lastMessage = messages.last;
    final preview = lastMessage.content.length > 50
        ? '${lastMessage.content.substring(0, 50)}...'
        : lastMessage.content;
    return preview;
  }

  /// Create a copy with updated fields
  SupportTicket copyWith({
    String? id,
    String? userId,
    String? subject,
    String? category,
    String? priority,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TicketMessage>? messages,
    bool? hasUnreadUpdates,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subject: subject ?? this.subject,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      hasUnreadUpdates: hasUnreadUpdates ?? this.hasUnreadUpdates,
    );
  }
}

/// Represents a message in a support ticket thread
class TicketMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String senderType; // 'user' or 'support'
  final String senderName;
  final String content;
  final List<String>? attachments;
  final DateTime createdAt;
  final bool isRead;

  const TicketMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderType,
    required this.senderName,
    required this.content,
    this.attachments,
    required this.createdAt,
    this.isRead = false,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      senderId: json['sender_id'] as String,
      senderType: json['sender_type'] as String,
      senderName: json['sender_name'] as String? ?? 'Unknown',
      content: json['content'] as String,
      attachments: json['attachments'] != null
          ? (json['attachments'] as List).cast<String>()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'sender_id': senderId,
      'sender_type': senderType,
      'sender_name': senderName,
      'content': content,
      'attachments': attachments,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }

  /// Check if message is from user
  bool get isFromUser => senderType == 'user';

  /// Check if message is from support
  bool get isFromSupport => senderType == 'support';

  /// Get formatted time
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Create a copy with updated fields
  TicketMessage copyWith({
    String? id,
    String? ticketId,
    String? senderId,
    String? senderType,
    String? senderName,
    String? content,
    List<String>? attachments,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return TicketMessage(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      senderId: senderId ?? this.senderId,
      senderType: senderType ?? this.senderType,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// Support ticket categories
enum TicketCategory {
  billing('billing', 'Billing Issue'),
  technical('technical', 'Technical Problem'),
  featureRequest('feature_request', 'Feature Request'),
  bugReport('bug_report', 'Bug Report'),
  account('account', 'Account Issue'),
  other('other', 'Other');

  final String value;
  final String displayName;

  const TicketCategory(this.value, this.displayName);
}

/// Support ticket priorities
enum TicketPriority {
  low('low', 'Low'),
  medium('medium', 'Medium'),
  high('high', 'High'),
  urgent('urgent', 'Urgent');

  final String value;
  final String displayName;

  const TicketPriority(this.value, this.displayName);
}
