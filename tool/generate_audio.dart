import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

void main() {
  Directory('assets/audio').createSync(recursive: true);
  for (final name in ['jump', 'hit']) {
    const rate = 22050;
    final count = (rate * (name == 'jump' ? .09 : .2)).round();
    final bytes = ByteData(44 + count * 2);
    void ascii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        bytes.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    bytes.setUint32(4, 36 + count * 2, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, 1, Endian.little);
    bytes.setUint32(24, rate, Endian.little);
    bytes.setUint32(28, rate * 2, Endian.little);
    bytes.setUint16(32, 2, Endian.little);
    bytes.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    bytes.setUint32(40, count * 2, Endian.little);
    for (var i = 0; i < count; i++) {
      final t = i / rate;
      final frequency = name == 'jump' ? 620 + 1800 * t : 130 - 180 * t;
      final value =
          math.sin(2 * math.pi * frequency * t) * (1 - i / count) * 9000;
      bytes.setInt16(44 + i * 2, value.round(), Endian.little);
    }
    File('assets/audio/$name.wav').writeAsBytesSync(bytes.buffer.asUint8List());
  }
}
