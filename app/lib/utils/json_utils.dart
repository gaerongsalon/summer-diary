class JsonUtils {
  static Map<K, V> asMap<K, V>(Map json) {
    final map = <K, V>{};
    json.entries.forEach((entry) => map[entry.key] = entry.value);
    return map;
  }

  static List<T> asList<T>(List json) => json.map((each) => each as T).toList();
}
