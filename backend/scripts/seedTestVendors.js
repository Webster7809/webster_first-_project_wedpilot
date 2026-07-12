// One-off dev seeding script — creates 7 test vendors per category with
// deliberately spread price ranges (budget/mid/luxury) so budget-based AI
// matching can be exercised manually. A subset per category (goodReputation:
// true) also gets real booked+service-done bookings and positive feedback
// from a shared pool of seed couples, so AI matching has vendors with an
// actual computed rating/CRS to weigh against the untested ones.
// Usage: node scripts/seedTestVendors.js
require('dotenv').config();
const bcrypt = require('bcrypt');
const sequelize = require('../db/sequelize');
const User = require('../db/models/user');
const Vendor = require('../db/models/vendor');
const VendorService = require('../db/models/vendorService');
const Inquiry = require('../db/models/inquiry');
const VendorFeedback = require('../db/models/vendorFeedback');
const { recalculateVendorStats } = require('../services/vendorStats');

const TEST_PASSWORD = 'VendorTest123!';

const VENDORS = [
  {
    email: 'contact@greenacresgardens.test',
    business_name: 'Green Acres Gardens',
    category: 'Venue',
    description: 'Relaxed outdoor garden venue with tented seating and a natural backdrop.',
    style_tags: ['Rustic', 'Bohemian'],
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    price_min: 8000,
    price_max: 15000,
    unit: 'package',
  },
  {
    email: 'events@thepearlballroom.test',
    business_name: 'The Pearl Ballroom',
    category: 'Venue',
    description: 'Indoor ballroom venue with in-house décor team and a 300-guest capacity.',
    style_tags: ['Elegant', 'Modern'],
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    price_min: 25000,
    price_max: 40000,
    unit: 'package',
  },
  {
    email: 'bookings@royalmanorestate.test',
    business_name: 'Royal Manor Estate',
    category: 'Venue',
    description: 'Luxury countryside estate offering a full weekend wedding experience.',
    style_tags: ['Elegant', 'Traditional'],
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    price_min: 60000,
    price_max: 120000,
    unit: 'package',
  },
  {
    email: 'hello@mamaskitchencatering.test',
    business_name: "Mama's Kitchen Catering",
    category: 'Catering',
    description: 'Home-style Zambian catering, buffet service for up to 200 guests.',
    style_tags: ['Traditional'],
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    price_min: 5000,
    price_max: 9000,
    unit: 'per event',
  },
  {
    email: 'info@signaturefeastcatering.test',
    business_name: 'Signature Feast Catering',
    category: 'Catering',
    description: 'Plated fine-dining catering with a customisable premium menu.',
    style_tags: ['Elegant', 'Modern'],
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    price_min: 20000,
    price_max: 35000,
    unit: 'per event',
  },
  {
    email: 'studio@lensandlight.test',
    business_name: 'Lens & Light Studios',
    category: 'Photography',
    description: 'Clean, modern wedding photography with a same-week digital gallery.',
    style_tags: ['Modern', 'Minimalist'],
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    price_min: 3000,
    price_max: 6000,
    unit: 'package',
  },
  {
    email: 'book@goldenhourphotography.test',
    business_name: 'Golden Hour Photography',
    category: 'Photography',
    description: 'Full-day premium coverage with a second shooter and a printed album.',
    style_tags: ['Elegant', 'Bohemian'],
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    price_min: 12000,
    price_max: 20000,
    unit: 'package',
  },
  // Ndola / Kitwe — deliberately cheaper than their Lusaka category peers, so
  // a Lusaka-based couple can test the "further away but fits your budget
  // better" alternate-recommendation path against the "near you" primary pick.
  {
    email: 'events@minershallvenue.test',
    business_name: "Miner's Hall Venue",
    category: 'Venue',
    description: 'Historic Copperbelt hall with in-house catering partners, budget-friendly rates.',
    style_tags: ['Traditional', 'Rustic'],
    location: 'Ndola',
    latitude: -12.9587,
    longitude: 28.6366,
    price_min: 5000,
    price_max: 10000,
    unit: 'package',
  },
  {
    email: 'hello@ndolahometable.test',
    business_name: 'Ndola Home Table Catering',
    category: 'Catering',
    description: 'Family-style Zambian catering for up to 150 guests, budget packages available.',
    style_tags: ['Traditional'],
    location: 'Ndola',
    latitude: -12.9587,
    longitude: 28.6366,
    price_min: 3500,
    price_max: 7000,
    unit: 'per event',
  },
  {
    email: 'book@kitwegardenhall.test',
    business_name: 'Kitwe Garden Hall',
    category: 'Venue',
    description: 'Outdoor garden hall on the Copperbelt with flexible, affordable packages.',
    style_tags: ['Rustic', 'Minimalist'],
    location: 'Kitwe',
    latitude: -12.8024,
    longitude: 28.2132,
    price_min: 6000,
    price_max: 12000,
    unit: 'package',
  },
  {
    email: 'studio@kitweframeworks.test',
    business_name: 'Kitwe Frame Works',
    category: 'Photography',
    description: 'Budget-friendly wedding photography with a digital gallery, based in Kitwe.',
    style_tags: ['Modern', 'Minimalist'],
    location: 'Kitwe',
    latitude: -12.8024,
    longitude: 28.2132,
    price_min: 2000,
    price_max: 4500,
    unit: 'package',
  },

  // ── Top-up to 5 vendors per category, spread across Lusaka/Ndola/Kitwe ────

  // Catering (already has 3 above) — +2
  {
    email: 'hello@copperbeltfeast.test',
    business_name: 'Copperbelt Feast Catering',
    category: 'Catering',
    description: 'Buffet-style Zambian catering for weddings up to 250 guests, based in Kitwe.',
    style_tags: ['Traditional'],
    location: 'Kitwe',
    latitude: -12.8024,
    longitude: 28.2132,
    price_min: 4000,
    price_max: 8000,
    unit: 'per event',
  },
  {
    email: 'info@ndolaelegantEats.test',
    business_name: 'Ndola Elegant Eats',
    category: 'Catering',
    description: 'Plated fine-dining catering service for upscale weddings in Ndola.',
    style_tags: ['Elegant', 'Modern'],
    location: 'Ndola',
    latitude: -12.9587,
    longitude: 28.6366,
    price_min: 15000,
    price_max: 28000,
    unit: 'per event',
  },

  // Photography (already has 3 above) — +2
  {
    email: 'hello@copperbeltcaptures.test',
    business_name: 'Copperbelt Captures',
    category: 'Photography',
    description: 'Full-day wedding photography with traditional and candid coverage, Kitwe-based.',
    style_tags: ['Modern', 'Traditional'],
    location: 'Kitwe',
    latitude: -12.8024,
    longitude: 28.2132,
    price_min: 5000,
    price_max: 9000,
    unit: 'package',
  },
  {
    email: 'book@ndolamoments.test',
    business_name: 'Ndola Moments Photography',
    category: 'Photography',
    description: 'Documentary-style wedding photography with natural light portraits.',
    style_tags: ['Bohemian', 'Minimalist'],
    location: 'Ndola',
    latitude: -12.9587,
    longitude: 28.6366,
    price_min: 4000,
    price_max: 8000,
    unit: 'package',
  },

  // Decor & flowers — 5 new
  {
    email: 'hello@bloomandblossom.test',
    business_name: 'Bloom & Blossom Decor',
    category: 'Decor & flowers',
    description: 'Full-service event styling and floral design for upscale weddings.',
    style_tags: ['Elegant', 'Modern'],
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    price_min: 6000,
    price_max: 15000,
    unit: 'package',
  },
  {
    email: 'orders@petallane.test',
    business_name: 'Petal Lane Florists',
    category: 'Decor & flowers',
    description: 'Fresh floral arrangements and simple venue styling at accessible rates.',
    style_tags: ['Rustic', 'Bohemian'],
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    price_min: 2500,
    price_max: 6000,
    unit: 'package',
  },
  {
    email: 'studio@copperbeltbloom.test',
    business_name: 'Copperbelt Bloom Studio',
    category: 'Decor & flowers',
    description: 'Budget-friendly décor and floral hire for Copperbelt weddings.',
    style_tags: ['Rustic', 'Minimalist'],
    location: 'Kitwe',
    latitude: -12.8024,
    longitude: 28.2132,
    price_min: 3000,
    price_max: 7000,
    unit: 'package',
  },
  {
    email: 'hello@kitwefloraldesigns.test',
    business_name: 'Kitwe Floral Designs',
    category: 'Decor & flowers',
    description: 'Premium floral installations and full venue transformation packages.',
    style_tags: ['Elegant', 'Traditional'],
    location: 'Kitwe',
    latitude: -12.8024,
    longitude: 28.2132,
    price_min: 8000,
    price_max: 18000,
    unit: 'package',
  },
  {
    email: 'hello@ndolagardendecor.test',
    business_name: 'Ndola Garden Décor',
    category: 'Decor & flowers',
    description: 'Simple, elegant garden-style decor packages for outdoor weddings.',
    style_tags: ['Bohemian'],
    location: 'Ndola',
    latitude: -12.9587,
    longitude: 28.6366,
    price_min: 2000,
    price_max: 5000,
    unit: 'package',
  },

  // DJ & MC — 5 new
  {
    email: 'book@amplifysounddj.test',
    business_name: 'Amplify Sound & DJ',
    category: 'DJ & MC',
    description: 'Modern sound system and DJ set for receptions up to 400 guests.',
    style_tags: ['Modern'],
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    price_min: 4000,
    price_max: 9000,
    unit: 'package',
  },
  {
    email: 'mc@chandalive.test',
    business_name: 'MC Chanda Live Entertainment',
    category: 'DJ & MC',
    description: 'Bilingual wedding MC and traditional ceremony hosting.',
    style_tags: ['Traditional'],
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    price_min: 2000,
    price_max: 5000,
    unit: 'package',
  },
  {
    email: 'book@copperbeltbeats.test',
    business_name: 'Copperbelt Beats DJ Crew',
    category: 'DJ & MC',
    description: 'Affordable DJ and sound hire for Copperbelt receptions.',
    style_tags: ['Modern', 'Minimalist'],
    location: 'Kitwe',
    latitude: -12.8024,
    longitude: 28.2132,
    price_min: 1800,
    price_max: 4000,
    unit: 'package',
  },
  {
    email: 'hello@kitwepartysounds.test',
    business_name: 'Kitwe Party Sounds',
    category: 'DJ & MC',
    description: 'Full production DJ, lighting, and MC package for larger weddings.',
    style_tags: ['Elegant'],
    location: 'Kitwe',
    latitude: -12.8024,
    longitude: 28.2132,
    price_min: 5000,
    price_max: 10000,
    unit: 'package',
  },
  {
    email: 'book@ndolavibe.test',
    business_name: 'Ndola Vibe Entertainment',
    category: 'DJ & MC',
    description: 'Budget DJ and MC hire with a mix of traditional and modern playlists.',
    style_tags: ['Traditional', 'Rustic'],
    location: 'Ndola',
    latitude: -12.9587,
    longitude: 28.6366,
    price_min: 1500,
    price_max: 3500,
    unit: 'package',
  },

  // Transport — 4 new (there's already one Kitwe entry added by the couple manually)
  {
    email: 'book@royalridecars.test',
    business_name: 'Royal Ride Wedding Cars',
    category: 'Transport',
    description: 'Chauffeured luxury car hire for the wedding party.',
    style_tags: ['Elegant'],
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    price_min: 3000,
    price_max: 8000,
    unit: 'per event',
  },
  {
    email: 'hello@budgetwheels.test',
    business_name: 'Budget Wheels Transport',
    category: 'Transport',
    description: 'Affordable guest shuttle and bridal car hire.',
    style_tags: ['Minimalist'],
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    price_min: 800,
    price_max: 2000,
    unit: 'per event',
  },
  {
    email: 'book@copperbeltclassiccars.test',
    business_name: 'Copperbelt Classic Cars',
    category: 'Transport',
    description: 'Vintage and classic car hire for the wedding convoy.',
    style_tags: ['Elegant', 'Traditional'],
    location: 'Kitwe',
    latitude: -12.8024,
    longitude: 28.2132,
    price_min: 4000,
    price_max: 9000,
    unit: 'per event',
  },
  {
    email: 'hello@ndolashuttle.test',
    business_name: 'Ndola Shuttle & Limo',
    category: 'Transport',
    description: 'Guest shuttle service and a limo option for the couple.',
    style_tags: ['Modern'],
    location: 'Ndola',
    latitude: -12.9587,
    longitude: 28.6366,
    price_min: 1200,
    price_max: 3000,
    unit: 'per event',
  },

  // Wedding attire — 5 new
  {
    email: 'hello@elegancebridal.test',
    business_name: 'Elegance Bridal House',
    category: 'Wedding attire',
    description: 'Designer bridal gowns and groom suits, made-to-measure or rental.',
    style_tags: ['Elegant'],
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    price_min: 8000,
    price_max: 20000,
    unit: 'package',
  },
  {
    email: 'hello@chicthreads.test',
    business_name: 'Chic Threads Bridal & Suits',
    category: 'Wedding attire',
    description: 'Modern, minimalist bridal wear and suiting at mid-range prices.',
    style_tags: ['Modern', 'Minimalist'],
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    price_min: 2500,
    price_max: 7000,
    unit: 'package',
  },
  {
    email: 'hello@copperbeltcouture.test',
    business_name: 'Copperbelt Couture',
    category: 'Wedding attire',
    description: 'Traditional and Western bridal wear, tailored locally in Kitwe.',
    style_tags: ['Traditional', 'Elegant'],
    location: 'Kitwe',
    latitude: -12.8024,
    longitude: 28.2132,
    price_min: 4000,
    price_max: 10000,
    unit: 'package',
  },
  {
    email: 'hello@kitwebridal.test',
    business_name: 'Kitwe Bridal Boutique',
    category: 'Wedding attire',
    description: 'Budget bridal gown rentals with free alterations.',
    style_tags: ['Bohemian'],
    location: 'Kitwe',
    latitude: -12.8024,
    longitude: 28.2132,
    price_min: 1500,
    price_max: 4000,
    unit: 'package',
  },
  {
    email: 'hello@ndolatailors.test',
    business_name: 'Ndola Tailors & Bridal',
    category: 'Wedding attire',
    description: 'Custom-tailored traditional wedding outfits at affordable rates.',
    style_tags: ['Traditional'],
    location: 'Ndola',
    latitude: -12.9587,
    longitude: 28.6366,
    price_min: 1000,
    price_max: 3000,
    unit: 'package',
  },

  // Cake & sweets — 5 new
  {
    email: 'orders@sweetsymphony.test',
    business_name: 'Sweet Symphony Cakes',
    category: 'Cake & sweets',
    description: 'Custom multi-tier wedding cakes with elegant modern designs.',
    style_tags: ['Elegant', 'Modern'],
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    price_min: 2500,
    price_max: 6000,
    unit: 'package',
  },
  {
    email: 'orders@sugarandspice.test',
    business_name: 'Sugar & Spice Bakery',
    category: 'Cake & sweets',
    description: 'Home-style wedding cakes and dessert tables at affordable rates.',
    style_tags: ['Rustic'],
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    price_min: 900,
    price_max: 2200,
    unit: 'package',
  },
  {
    email: 'hello@copperbeltcakestudio.test',
    business_name: 'Copperbelt Cake Studio',
    category: 'Cake & sweets',
    description: 'Custom cake designs and dessert tables, based in Kitwe.',
    style_tags: ['Modern'],
    location: 'Kitwe',
    latitude: -12.8024,
    longitude: 28.2132,
    price_min: 1500,
    price_max: 3500,
    unit: 'package',
  },
  {
    email: 'hello@kitwesweettreats.test',
    business_name: 'Kitwe Sweet Treats',
    category: 'Cake & sweets',
    description: 'Budget wedding cakes and traditional sweets platters.',
    style_tags: ['Traditional'],
    location: 'Kitwe',
    latitude: -12.8024,
    longitude: 28.2132,
    price_min: 800,
    price_max: 1800,
    unit: 'package',
  },
  {
    email: 'hello@ndoladelight.test',
    business_name: 'Ndola Delight Bakery',
    category: 'Cake & sweets',
    description: 'Affordable wedding cakes and dessert bars for Ndola weddings.',
    style_tags: ['Rustic', 'Bohemian'],
    location: 'Ndola',
    latitude: -12.9587,
    longitude: 28.6366,
    price_min: 700,
    price_max: 1600,
    unit: 'package',
  },

  // ── Top-up to 7 per category — all seeded with real bookings + strong,
  // genuinely-computed feedback (not fabricated stats) so AI matching has
  // vendors with real reputations to weigh against the untested ones above.

  // Venue (5 above) — +2
  {
    email: 'events@sablehillsvenue.test',
    business_name: 'Sable Hills Wedding Venue',
    category: 'Venue',
    description: 'Elegant hillside venue with panoramic views and an in-house events team.',
    style_tags: ['Elegant', 'Modern'],
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    price_min: 30000,
    price_max: 55000,
    unit: 'package',
    goodReputation: true,
  },
  {
    email: 'bookings@heritagelodgeestate.test',
    business_name: 'Heritage Lodge Estate',
    category: 'Venue',
    description: 'Traditional-style lodge estate in Ndola with grounds for large receptions.',
    style_tags: ['Traditional', 'Elegant'],
    location: 'Ndola',
    latitude: -12.9587,
    longitude: 28.6366,
    price_min: 18000,
    price_max: 32000,
    unit: 'package',
    goodReputation: true,
  },

  // Catering (5 above) — +2
  {
    email: 'hello@copperrosecatering.test',
    business_name: 'Copper Rose Catering',
    category: 'Catering',
    description: 'Elegant plated and buffet catering with a highly-rated tasting menu.',
    style_tags: ['Elegant', 'Modern'],
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    price_min: 12000,
    price_max: 22000,
    unit: 'per event',
    goodReputation: true,
  },
  {
    email: 'hello@tamarastable.test',
    business_name: "Tamara's Table Catering",
    category: 'Catering',
    description: 'Warm, traditional Zambian catering with a loyal Copperbelt following.',
    style_tags: ['Traditional', 'Rustic'],
    location: 'Kitwe',
    latitude: -12.8024,
    longitude: 28.2132,
    price_min: 6000,
    price_max: 12000,
    unit: 'per event',
    goodReputation: true,
  },

  // Photography (5 above) — +2
  {
    email: 'studio@timelessframes.test',
    business_name: 'Timeless Frames Photography',
    category: 'Photography',
    description: 'Award-winning wedding photography blending traditional and elegant styles.',
    style_tags: ['Elegant', 'Traditional'],
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    price_min: 7000,
    price_max: 14000,
    unit: 'package',
    goodReputation: true,
  },
  {
    email: 'book@apertureandaisle.test',
    business_name: 'Aperture & Aisle Studios',
    category: 'Photography',
    description: 'Highly-reviewed modern and minimalist wedding photography in Ndola.',
    style_tags: ['Modern', 'Minimalist'],
    location: 'Ndola',
    latitude: -12.9587,
    longitude: 28.6366,
    price_min: 4500,
    price_max: 9000,
    unit: 'package',
    goodReputation: true,
  },

  // Decor & flowers (5 above) — +2
  {
    email: 'hello@ivoryandbloom.test',
    business_name: 'Ivory & Bloom Events',
    category: 'Decor & flowers',
    description: 'Premium event styling and floral design with a stellar client track record.',
    style_tags: ['Elegant', 'Modern'],
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    price_min: 9000,
    price_max: 20000,
    unit: 'package',
    goodReputation: true,
  },
  {
    email: 'orders@wildflowercopperbelt.test',
    business_name: 'Wildflower Copperbelt Decor',
    category: 'Decor & flowers',
    description: 'Bohemian and rustic floral styling, a Copperbelt favourite.',
    style_tags: ['Bohemian', 'Rustic'],
    location: 'Kitwe',
    latitude: -12.8024,
    longitude: 28.2132,
    price_min: 4000,
    price_max: 9000,
    unit: 'package',
    goodReputation: true,
  },

  // DJ & MC (5 above) — +2
  {
    email: 'book@primesoundent.test',
    business_name: 'Prime Sound Entertainment',
    category: 'DJ & MC',
    description: 'High-energy DJ and MC duo with consistently glowing feedback.',
    style_tags: ['Modern', 'Elegant'],
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    price_min: 6000,
    price_max: 12000,
    unit: 'package',
    goodReputation: true,
  },
  {
    email: 'mc@voiceofzambia.test',
    business_name: 'Voice of Zambia MC & DJ',
    category: 'DJ & MC',
    description: 'Bilingual MC and sound hire known for keeping receptions on schedule.',
    style_tags: ['Traditional', 'Modern'],
    location: 'Ndola',
    latitude: -12.9587,
    longitude: 28.6366,
    price_min: 3000,
    price_max: 6500,
    unit: 'package',
    goodReputation: true,
  },

  // Transport (4 above) — +3
  {
    email: 'book@prestigeweddingcars.test',
    business_name: 'Prestige Wedding Cars',
    category: 'Transport',
    description: 'Chauffeured luxury bridal car hire with a spotless service record.',
    style_tags: ['Elegant', 'Modern'],
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    price_min: 5000,
    price_max: 12000,
    unit: 'per event',
    goodReputation: true,
  },
  {
    email: 'hello@copperbeltbridalrides.test',
    business_name: 'Copperbelt Bridal Rides',
    category: 'Transport',
    description: 'Reliable, punctual bridal car and guest shuttle service in Kitwe.',
    style_tags: ['Elegant'],
    location: 'Kitwe',
    latitude: -12.8024,
    longitude: 28.2132,
    price_min: 3000,
    price_max: 7000,
    unit: 'per event',
    goodReputation: true,
  },
  {
    email: 'book@ndolaroyaltransport.test',
    business_name: 'Ndola Royal Transport',
    category: 'Transport',
    description: 'Traditional and elegant convoy hire, well-reviewed for punctuality.',
    style_tags: ['Traditional', 'Elegant'],
    location: 'Ndola',
    latitude: -12.9587,
    longitude: 28.6366,
    price_min: 2500,
    price_max: 6000,
    unit: 'per event',
    goodReputation: true,
  },

  // Wedding attire (5 above) — +2
  {
    email: 'hello@thebridalatelier.test',
    business_name: 'The Bridal Atelier',
    category: 'Wedding attire',
    description: 'Premium designer bridal gowns and suiting with a devoted client base.',
    style_tags: ['Elegant'],
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    price_min: 10000,
    price_max: 25000,
    unit: 'package',
    goodReputation: true,
  },
  {
    email: 'hello@heritagewearcopperbelt.test',
    business_name: 'Heritage Wear Copperbelt',
    category: 'Wedding attire',
    description: 'Traditional wedding outfits tailored locally, highly recommended in Kitwe.',
    style_tags: ['Traditional'],
    location: 'Kitwe',
    latitude: -12.8024,
    longitude: 28.2132,
    price_min: 3500,
    price_max: 9000,
    unit: 'package',
    goodReputation: true,
  },

  // Cake & sweets (5 above) — +2
  {
    email: 'orders@divinecakecouture.test',
    business_name: 'Divine Cake Couture',
    category: 'Cake & sweets',
    description: 'Elegant custom wedding cakes with a consistently 5-star track record.',
    style_tags: ['Elegant', 'Modern'],
    location: 'Lusaka',
    latitude: -15.4167,
    longitude: 28.2833,
    price_min: 3500,
    price_max: 8000,
    unit: 'package',
    goodReputation: true,
  },
  {
    email: 'hello@copperbeltsweetcelebrations.test',
    business_name: 'Copperbelt Sweet Celebrations',
    category: 'Cake & sweets',
    description: 'Well-loved traditional and rustic wedding cakes in Ndola.',
    style_tags: ['Traditional', 'Rustic'],
    location: 'Ndola',
    latitude: -12.9587,
    longitude: 28.6366,
    price_min: 1200,
    price_max: 3000,
    unit: 'package',
    goodReputation: true,
  },
];

