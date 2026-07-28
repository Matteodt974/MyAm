import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'digestive_entry.dart';

class DigestiveJournalRepository {
  DigestiveJournalRepository(this._dio);

  final Dio _dio;

  /// Enregistre une entree du journal digestif.
  ///
  /// Les dates partent toujours en UTC : le backend les stocke en [Instant].
  Future<DigestiveEntry> create({
    required int bristolType,
    required DateTime occurredAt,
    String? notes,
  }) async {
    final trimmedNotes = notes?.trim();

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.digestiveJournal,
        data: {
          'bristolType': bristolType,
          'occurredAt': occurredAt.toUtc().toIso8601String(),
          if (trimmedNotes != null && trimmedNotes.isNotEmpty)
            'notes': trimmedNotes,
        },
      );

      return DigestiveEntry.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Liste les entrees, de la plus recente a la plus ancienne.
  Future<List<DigestiveEntry>> list({DateTime? since}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.digestiveJournal,
        queryParameters: {
          if (since != null) 'since': since.toUtc().toIso8601String(),
        },
      );

      return (response.data ?? const <dynamic>[])
          .cast<Map<String, dynamic>>()
          .map(DigestiveEntry.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final digestiveJournalRepositoryProvider = Provider<DigestiveJournalRepository>(
  (ref) => DigestiveJournalRepository(ref.watch(dioProvider)),
);
