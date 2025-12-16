/// 用户模型
class UserModel {
  final String? id;
  final String? username;
  final String? email;
  final String? phone;
  final String? avatar;
  final double? balance;
  final String? token;
  
  UserModel({
    this.id,
    this.username,
    this.email,
    this.phone,
    this.avatar,
    this.balance,
    this.token,
  });
  
  // 从 JSON 创建
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString(),
      username: json['username']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      avatar: json['avatar']?.toString(),
      balance: json['balance'] != null ? double.tryParse(json['balance'].toString()) : null,
      token: json['token']?.toString(),
    );
  }
  
  // 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'balance': balance,
      'token': token,
    };
  }
  
  // 复制并更新
  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? phone,
    String? avatar,
    double? balance,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      balance: balance ?? this.balance,
      token: token ?? this.token,
    );
  }
}







