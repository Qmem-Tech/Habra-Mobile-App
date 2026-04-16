import 'package:flutter_test/flutter_test.dart';
import 'package:habra_mobile_app/core/error/exceptions.dart' as app;
import 'package:habra_mobile_app/core/supabase/supabase_failure_mapper.dart';

void main() {
  group('SupabaseFailureMapper fallback auth mapping', () {
    test('maps ApiException 10 message to actionable Google guidance', () {
      try {
        SupabaseFailureMapper.throwFromError(
          'com.google.android.gms.common.api.ApiException: 10',
        );
        fail('Expected throwFromError to throw.');
      } catch (e) {
        expect(e, isA<app.ServerException>());
        final server = e as app.ServerException;
        expect(server.message, contains('Google Sign-In error (code 10)'));
      }
    });

    test('maps shorthand m4.b: 10 trace to Google OAuth guidance', () {
      try {
        SupabaseFailureMapper.throwFromError('m4.b: 10');
        fail('Expected throwFromError to throw.');
      } catch (e) {
        expect(e, isA<app.ServerException>());
        final server = e as app.ServerException;
        expect(server.message, contains('Google Sign-In failed'));
      }
    });
  });
}