// Reusable pool of couple accounts that "book" every goodReputation vendor —
// small and shared across vendors since VendorFeedback's uniqueness is per
// (couple, vendor) pair, not global.
const SEED_COUPLE_COUNT = 6;

async function ensureSeedCouples(password_hash) {
  const couples = [];
  for (let i = 1; i <= SEED_COUPLE_COUNT; i++) {
    const email = `seed-couple-${String(i).padStart(2, '0')}@test.com`;
    let user = await User.findOne({ where: { email } });
    if (!user) {
      user = await User.create({
        email,
        password_hash,
        name: `Seed Couple ${i}`,
        role: 'couple',
        is_verified: true,
      });
    }
    couples.push(user);
  }
  return couples;
}

const POSITIVE_COMMENTS = [
  'Absolutely wonderful to work with — professional and on time!',
  'Exceeded our expectations, would recommend to any couple.',
  'Great communication throughout and beautiful results.',
  'Made our wedding day stress-free — highly recommend.',
  'Fantastic value and attention to detail.',
  'They went above and beyond for us.',
];
const RATINGS = [5, 5, 4, 5, 5, 4];
const ON_TIME = ['yes', 'yes', 'yes', 'no', 'yes', 'not_applicable'];

// Creates real booked + service-done inquiries and matching feedback from
// the seed-couple pool, then lets recalculateVendorStats compute the
// vendor's rating/CRS for real — never writes vendor_stats directly, so the
// numbers stay correct if stats are ever recalculated later.
async function seedGoodReputation(vendor, meta, coupleUsers) {
  let created = 0;
  for (let i = 0; i < coupleUsers.length; i++) {
    const couple = coupleUsers[i];
    const existingFeedback = await VendorFeedback.findOne({
      where: { couple_user_id: couple.user_id, vendor_id: vendor.vendor_id },
    });
    if (existingFeedback) continue;

    const now = new Date();
    const inquiry = await Inquiry.create({
      couple_user_id: couple.user_id,
      vendor_id: vendor.vendor_id,
      message: `Hi! We'd love to book you for our wedding — ${meta.business_name} came highly recommended.`,
      status: 'booked',
      responded_at: now,
      service_done_at: now,
      rating_reminder_count: 1,
      rating_reminder_last_sent_at: now,
    });

    await VendorFeedback.create({
      couple_user_id: couple.user_id,
      vendor_id: vendor.vendor_id,
      inquiry_id: inquiry.inquiry_id,
      star_rating: RATINGS[i % RATINGS.length],
      comment: POSITIVE_COMMENTS[i % POSITIVE_COMMENTS.length],
      on_time: ON_TIME[i % ON_TIME.length],
    });
    created++;
  }

  if (created > 0) {
    await recalculateVendorStats(vendor.vendor_id);
    console.log(`  Seeded ${created} feedback entries for ${meta.business_name}.`);
  } else {
    console.log(`  ${meta.business_name} already has reputation data — skipped.`);
  }
}

