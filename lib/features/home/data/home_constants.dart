class HomeCircleItem {
  const HomeCircleItem({
    required this.title,
    required this.imagePath,
    this.placeholderText,
    this.id,
    this.description,
    this.date,
    this.raw,
  });

  final String title;
  final String imagePath;
  final String? placeholderText;

  /// Optional backend id. Currently used by the Donations section so that
  /// tapping a tile can deep-link straight into the donation flow.
  final String? id;

  /// Optional long-form description carried alongside [title] for screens
  /// that need it (e.g. the donation details screen).
  final String? description;

  /// Optional ISO/date string from backend, used for calendar deep-links.
  final String? date;

  /// Original backend payload for detail pages that need richer arguments.
  final Map<String, dynamic>? raw;
}

class HomeConstants {
  static const String userName = 'Aarav Sharma';
  static const String dateAndTithi = '31st May, 2067 | Ekadashi';
  static const String quote = 'योग: कर्मसु कौशलम्';
  static const String quoteSubtext = 'Yoga is skill in action';

  static const List<HomeCircleItem> upcomingPooja = [
    HomeCircleItem(
      title: 'Ganesh\nPooja',
      imagePath: 'assets/images/home/ganesh.png',
    ),
    HomeCircleItem(
      title: 'Lakshmi\nPooja',
      imagePath: 'assets/images/home/lakshmi.png',
    ),
    HomeCircleItem(
      title: 'Shiva\nAbhishekam',
      imagePath: 'assets/images/home/shiva.png',
    ),
  ];

  static const List<HomeCircleItem> upcomingFestivals = [
    HomeCircleItem(
      title: 'Ganesh\nChaturthi',
      imagePath: 'assets/images/appLogo.png',
    ),
    HomeCircleItem(title: 'Diwali', imagePath: 'assets/images/appLogo.png'),
  ];

  static const List<HomeCircleItem> donations = [
    HomeCircleItem(
      title: 'Annadanam',
      imagePath: 'assets/images/home/annadanam.png',
    ),
    HomeCircleItem(
      title: 'Yoga\nCenters',
      imagePath: 'assets/images/home/yoga.png',
    ),
    HomeCircleItem(
      title: 'Goshala',
      imagePath: 'assets/images/home/goshala.png',
    ),
    HomeCircleItem(
      title: 'Orphanage',
      imagePath: 'assets/images/home/orphane.png',
    ),
    HomeCircleItem(
      title: 'Temple\nConstruction',
      imagePath: 'assets/images/home/temple.png',
    ),
  ];
}
