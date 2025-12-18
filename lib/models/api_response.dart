/// API 统一响应模型
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;
  
  ApiResponse({
    required this.code,
    required this.message,
    this.data,
  });
  
  /// 从 JSON 创建
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      code: json['code'] ?? json['status'] ?? 0,
      message: json['message'] ?? json['msg'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
    );
  }
  
  /// 是否成功
  bool get isSuccess => code == 200 || code == 0 || code == 1;
  
  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'data': data,
    };
  }
}










