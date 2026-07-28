/// Curated stock photography, grouped by vendor category — shown only as a
/// fallback when a vendor hasn't uploaded any real photos of their own yet
/// (see [VendorHeroImage] in widgets/vendor_hero_image.dart), never in place
/// of real vendor media. Every photo was hand-picked and visually verified to
/// actually depict that category (a grazing table for Catering, a hanging
/// gown for Wedding attire, etc.) — not a random/generic wedding photo reused
/// everywhere.
///
/// Source: Pexels (https://www.pexels.com/license/) — free for commercial
/// use, no attribution required, stable CDN suitable for hotlinking.
class VendorCategoryImages {
  VendorCategoryImages._();

  static const Map<String, List<int>> _photoIdsByCategory = {
    'Venue': [33852468, 17001763, 3376771, 12688997, 32142669],
    'Catering': [28976236, 28976230, 28976228, 37976911, 29587700],
    'Photography': [35325793, 37754302, 21560369, 18864880, 17169150],
    'Decor & flowers': [31138818, 4646001, 12876507, 31517333, 32657514],
    'DJ & MC': [27018254, 32601989, 12473542, 1749822, 29315604],
    'Transport': [37828108, 13044866, 19894151, 18433155, 29240263],
    'Wedding attire': [27269998, 20194301, 16625625, 4637461, 15120548],
    'Cake & sweets': [11712500, 17315403, 30445121, 24838552, 19870076],
  };

  /// Used only for a category outside the curated map above (a vendor with a
  /// custom, couple-added category) — a generic decor shot rather than no
  /// image at all.
  static const List<int> _fallback = [12876507, 33852468, 28976236];

  static String _urlFor(int id, int width) =>
      'https://images.pexels.com/photos/$id/pexels-photo-$id.jpeg?auto=compress&cs=tinysrgb&w=$width';

  /// One stable image for [vendorId] within [category] — the same vendor
  /// always gets the same photo (no flicker on rebuild), but different
  /// vendors in the same category spread across the curated set instead of
  /// every card in, say, Catering showing the identical picture.
  static String forVendor(String category, String vendorId, {int width = 800}) {
    final ids = _photoIdsByCategory[category] ?? _fallback;
    final index = vendorId.hashCode.abs() % ids.length;
    return _urlFor(ids[index], width);
  }

  /// The full curated set for a category, for the profile hero carousel and
  /// portfolio grid when a vendor has no uploads of their own to show yet.
  static List<String> galleryFor(String category, {int width = 800}) {
    final ids = _photoIdsByCategory[category] ?? _fallback;
    return ids.map((id) => _urlFor(id, width)).toList();
  }
}
