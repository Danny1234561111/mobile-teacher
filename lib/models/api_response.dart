class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int? statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, 
    T Function(dynamic) fromJsonT
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? true,
      message: json['message'] ?? '',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      statusCode: json['statusCode'],
    );
  }
}