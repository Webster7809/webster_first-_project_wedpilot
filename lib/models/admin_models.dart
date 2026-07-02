class AdminVendor {
  final String id;
  final String name;
  final String category;
  final String submitted;
  final int docs;
  final String email;
  final String phone;
  final String location;

  const AdminVendor({
    required this.id,
    required this.name,
    required this.category,
    required this.submitted,
    required this.docs,
    required this.email,
    required this.phone,
    required this.location,
  });
}

class AdminUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final String joined;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.joined,
  });

  bool get isSuspended => status == 'suspended';

  AdminUser copyWith({String? status}) => AdminUser(
        id: id,
        name: name,
        email: email,
        role: role,
        status: status ?? this.status,
        joined: joined,
      );
}

class FlaggedReview {
  final String id;
  final String vendor;
  final int rating;
  final String text;
  final String flagReason;

  const FlaggedReview({
    required this.id,
    required this.vendor,
    required this.rating,
    required this.text,
    required this.flagReason,
  });
}

class FlaggedImage {
  final String id;
  final String vendor;
  final String category;
  final String flagReason;

  const FlaggedImage({
    required this.id,
    required this.vendor,
    required this.category,
    required this.flagReason,
  });
}

class FlaggedMessage {
  final String id;
  final String sender;
  final String recipient;
  final String excerpt;
  final String flagReason;

  const FlaggedMessage({
    required this.id,
    required this.sender,
    required this.recipient,
    required this.excerpt,
    required this.flagReason,
  });
}
