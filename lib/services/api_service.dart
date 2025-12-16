import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../utils/storage_util.dart';
import '../models/api_response.dart';
import '../models/user_model.dart';

/// API 服务封装
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late Dio _dio;
  
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    // 添加拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 添加 token
        final token = await StorageUtil.getString(AppConfig.keyToken);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (error, handler) {
        // 处理错误
        return handler.next(error);
      },
    ));
  }
  
  /// GET 请求
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }
  
  /// POST 请求
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
  
  /// PUT 请求
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
  
  /// DELETE 请求
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
  
  // ==================== 用户相关接口 ====================
  
  /// 登录
  /// [email] 邮箱
  /// [password] 密码
  Future<ApiResponse<UserModel>> login(String email, String password) async {
    try {
      final response = await post(
        '/api/mobile/register/login',  // 实际登录接口地址
        data: {
          'email': email,
          'password': password,
        },
      );
      
      return ApiResponse.fromJson(
        response.data,
        (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      // 处理网络错误
      String errorMsg = '登录失败';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMsg = '网络连接超时，请检查网络';
      } else if (e.type == DioExceptionType.badResponse) {
        // 服务器返回错误
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          errorMsg = data['message'] ?? data['msg'] ?? errorMsg;
        }
      } else if (e.type == DioExceptionType.unknown) {
        errorMsg = '网络连接失败，请检查网络';
      }
      
      return ApiResponse(
        code: e.response?.statusCode ?? -1,
        message: errorMsg,
        data: null,
      );
    } catch (e) {
      return ApiResponse(
        code: -1,
        message: '登录失败: $e',
        data: null,
      );
    }
  }
  
  /// 检查邮箱是否可用
  /// [email] 邮箱
  Future<ApiResponse<dynamic>> checkEmail(String email) async {
    try {
      final response = await get(
        '/api/mobile/register/check_email',
        queryParameters: {'email': email},
      );
      
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      String errorMsg = '检查邮箱失败';
      if (e.type == DioExceptionType.badResponse) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          errorMsg = data['message'] ?? data['msg'] ?? errorMsg;
        }
      }
      
      return ApiResponse(
        code: e.response?.statusCode ?? -1,
        message: errorMsg,
        data: null,
      );
    } catch (e) {
      return ApiResponse(
        code: -1,
        message: '检查邮箱失败: $e',
        data: null,
      );
    }
  }
  
  /// 发送注册验证码
  /// [email] 邮箱
  Future<ApiResponse<dynamic>> sendEmailCode(String email) async {
    try {
      final response = await post(
        '/api/mobile/register/send_code',
        data: {'email': email},
      );
      
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      String errorMsg = '发送验证码失败';
      if (e.type == DioExceptionType.badResponse) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          errorMsg = data['message'] ?? data['msg'] ?? errorMsg;
        }
      }
      
      return ApiResponse(
        code: e.response?.statusCode ?? -1,
        message: errorMsg,
        data: null,
      );
    } catch (e) {
      return ApiResponse(
        code: -1,
        message: '发送验证码失败: $e',
        data: null,
      );
    }
  }
  
  /// 注册
  /// [email] 邮箱
  /// [code] 验证码
  /// [password] 密码
  /// [nickname] 昵称（可选）
  /// [phone] 手机号（可选）
  /// [appid] 应用ID（可选）
  Future<ApiResponse<UserModel>> register({
    required String email,
    required String code,
    required String password,
    String? nickname,
    String? phone,
    String? appid,
  }) async {
    try {
      final data = {
        'email': email,
        'code': code,
        'password': password,
      };
      
      if (nickname != null) data['nickname'] = nickname;
      if (phone != null) data['phone'] = phone;
      if (appid != null) data['appid'] = appid;
      
      final response = await post(
        '/api/mobile/register/register',
        data: data,
      );
      
      return ApiResponse.fromJson(
        response.data,
        (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      String errorMsg = '注册失败';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMsg = '网络连接超时，请检查网络';
      } else if (e.type == DioExceptionType.badResponse) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          errorMsg = data['message'] ?? data['msg'] ?? errorMsg;
        }
      }
      
      return ApiResponse(
        code: e.response?.statusCode ?? -1,
        message: errorMsg,
        data: null,
      );
    } catch (e) {
      return ApiResponse(
        code: -1,
        message: '注册失败: $e',
        data: null,
      );
    }
  }
  
  /// 获取用户信息
  /// [uid] 用户ID（可选，不传则从本地存储获取）
  Future<ApiResponse<UserModel>> getUserInfo({String? uid}) async {
    try {
      // 如果没有传 uid，从本地存储获取
      if (uid == null || uid.isEmpty) {
        uid = await StorageUtil.getString('userId');
      }
      
      final response = await get(
        '/api/mobile/user/info',
        queryParameters: {'uid': uid},
      );
      
      return ApiResponse.fromJson(
        response.data,
        (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      String errorMsg = '获取用户信息失败';
      if (e.type == DioExceptionType.badResponse) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          errorMsg = data['message'] ?? data['msg'] ?? errorMsg;
        }
      }
      
      return ApiResponse(
        code: e.response?.statusCode ?? -1,
        message: errorMsg,
        data: null,
      );
    } catch (e) {
      return ApiResponse(
        code: -1,
        message: '获取用户信息失败: $e',
        data: null,
      );
    }
  }
  
  /// 修改用户信息
  Future<ApiResponse<dynamic>> updateUserInfo(Map<String, dynamic> data) async {
    try {
      final response = await post('/api/user/update', data: data);
      
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      String errorMsg = '修改用户信息失败';
      if (e.type == DioExceptionType.badResponse) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          errorMsg = data['message'] ?? data['msg'] ?? errorMsg;
        }
      }
      
      return ApiResponse(
        code: e.response?.statusCode ?? -1,
        message: errorMsg,
        data: null,
      );
    } catch (e) {
      return ApiResponse(
        code: -1,
        message: '修改用户信息失败: $e',
        data: null,
      );
    }
  }
  
  /// 获取我的邀请记录
  Future<ApiResponse<dynamic>> getInviteList() async {
    try {
      final response = await get('/api/user/invite-list');
      
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      String errorMsg = '获取邀请记录失败';
      if (e.type == DioExceptionType.badResponse) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          errorMsg = data['message'] ?? data['msg'] ?? errorMsg;
        }
      }
      
      return ApiResponse(
        code: e.response?.statusCode ?? -1,
        message: errorMsg,
        data: null,
      );
    } catch (e) {
      return ApiResponse(
        code: -1,
        message: '获取邀请记录失败: $e',
        data: null,
      );
    }
  }
  
  /// 获取邀请统计
  Future<ApiResponse<dynamic>> getInviteStats() async {
    try {
      final response = await get('/api/user/invite-stats');
      
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      String errorMsg = '获取邀请统计失败';
      if (e.type == DioExceptionType.badResponse) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          errorMsg = data['message'] ?? data['msg'] ?? errorMsg;
        }
      }
      
      return ApiResponse(
        code: e.response?.statusCode ?? -1,
        message: errorMsg,
        data: null,
      );
    } catch (e) {
      return ApiResponse(
        code: -1,
        message: '获取邀请统计失败: $e',
        data: null,
      );
    }
  }
}







