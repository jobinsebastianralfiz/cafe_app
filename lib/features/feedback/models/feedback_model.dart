import 'package:cloud_firestore/cloud_firestore.dart';

/// Review Model - User reviews for menu items
class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhoto;
  final String menuItemId;
  final String menuItemName;
  final String? orderId;
  final double rating;
  final String? comment;
  final List<String> photos;
  final bool isVerifiedPurchase;
  final int helpfulCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.menuItemId,
    required this.menuItemName,
    this.orderId,
    required this.rating,
    this.comment,
    this.photos = const [],
    this.isVerifiedPurchase = false,
    this.helpfulCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userPhoto: data['userPhoto'],
      menuItemId: data['menuItemId'] ?? '',
      menuItemName: data['menuItemName'] ?? '',
      orderId: data['orderId'],
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'],
      photos: List<String>.from(data['photos'] ?? []),
      isVerifiedPurchase: data['isVerifiedPurchase'] ?? false,
      helpfulCount: data['helpfulCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'menuItemId': menuItemId,
      'menuItemName': menuItemName,
      'orderId': orderId,
      'rating': rating,
      'comment': comment,
      'photos': photos,
      'isVerifiedPurchase': isVerifiedPurchase,
      'helpfulCount': helpfulCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 30) {
      return '${difference.inDays ~/ 30}mo ago';
    } else if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }

  ReviewModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhoto,
    String? menuItemId,
    String? menuItemName,
    String? orderId,
    double? rating,
    String? comment,
    List<String>? photos,
    bool? isVerifiedPurchase,
    int? helpfulCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhoto: userPhoto ?? this.userPhoto,
      menuItemId: menuItemId ?? this.menuItemId,
      menuItemName: menuItemName ?? this.menuItemName,
      orderId: orderId ?? this.orderId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      photos: photos ?? this.photos,
      isVerifiedPurchase: isVerifiedPurchase ?? this.isVerifiedPurchase,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Order Feedback Model - Overall order feedback
class OrderFeedbackModel {
  final String id;
  final String orderId;
  final String orderNumber;
  final String userId;
  final String userName;
  final double overallRating;
  final double foodRating;
  final double serviceRating;
  final double deliveryRating;
  final String? comment;
  final List<String> tags; // quick delivery, great taste, etc.
  final bool wouldRecommend;
  final DateTime createdAt;

  OrderFeedbackModel({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.userId,
    required this.userName,
    required this.overallRating,
    this.foodRating = 0,
    this.serviceRating = 0,
    this.deliveryRating = 0,
    this.comment,
    this.tags = const [],
    this.wouldRecommend = true,
    required this.createdAt,
  });

  factory OrderFeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderFeedbackModel(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      orderNumber: data['orderNumber'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      overallRating: (data['overallRating'] ?? 0).toDouble(),
      foodRating: (data['foodRating'] ?? 0).toDouble(),
      serviceRating: (data['serviceRating'] ?? 0).toDouble(),
      deliveryRating: (data['deliveryRating'] ?? 0).toDouble(),
      comment: data['comment'],
      tags: List<String>.from(data['tags'] ?? []),
      wouldRecommend: data['wouldRecommend'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'orderNumber': orderNumber,
      'userId': userId,
      'userName': userName,
      'overallRating': overallRating,
      'foodRating': foodRating,
      'serviceRating': serviceRating,
      'deliveryRating': deliveryRating,
      'comment': comment,
      'tags': tags,
      'wouldRecommend': wouldRecommend,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Feedback Tags - Common feedback tags
class FeedbackTags {
  static const List<String> positiveTags = [
    'Quick Delivery',
    'Great Taste',
    'Fresh Ingredients',
    'Good Portions',
    'Value for Money',
    'Friendly Service',
    'Well Packed',
    'Hot Food',
    'On Time',
  ];

  static const List<String> negativeTags = [
    'Slow Delivery',
    'Cold Food',
    'Wrong Order',
    'Missing Items',
    'Poor Packaging',
    'Small Portions',
    'Not Fresh',
    'Rude Service',
    'Late Delivery',
  ];
}
