import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'error_response_dto.g.dart';

@immutable
@JsonSerializable()
class ErrorResponseDto {

  const ErrorResponseDto({
    required this.code,
    required this.message,
    this.details,
  });

  factory ErrorResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ErrorResponseDtoFromJson(json);
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  Map<String, dynamic> toJson() => _$ErrorResponseDtoToJson(this);
}