async function main() {
  await sequelize.authenticate();
  const password_hash = await bcrypt.hash(TEST_PASSWORD, 10);

  const reputationVendors = [];

  for (const v of VENDORS) {
    const existingUser = await User.findOne({ where: { email: v.email } });
    if (existingUser) {
      console.log(`Skipping ${v.business_name} — ${v.email} already exists.`);
      if (v.goodReputation) {
        const existingVendor = await Vendor.findOne({ where: { user_id: existingUser.user_id } });
        if (existingVendor) reputationVendors.push({ vendor: existingVendor, meta: v });
      }
      continue;
    }

    const user = await User.create({
      email: v.email,
      password_hash,
      name: v.business_name,
      role: 'vendor',
      is_verified: true,
    });

    const vendor = await Vendor.create({
      user_id: user.user_id,
      business_name: v.business_name,
      description: v.description,
      category: v.category,
      location: v.location,
      latitude: v.latitude,
      longitude: v.longitude,
      tier: 'free',
      verification_status: 'verified',
      style_tags: v.style_tags,
    });

    await VendorService.create({
      vendor_id: vendor.vendor_id,
      title: `${v.category} package`,
      description: v.description,
      price_min: v.price_min,
      price_max: v.price_max,
      unit: v.unit,
    });

    console.log(`Created ${v.business_name} (${v.category}, ${v.price_min}-${v.price_max} ZMW) — login: ${v.email} / ${TEST_PASSWORD}`);
    if (v.goodReputation) reputationVendors.push({ vendor, meta: v });
  }

  if (reputationVendors.length) {
    console.log(`\nSeeding reputations for ${reputationVendors.length} vendors...`);
    const coupleUsers = await ensureSeedCouples(password_hash);
    for (const { vendor, meta } of reputationVendors) {
      await seedGoodReputation(vendor, meta, coupleUsers);
    }
  }

  console.log('Done.');
  process.exit(0);
}

main().catch((err) => {
  console.error('Failed to seed test vendors:', err.message);
  process.exit(1);
});
