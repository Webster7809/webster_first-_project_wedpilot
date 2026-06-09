import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vendor_profile.dart';

final selectedCategoryProvider = StateProvider<String>((ref) => 'Photography');

final vendorSearchQueryProvider = StateProvider<String>((ref) => '');

final vendorListProvider = FutureProvider.family<List<VendorProfile>, String>(
  (ref, category) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockVendors.where((v) => v.category == category).toList();
  },
);

final vendorDetailProvider = FutureProvider.family<VendorProfile, String>(
  (ref, vendorId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockVendors.firstWhere((v) => v.id == vendorId,
        orElse: () => _mockVendors.first);
  },
);

final wishlistProvider = StateNotifierProvider<WishlistNotifier, List<String>>(
  (ref) => WishlistNotifier(),
);

class WishlistNotifier extends StateNotifier<List<String>> {
  WishlistNotifier() : super([]);

  void toggle(String vendorId) {
    if (state.contains(vendorId)) {
      state = state.where((id) => id != vendorId).toList();
    } else {
      state = [...state, vendorId];
    }
  }

  bool isWishlisted(String vendorId) => state.contains(vendorId);
}

final List<VendorProfile> _mockVendors = [
  VendorProfile(
    id: 'v-001',
    userId: 'u-001',
    businessName: 'Blossom Photography',
    description: 'Award-winning wedding photography with a romantic, editorial style. Over 200 weddings captured.',
    category: 'Photography',
    location: 'New York, NY',
    latitude: 40.7128,
    longitude: -74.0060,
    tier: VendorTier.premium,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Romantic', 'Editorial', 'Modern'],
    rating: 4.9,
    reviewCount: 87,
    compositeScore: 94.2,
    services: [
      VendorService(id: 's-001', vendorId: 'v-001', title: 'Full Day Coverage', description: '10 hours of coverage', priceMin: 3500, priceMax: 5000, unit: 'package'),
      VendorService(id: 's-002', vendorId: 'v-001', title: 'Half Day Coverage', description: '6 hours of coverage', priceMin: 2200, priceMax: 3200, unit: 'package'),
    ],
  ),
  VendorProfile(
    id: 'v-002',
    userId: 'u-002',
    businessName: 'Golden Lens Studio',
    description: 'Candid, documentary-style wedding photography that tells your love story authentically.',
    category: 'Photography',
    location: 'Brooklyn, NY',
    latitude: 40.6782,
    longitude: -73.9442,
    tier: VendorTier.pro,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Candid', 'Documentary', 'Boho'],
    rating: 4.7,
    reviewCount: 52,
    compositeScore: 88.5,
    services: [
      VendorService(id: 's-003', vendorId: 'v-002', title: 'Wedding Package A', description: '8 hours, 2 photographers', priceMin: 2800, priceMax: 4000, unit: 'package'),
    ],
  ),
  VendorProfile(
    id: 'v-003',
    userId: 'u-003',
    businessName: 'The Garden Venue',
    description: 'An enchanting outdoor wedding venue with manicured gardens, fountain, and reception hall.',
    category: 'Venue',
    location: 'Long Island, NY',
    latitude: 40.7891,
    longitude: -73.1350,
    tier: VendorTier.premium,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Garden', 'Romantic', 'Outdoor'],
    rating: 4.8,
    reviewCount: 134,
    compositeScore: 91.0,
    services: [
      VendorService(id: 's-004', vendorId: 'v-003', title: 'Full Venue Rental', description: 'Up to 200 guests, full day', priceMin: 8000, priceMax: 15000, unit: 'day'),
    ],
  ),
  VendorProfile(
    id: 'v-004',
    userId: 'u-004',
    businessName: 'Culinary Bliss Catering',
    description: 'Farm-to-table wedding catering with customizable menus and professional service staff.',
    category: 'Catering',
    location: 'New York, NY',
    latitude: 40.7580,
    longitude: -73.9855,
    tier: VendorTier.pro,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Modern', 'Farm-to-Table'],
    rating: 4.6,
    reviewCount: 68,
    compositeScore: 85.3,
    services: [
      VendorService(id: 's-005', vendorId: 'v-004', title: 'Per Person Package', description: 'Includes appetizers, main, dessert', priceMin: 85, priceMax: 150, unit: 'per person'),
    ],
  ),
  VendorProfile(
    id: 'v-005',
    userId: 'u-005',
    businessName: 'Petal & Bloom Floristry',
    description: 'Luxury floral designs that transform your wedding vision into a breathtaking reality.',
    category: 'Floristry',
    location: 'Manhattan, NY',
    latitude: 40.7831,
    longitude: -73.9712,
    tier: VendorTier.premium,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Romantic', 'Luxury', 'Garden'],
    rating: 4.9,
    reviewCount: 43,
    compositeScore: 92.1,
    services: [
      VendorService(id: 's-006', vendorId: 'v-005', title: 'Full Floral Package', description: 'Ceremony + reception florals', priceMin: 3000, priceMax: 8000, unit: 'package'),
    ],
  ),
  VendorProfile(
    id: 'v-006',
    userId: 'u-006',
    businessName: 'Sweet Moments Cake Studio',
    description: 'Custom wedding cakes and dessert tables crafted with artistic detail and exceptional flavors.',
    category: 'Cake',
    location: 'Queens, NY',
    latitude: 40.7282,
    longitude: -73.7949,
    tier: VendorTier.pro,
    verificationStatus: VerificationStatus.verified,
    styleTags: ['Modern', 'Elegant'],
    rating: 4.7,
    reviewCount: 91,
    compositeScore: 86.8,
    services: [
      VendorService(id: 's-007', vendorId: 'v-006', title: 'Custom Wedding Cake', description: 'Per serving pricing', priceMin: 6, priceMax: 15, unit: 'per serving'),
    ],
  ),
];
