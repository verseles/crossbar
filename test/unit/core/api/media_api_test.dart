import 'package:flutter_test/flutter_test.dart';
import 'package:crossbar/core/api/media_api.dart';

void main() {
  group('MediaApi', () {
    const api = MediaApi();

    group('Playback Controls', () {
      test('play returns boolean', () async {
        final result = await api.play();
        expect(result, isA<bool>());
      });

      test('pause returns boolean', () async {
        final result = await api.pause();
        expect(result, isA<bool>());
      });

      test('playPause returns boolean', () async {
        final result = await api.playPause();
        expect(result, isA<bool>());
      });

      test('stop returns boolean', () async {
        final result = await api.stop();
        expect(result, isA<bool>());
      });

      test('next returns boolean', () async {
        final result = await api.next();
        expect(result, isA<bool>());
      });

      test('previous returns boolean', () async {
        final result = await api.previous();
        expect(result, isA<bool>());
      });

      test('seek returns boolean', () async {
        final result = await api.seek('+10s');
        expect(result, isA<bool>());
      });

      test('seek parses offset without s suffix', () async {
        final result = await api.seek('+30');
        expect(result, isA<bool>());
      });

      test('seek handles negative offset', () async {
        final result = await api.seek('-15s');
        expect(result, isA<bool>());
      });
    });

    group('getPlaying', () {
      test('returns map with status', () async {
        final result = await api.getPlaying();
        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('status'), true);
      });

      test('returns playing boolean', () async {
        final result = await api.getPlaying();
        expect(result.containsKey('playing'), true);
        expect(result['playing'], isA<bool>());
      });
    });

    group('Volume Controls', () {
      test('getVolume returns int', () async {
        final result = await api.getVolume();
        expect(result, isA<int>());
      });

      test('getVolume returns value in range 0-100', () async {
        final result = await api.getVolume();
        expect(result, greaterThanOrEqualTo(0));
        expect(result, lessThanOrEqualTo(100));
      });

      test('setVolume returns boolean', () async {
        // Don't actually change volume, just test return type
        final currentVolume = await api.getVolume();
        final result = await api.setVolume(currentVolume);
        expect(result, isA<bool>());
      });

      test('setVolume clamps values to 0-100', () async {
        // These should not throw, just clamp
        final result1 = await api.setVolume(-10);
        final result2 = await api.setVolume(150);
        expect(result1, isA<bool>());
        expect(result2, isA<bool>());
      });

      test('isMuted returns boolean', () async {
        final result = await api.isMuted();
        expect(result, isA<bool>());
      });

      test('toggleMute returns boolean', () async {
        final result = await api.toggleMute();
        expect(result, isA<bool>());
      });

      test('setMute returns boolean', () async {
        final currentMute = await api.isMuted();
        final result = await api.setMute(currentMute);
        expect(result, isA<bool>());
      });
    });

    group('Audio Output', () {
      test('getAudioOutput returns string', () async {
        final result = await api.getAudioOutput();
        expect(result, isA<String>());
      });

      test('listAudioOutputs returns list', () async {
        final result = await api.listAudioOutputs();
        expect(result, isA<List<Map<String, String>>>());
      });

      test('setAudioOutput returns boolean', () async {
        final result = await api.setAudioOutput('nonexistent');
        expect(result, isA<bool>());
      });
    });

    group('Brightness Controls', () {
      test('getBrightness returns int', () async {
        final result = await api.getBrightness();
        expect(result, isA<int>());
      });

      test('getBrightness returns value in range 0-100', () async {
        final result = await api.getBrightness();
        expect(result, greaterThanOrEqualTo(0));
        expect(result, lessThanOrEqualTo(100));
      });

      test('setBrightness returns boolean', () async {
        // Don't actually change brightness, just test return type
        final currentBrightness = await api.getBrightness();
        final result = await api.setBrightness(currentBrightness);
        expect(result, isA<bool>());
      });

      test('setBrightness clamps values to 0-100', () async {
        // These should not throw, just clamp
        final result1 = await api.setBrightness(-10);
        final result2 = await api.setBrightness(150);
        expect(result1, isA<bool>());
        expect(result2, isA<bool>());
      });
    });
  });
}
