class TourEvent {
  const TourEvent({
    required this.name,
    required this.venue,
    required this.startDate,
    required this.startTime,
    required this.endTime,
    required this.excerpt,
    required this.imageUrl,
  });
  final String name;
  final String venue;
  final String startDate;
  final String startTime;
  final String endTime;
  final String excerpt;
  final String imageUrl;

  String get displayName => '$name - $venue ($startDate)';
}

const List<TourEvent> tourEvents = [
  TourEvent(
    name: 'Local ARTbeat ENC Art Capture Tour - Pink Hill',
    venue: 'Downtown Pink Hill',
    startDate: '2026-01-18',
    startTime: '2:00 PM',
    endTime: '4:00 PM',
    excerpt:
        'We will be downtown capturing outdoor art with the Local ARTbeat app while walking and exploring the city together',
    imageUrl:
        'https://www.localartbeat.com/wp-content/uploads/2025/12/pink_hill_enc_tour_2026.png',
  ),
  TourEvent(
    name: 'Local ARTbeat ENC Art Capture Tour - Farmville',
    venue: 'Downtown Farmville',
    startDate: '2026-01-25',
    startTime: '2:00 PM',
    endTime: '4:00 PM',
    excerpt:
        'Meet us downtown as we explore public art and capture discoveries using the Local ARTbeat app',
    imageUrl:
        'https://www.localartbeat.com/wp-content/uploads/2025/12/farmville_enc_tour_2026.png',
  ),
  TourEvent(
    name: 'Local ARTbeat ENC Art Capture Tour - Ayden',
    venue: 'Downtown Ayden',
    startDate: '2026-02-01',
    startTime: '2:00 PM',
    endTime: '4:00 PM',
    excerpt:
        'Walk downtown capture art and explore the city through Local ARTbeat',
    imageUrl:
        'https://www.localartbeat.com/wp-content/uploads/2025/12/ayden_enc_tour_2026.png',
  ),
  TourEvent(
    name: 'Local ARTbeat ENC Art Capture Tour - Wilson',
    venue: 'Downtown Wilson',
    startDate: '2026-02-08',
    startTime: '2:00 PM',
    endTime: '4:00 PM',
    excerpt:
        'Discover how much art is hiding downtown as we explore and capture it with Local ARTbeat',
    imageUrl:
        'https://www.localartbeat.com/wp-content/uploads/2025/12/wilson_enc_tour_2026.png',
  ),
  TourEvent(
    name: 'Local ARTbeat ENC Art Capture Tour - Jacksonville',
    venue: 'Downtown Jacksonville',
    startDate: '2026-02-15',
    startTime: '2:00 PM',
    endTime: '4:00 PM',
    excerpt:
        'Explore downtown and capture public art while walking the city with Local ARTbeat',
    imageUrl:
        'https://www.localartbeat.com/wp-content/uploads/2025/12/jacksonville_enc_tour_2026.png',
  ),
  TourEvent(
    name: 'Local ARTbeat ENC Art Capture Tour - Warsaw',
    venue: 'Downtown Warsaw',
    startDate: '2026-02-22',
    startTime: '2:00 PM',
    endTime: '4:00 PM',
    excerpt:
        'Help us map outdoor art while exploring downtown with Local ARTbeat',
    imageUrl:
        'https://www.localartbeat.com/wp-content/uploads/2025/12/warsaw_enc_tour_2026.png',
  ),
  TourEvent(
    name: 'Local ARTbeat ENC Art Capture Tour - La Grange',
    venue: 'Downtown La Grange',
    startDate: '2026-03-01',
    startTime: '2:00 PM',
    endTime: '4:00 PM',
    excerpt:
        'Join us downtown to discover art and explore the city using Local ARTbeat',
    imageUrl:
        'https://www.localartbeat.com/wp-content/uploads/2025/12/la_grange_enc_tour_2026.png',
  ),
  TourEvent(
    name: 'Local ARTbeat ENC Art Capture Tour - Washington',
    venue: 'Downtown Washington',
    startDate: '2026-03-08',
    startTime: '2:00 PM',
    endTime: '4:00 PM',
    excerpt:
        'Walk the waterfront and downtown while capturing public art with Local ARTbeat',
    imageUrl:
        'https://www.localartbeat.com/wp-content/uploads/2025/12/washington_enc_tour_2026.png',
  ),
  TourEvent(
    name: 'Local ARTbeat ENC Art Capture Tour - Goldsboro',
    venue: 'Downtown Goldsboro',
    startDate: '2026-03-15',
    startTime: '2:00 PM',
    endTime: '4:00 PM',
    excerpt:
        'Explore downtown and capture public art while discovering the city with Local ARTbeat',
    imageUrl:
        'https://www.localartbeat.com/wp-content/uploads/2025/12/goldsboro_enc_tour_2026.png',
  ),
  TourEvent(
    name: 'Local ARTbeat ENC Art Capture Tour - New Bern',
    venue: 'Downtown New Bern',
    startDate: '2026-03-22',
    startTime: '2:00 PM',
    endTime: '4:00 PM',
    excerpt:
        'Experience historic downtown and capture art using the Local ARTbeat app',
    imageUrl:
        'https://www.localartbeat.com/wp-content/uploads/2025/12/new_bern_enc_tour_2026.png',
  ),
  TourEvent(
    name: 'Local ARTbeat ENC Art Capture Tour - Mount Olive',
    venue: 'Downtown Mount Olive',
    startDate: '2026-03-29',
    startTime: '2:00 PM',
    endTime: '4:00 PM',
    excerpt: 'Walk downtown and help document public art using Local ARTbeat',
    imageUrl:
        'https://www.localartbeat.com/wp-content/uploads/2025/12/mount_olive_enc_tour_2026.png',
  ),
  TourEvent(
    name: 'Local ARTbeat ENC Art Capture Tour - Tarboro',
    venue: 'Downtown Tarboro',
    startDate: '2026-04-12',
    startTime: '2:00 PM',
    endTime: '4:00 PM',
    excerpt:
        'Discover how much art is hiding downtown as we explore and capture it with Local ARTbeat',
    imageUrl:
        'https://www.localartbeat.com/wp-content/uploads/2025/12/mount_olive_enc_tour_2026.png',
  ),
  TourEvent(
    name: 'Local ARTbeat ENC Art Capture Tour - Edenton',
    venue: 'Downtown Edenton',
    startDate: '2026-04-19',
    startTime: '2:00 PM',
    endTime: '4:00 PM',
    excerpt:
        'Explore downtown and capture public art while walking the city with Local ARTbeat',
    imageUrl:
        'https://www.localartbeat.com/wp-content/uploads/2025/12/edenton_enc_tour_2026.png',
  ),
  TourEvent(
    name: 'Local ARTbeat Launch Party - Kinston',
    venue: 'Downtown Kinston',
    startDate: '2026-04-25',
    startTime: '6:00 PM',
    endTime: '8:00 PM',
    excerpt:
        'Celebrate the launch of Local ARTbeat and join the community downtown',
    imageUrl:
        'https://www.localartbeat.com/wp-content/uploads/2025/12/kinston_enc_tour_2026.png',
  ),
  TourEvent(
    name: 'Local ARTbeat ENC Art Capture Tour - Kinston',
    venue: 'Downtown Kinston',
    startDate: '2026-04-26',
    startTime: '2:00 PM',
    endTime: '4:00 PM',
    excerpt: 'Explore downtown and capture public art using Local ARTbeat',
    imageUrl:
        'https://www.localartbeat.com/wp-content/uploads/2025/12/kinston_enc_tour_2026.png',
  ),
  TourEvent(
    name: 'Local ARTbeat ENC Art Capture Tour - Rocky Mount',
    venue: 'Downtown Rocky Mount',
    startDate: '2026-05-03',
    startTime: '2:00 PM',
    endTime: '4:00 PM',
    excerpt: 'Explore downtown and capture public art with Local ARTbeat',
    imageUrl:
        'https://www.localartbeat.com/wp-content/uploads/2025/12/rocky_mount_enc_tour_2026.png',
  ),
  TourEvent(
    name: 'Local ARTbeat ENC Art Capture Tour - Snow Hill',
    venue: 'Downtown Snow Hill',
    startDate: '2026-05-10',
    startTime: '2:00 PM',
    endTime: '4:00 PM',
    excerpt: 'Explore downtown and capture public art with Local ARTbeat',
    imageUrl:
        'https://www.localartbeat.com/wp-content/uploads/2025/12/snow_hill_enc_tour_2026.png',
  ),
  TourEvent(
    name: 'Local ARTbeat ENC Art Capture Tour - Burgaw',
    venue: 'Downtown Burgaw',
    startDate: '2026-05-17',
    startTime: '2:00 PM',
    endTime: '4:00 PM',
    excerpt: 'Explore downtown and capture public art with Local ARTbeat',
    imageUrl:
        'https://www.localartbeat.com/wp-content/uploads/2025/12/burgaw_enc_tour_2026.png',
  ),
  TourEvent(
    name: 'Local ARTbeat ENC Art Capture Tour - Beaufort',
    venue: 'Downtown Beaufort',
    startDate: '2026-05-24',
    startTime: '2:00 PM',
    endTime: '4:00 PM',
    excerpt: 'Walk the waterfront and capture public art using Local ARTbeat',
    imageUrl:
        'https://www.localartbeat.com/wp-content/uploads/2025/12/beaufort_enc_tour_2026.png',
  ),
  TourEvent(
    name: 'Local ARTbeat ENC Art Capture Tour - Elizabeth City',
    venue: 'Downtown Elizabeth City',
    startDate: '2026-05-31',
    startTime: '2:00 PM',
    endTime: '4:00 PM',
    excerpt: 'Explore downtown and capture public art using Local ARTbeat',
    imageUrl:
        'https://www.localartbeat.com/wp-content/uploads/2025/12/elizabeth_city_enc_tour_2026.png',
  ),
  TourEvent(
    name: 'Local ARTbeat ENC Art Capture Tour - Greenville',
    venue: 'Downtown Greenville',
    startDate: '2026-06-07',
    startTime: '2:00 PM',
    endTime: '4:00 PM',
    excerpt: 'Explore downtown and capture public art using Local ARTbeat',
    imageUrl:
        'https://www.localartbeat.com/wp-content/uploads/2025/12/greenville_enc_tour_2026.png',
  ),
  TourEvent(
    name: 'Local ARTbeat ENC Art Capture Tour - Havelock',
    venue: 'Downtown Havelock',
    startDate: '2026-06-14',
    startTime: '2:00 PM',
    endTime: '4:00 PM',
    excerpt: 'Explore downtown and capture public art using Local ARTbeat',
    imageUrl:
        'https://www.localartbeat.com/wp-content/uploads/2025/12/havelock_enc_tour_2026.png',
  ),
  TourEvent(
    name: 'Local ARTbeat ENC Art Capture Tour - Clinton',
    venue: 'Downtown Clinton',
    startDate: '2026-06-21',
    startTime: '2:00 PM',
    endTime: '4:00 PM',
    excerpt: 'Explore downtown and capture public art using Local ARTbeat',
    imageUrl:
        'https://www.localartbeat.com/wp-content/uploads/2025/12/clinton_enc_tour_2026.png',
  ),
  TourEvent(
    name: 'Local ARTbeat ENC Art Capture Tour - Morehead City',
    venue: 'Downtown Morehead City',
    startDate: '2026-06-28',
    startTime: '2:00 PM',
    endTime: '4:00 PM',
    excerpt:
        'Walk downtown and waterfront areas capturing art with Local ARTbeat',
    imageUrl:
        'https://www.localartbeat.com/wp-content/uploads/2025/12/morehead_city_enc_tour_2026.png',
  ),
  TourEvent(
    name: 'Local ARTbeat ENC Art Capture Tour - Fayetteville',
    venue: 'Downtown Fayetteville',
    startDate: '2026-07-05',
    startTime: '2:00 PM',
    endTime: '4:00 PM',
    excerpt: 'Explore downtown and capture public art using Local ARTbeat',
    imageUrl:
        'https://www.localartbeat.com/wp-content/uploads/2025/12/fayetteville_enc_tour_2026.png',
  ),
  TourEvent(
    name: 'Local ARTbeat ENC Art Capture Tour - Wilmington',
    venue: 'Downtown Wilmington',
    startDate: '2026-07-12',
    startTime: '2:00 PM',
    endTime: '4:00 PM',
    excerpt: 'Explore downtown and capture public art using Local ARTbeat',
    imageUrl:
        'https://www.localartbeat.com/wp-content/uploads/2025/12/wilmington_enc_tour_2026.png',
  ),
];
