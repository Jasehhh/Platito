import 'package:flutter_test/flutter_test.dart';
import 'package:platito/widgets/home_header.dart';

void main() {
  group('HomeHeader.greetingFor', () {
    test('says umaga before noon', () {
      expect(
        HomeHeader.greetingFor(DateTime(2026, 10, 12, 7)),
        'Magandang umaga!',
      );
    });

    test('says hapon from noon until 6 PM', () {
      expect(
        HomeHeader.greetingFor(DateTime(2026, 10, 12, 12)),
        'Magandang hapon!',
      );
      expect(
        HomeHeader.greetingFor(DateTime(2026, 10, 12, 17, 59)),
        'Magandang hapon!',
      );
    });

    test('says gabi from 6 PM', () {
      expect(
        HomeHeader.greetingFor(DateTime(2026, 10, 12, 18)),
        'Magandang gabi!',
      );
    });
  });
}
