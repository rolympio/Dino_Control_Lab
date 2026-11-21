import '../domain/config.dart';
import '../domain/json_values.dart';

List<Map<String, dynamic>> parseSamples(Object? value) {
  var previous = -1;
  return jsonList(value).map((item) {
    final sample = jsonObject(item);
    final tick = jsonInt(sample['tick'], min: 0);
    if (tick < previous) throw const FormatException('Amostras fora de ordem');
    previous = tick;
    jsonNumber(sample['time_s'], min: 0);
    jsonNumber(sample['height_px'], min: 0);
    jsonNumber(sample['velocity_px_s']);
    jsonNumber(sample['speed_px_s'], min: 0);
    jsonNumber(sample['distance_px'], min: 0);
    jsonInt(sample['score'], min: 0);
    jsonEnum(sample['move'], Move.values);
    return Map<String, dynamic>.from(sample);
  }).toList();
}

List<Map<String, dynamic>> parseEvents(Object? value) {
  return jsonList(value).map((item) {
    final event = jsonObject(item);
    jsonInt(event['tick'], min: 0);
    if (!event.containsKey('move') && !event.containsKey('config')) {
      throw const FormatException('Evento sem ação ou configuração');
    }
    if (event.containsKey('move')) jsonEnum(event['move'], Move.values);
    if (event.containsKey('config')) {
      LabConfig.fromJson(jsonObject(event['config']));
    }
    return Map<String, dynamic>.from(event);
  }).toList();
}
