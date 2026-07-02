T enumByName<T extends Enum>(List<T> values, String? name, T fallback) =>
    name == null
        ? fallback
        : values.firstWhere((e) => e.name == name, orElse: () => fallback);
