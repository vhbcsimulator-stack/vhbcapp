import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as ypf;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:pdfrx/pdfrx.dart' as pdfrx;
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'youtube_embed_stub.dart'
    if (dart.library.html) 'youtube_embed_web.dart';
import 'map_embed_stub.dart' if (dart.library.html) 'map_embed_web.dart';
import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart'
    if (dart.library.io) 'download_helper_io.dart';
import 'cache_manager.dart';
import 'optimized_image.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/env.txt');

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception(
      'Missing Supabase configuration. Please set SUPABASE_URL and SUPABASE_ANON_KEY in .env',
    );
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F88D5),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF6F9FC),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: Colors.grey[600],
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: const Color(0xFF0F88D5),
          foregroundColor: Colors.white,
        ),
        tabBarTheme: TabBarTheme(
          labelColor: colorScheme.primary,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: colorScheme.primary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F88D5),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goToHome();
  }

  Future<void> _goToHome() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoWidth = min(screenWidth * 0.55, 240.0);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'image_assets/splash_screen.png',
                width: logoWidth,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 18),
              const Text(
                'VHBC App',
                style: TextStyle(
                  color: Color(0xFF0F88D5),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _selectedProject = 0;
  String _selectedPhase = 'Phase 1';
  String _selectedLotCategory = 'Regular';
  int _computeTabIndex = 0;
  int _faqTabIndex = 0;
  double _downpaymentIndex = 0;
  double _phaseIndex = 0;
  double _lotCategoryIndex = 0;
  double _paymentYears = 1;
  bool _isPaymentYearsEnabled = true;
  double _tcpAmount = 0;
  double _pricePerSqm = 0;
  double _originalPricePerSqm = 0;
  double _monthlyAmortization = 0;
  bool _isComputing = false;
  double _floorLevelIndex = 0;
  String _selectedFloorLevel = '2nd';
  double _viewIndex = 0;
  String _selectedView = 'Nature View';
  String _selectedEndUnit = 'No';
  String _selectedFurnish = 'Semi Finished';
  bool _isLoadingMedia = false;
  bool _isLoadingFutureMedia = false;
  String? _mediaError;
  String? _futureMediaError;
  bool _isLoadingVideos = false;
  String? _videosError;
  List<String> _projectDevImages = [];
  List<String> _futureDevImages = [];
  bool _futureMediaFetched = false;
  final Map<String, List<_YoutubeVideoItem>> _youtubeVideosByProject = {};
  bool _notificationsInitialized = false;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  RealtimeChannel? _announcementsChannel;
  bool _isLoadingAnnouncements = false;
  String? _announcementsError;
  List<_AnnouncementItem> _announcements = [];
  bool _isLoadingFaqDoc = false;
  Uint8List? _faqPdfBytes;
  String? _faqError;
  final Map<String, Uint8List> _faqPdfCache = {};
  final PdfViewerController _faqPdfController = PdfViewerController();
  final pdfrx.PdfViewerController _faqPdfControllerWeb =
      pdfrx.PdfViewerController();
  double _faqZoomLevel = 1.0;
  final List<_HermosaChatMessage> _hermosaMessages = [];
  late final TextEditingController _hermosaMessageController;
  late final ScrollController _hermosaScrollController;
  bool _hermosaKbReady = false;
  bool _hermosaKbLoading = false;
  String? _hermosaKbError;
  final List<_HermosaKbChunk> _hermosaKbChunks = [];
  void _openImageGalleryFullScreen(
    BuildContext viewContext,
    List<String> images,
    int startIndex, {
    List<String>? captions,
  }) {
    if (images.isEmpty) return;
    _warmImageCache(images);
    final initialPage = startIndex.clamp(0, images.length - 1);
    final controller = PageController(initialPage: initialPage);
    final transformationControllers = List.generate(
      images.length,
      (_) => TransformationController(),
    );
    int activeIndex = initialPage;
    bool isZoomed = false;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          return StatefulBuilder(
            builder: (context, setState) {
              int currentIndex = controller.hasClients
                  ? controller.page?.round() ?? initialPage
                  : initialPage;
              if (currentIndex != activeIndex) {
                activeIndex = currentIndex;
                isZoomed = transformationControllers[activeIndex]
                        .value
                        .getMaxScaleOnAxis() >
                    1.01;
              }
              return Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  backgroundColor: Colors.black,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: Text(
                    captions != null && captions.length == images.length
                        ? captions[currentIndex]
                        : '${currentIndex + 1}/${images.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  actions: [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      color: Colors.white,
                      onSelected: (value) {
                        if (value == 'download') {
                          final name = captions != null &&
                                  captions.length == images.length
                              ? captions[currentIndex]
                              : 'image';
                          _downloadImage(context, images[currentIndex], name);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'download',
                          child: Text('Download'),
                        ),
                      ],
                    ),
                  ],
                ),
                body: PageView.builder(
                  controller: controller,
                  onPageChanged: (idx) {
                    setState(() {
                      activeIndex = idx;
                      isZoomed = transformationControllers[activeIndex]
                              .value
                              .getMaxScaleOnAxis() >
                          1.01;
                    });
                  },
                  physics: isZoomed
                      ? const NeverScrollableScrollPhysics()
                      : const PageScrollPhysics(),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final url = images[index];
                    final size = MediaQuery.of(viewContext).size;
                    return Center(
                      child: SizedBox.expand(
                        child: Listener(
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: (_) {},
                          child: InteractiveViewer(
                            transformationController:
                                transformationControllers[index],
                            minScale: 1.0,
                            maxScale: 50.0,
                            scaleEnabled: true,
                            panEnabled: true,
                            onInteractionUpdate: (_) {
                              if (!mounted) return;
                              if (index == activeIndex) {
                                final nowZoomed =
                                    transformationControllers[index]
                                            .value
                                            .getMaxScaleOnAxis() >
                                        1.01;
                                if (nowZoomed != isZoomed) {
                                  setState(() => isZoomed = nowZoomed);
                                }
                              }
                            },
                            child: _cachedNetworkImage(
                              viewContext,
                              url,
                              height: size.height,
                              width: size.width,
                              fit: BoxFit.contain,
                              useFullQuality:
                                  true, // Load full quality in fullscreen
                              placeholder: const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                              error: const Text(
                                'Failed to load image.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  bool _isLoadingSalesMap = false;
  String? _salesMapError;
  Map<int, String> _salesMapImages = {};
  Map<int, String> _salesMapCommercialImages = {};
  String? _erhdSalesMapImage;
  List<_SalesMapGalleryItem> _msccSalesMapItems = [];
  late final TextEditingController _lotSizeController;
  late final AnimationController _homeAnimController;
  late final Animation<double> _heroBgOpacity;
  late final Animation<double> _heroTextOpacity;
  late final Animation<Offset> _heroTextSlide;
  late final Animation<double> _cardsScale;
  late final Animation<double> _cardsOpacity;
  late final TabController _computeTabController;
  late final TabController _faqTabController;

  final List<String> _defaultPhases = const ['Phase 1', 'Phase 2', 'Phase 3'];
  final List<String> _defaultLotCategories = const [
    'Regular',
    'Regular Corner',
    'Prime',
    'Prime Corner',
    'Commercial',
    'Commercial Corner',
  ];
  final List<String> _msccUnitTypes = const [
    '1 Bed Room',
    '2 Bed Room',
    '2 Bed Room Deluxe',
  ];
  final List<String> _mvlcLotCategories = const [
    'Regular',
    'Regular Corner',
    'Prime',
    'Prime Corner',
    'Commercial',
    'Commercial Corner',
    'Prime Commercial',
    'Prime Commercial Corner',
  ];
  final List<String> _erhdLotCategories = const [
    'Regular',
    'Prime',
    'Prime Corner',
  ];
  final List<String> _msccFloorLevels = const [
    '2nd',
    '3rd',
    '4th',
    '5th',
    '6th',
  ];
  final List<String> _msccViewOptions = const [
    'Nature View',
    'Facing Amenities',
  ];
  final List<String> _msccEndUnitOptions = const ['Yes', 'No'];
  List<String> get _msccFurnishOptions => const [
        'Semi Finished',
        'Bare',
        'Fully Finished',
      ];
  final List<int> _defaultDownpaymentOptions = const [0, 10, 30, 50, 100];
  final List<int> _msccDownpaymentOptions = const [30, 50, 100];
  late List<String> _phaseOptions = List.from(_defaultPhases);
  late List<String> _lotCategoryOptions = List.from(_mvlcLotCategories);
  late List<int> _downpaymentOptions = List.from(_defaultDownpaymentOptions);

  final List<String> _titles = const [
    'Home',
    'Media',
    'Sales Map',
    'Compute',
    'Announcements',
    'Hermosa',
  ];

  final List<String> _projects = const ['MVLC', 'ERHD', 'MSCC'];
  final List<String> _projectTitles = const [
    'Mountain View Leisure Community',
    'Eastwest Resorts Hub and Development',
    'Mountain Suites & Country Club',
  ];
  final Map<String, String> _projectImages = const {
    'MVLC': 'image_assets/mvlc.jpeg',
    'ERHD': 'image_assets/erhd.jpeg',
    'MSCC': 'image_assets/mscc.png',
  };
  final List<String> _projectLocations = const [
    'Nasugbu, Batangas',
    'Indang, Cavite',
    'Nasugbu, Batangas',
  ];

  bool get _isMsccProject => _projects[_selectedProject] == 'MSCC';

  @override
  void initState() {
    super.initState();
    _lotSizeController = TextEditingController();
    _homeAnimController = AnimationController(
      duration: const Duration(milliseconds: 1300),
      vsync: this,
    );
    _computeTabController = TabController(length: 2, vsync: this);
    _computeTabController.addListener(_onComputeTabChanged);
    _faqTabController = TabController(length: 2, vsync: this);
    _faqTabController.addListener(_onFaqTabChanged);
    _hermosaMessageController = TextEditingController();
    _hermosaScrollController = ScrollController();

    _heroBgOpacity = CurvedAnimation(
      parent: _homeAnimController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _heroTextOpacity = CurvedAnimation(
      parent: _homeAnimController,
      curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
    );
    _heroTextSlide =
        Tween<Offset>(begin: const Offset(0, -0.25), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _homeAnimController,
        curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
      ),
    );
    _cardsScale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(
        parent: _homeAnimController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOutBack),
      ),
    );
    _cardsOpacity = CurvedAnimation(
      parent: _homeAnimController,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
    );

    _homeAnimController.forward();
    _updatePaymentYearsConstraints();
    if (_selectedProject == 0 || _selectedProject == 1 || _isMsccProject) {
      _loadSalesMaps();
    }
    _setupAnnouncementNotifications();
  }

  @override
  void dispose() {
    _lotSizeController.dispose();
    _homeAnimController.dispose();
    _computeTabController.removeListener(_onComputeTabChanged);
    _computeTabController.dispose();
    _faqTabController.removeListener(_onFaqTabChanged);
    _faqTabController.dispose();
    _hermosaMessageController.dispose();
    _hermosaScrollController.dispose();
    _announcementsChannel?.unsubscribe();
    super.dispose();
  }

  void _adjustFaqZoom(double delta) {
    if (kIsWeb) {
      if (!_faqPdfControllerWeb.isReady) return;
      final newZoom =
          (_faqPdfControllerWeb.currentZoom + delta).clamp(1.0, 4.0).toDouble();
      _faqPdfControllerWeb.setZoom(
        _faqPdfControllerWeb.centerPosition,
        newZoom,
        // duration: Duration.zero,
      );
      setState(() => _faqZoomLevel = newZoom);
      return;
    }
    final newZoom =
        (_faqPdfController.zoomLevel + delta).clamp(1.0, 4.0).toDouble();
    _faqPdfController.zoomLevel = newZoom;
    setState(() => _faqZoomLevel = newZoom);
  }

  void _openFaqPdfFullScreen(BuildContext context) {
    final pdfBytes = _faqPdfBytes;
    if (pdfBytes == null) return;
    final assetPath = _faqAssetPathForProject(_projects[_selectedProject]);
    final projectTitle =
        _selectedProject >= 0 && _selectedProject < _projectTitles.length
            ? _projectTitles[_selectedProject]
            : 'Project';
    final controller = PdfViewerController()..zoomLevel = _faqZoomLevel;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          if (kIsWeb && assetPath != null) {
            final webController = pdfrx.PdfViewerController();
            return Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                title: Text(
                  'FAQs $projectTitle',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              body: SafeArea(
                child: pdfrx.PdfViewer.asset(
                  assetPath,
                  controller: webController,
                  params: _faqPdfrxParams(),
                ),
              ),
            );
          }
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                'FAQs $projectTitle',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            body: SafeArea(
              child: SfPdfViewer.memory(
                pdfBytes,
                controller: controller,
                canShowPaginationDialog: false,
                canShowScrollHead: true,
                canShowScrollStatus: true,
                interactionMode: PdfInteractionMode.pan,
              ),
            ),
          );
        },
      ),
    );
  }

  void _openCompanyProfileFullScreen(BuildContext context) {
    const assetPath = 'assets/company_profile.pdf';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          if (kIsWeb) {
            final webController = pdfrx.PdfViewerController();
            return Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                title: const Text(
                  'Company Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              body: SafeArea(
                child: pdfrx.PdfViewer.asset(
                  assetPath,
                  controller: webController,
                  params: _companyProfilePdfrxParams(),
                ),
              ),
            );
          }
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text(
                'Company Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            body: SafeArea(
              child: SfPdfViewer.asset(
                assetPath,
                canShowPaginationDialog: false,
                canShowScrollHead: true,
                canShowScrollStatus: true,
                interactionMode: PdfInteractionMode.pan,
              ),
            ),
          );
        },
      ),
    );
  }

  void _onComputeTabChanged() {
    if (_computeTabIndex != _computeTabController.index &&
        !_computeTabController.indexIsChanging) {
      setState(() => _computeTabIndex = _computeTabController.index);
    }
  }

  void _onFaqTabChanged() {
    if (_faqTabIndex != _faqTabController.index &&
        !_faqTabController.indexIsChanging) {
      setState(() => _faqTabIndex = _faqTabController.index);
    }
  }

  double _contentMaxWidth(double width) {
    if (width >= 1280) return 1080;
    if (width >= 1024) return 960;
    if (width >= 840) return 820;
    return width;
  }

  double _pageHorizontalPadding(double width) {
    if (width >= 1024) return 32;
    if (width >= 720) return 24;
    return 16;
  }

  int _mediaGridColumns(double width) {
    return 2;
  }

  double _salesMapMediaHeight(double width) {
    final height = width * 9 / 16;
    return height.clamp(180.0, 320.0);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: _currentIndex <= 5
          ? null
          : AppBar(title: Text(_titles[_currentIndex]), centerTitle: true),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            _homeAnimController.forward(from: 0);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library_outlined),
            activeIcon: Icon(Icons.photo_library),
            label: 'Media',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Sales Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate_outlined),
            activeIcon: Icon(Icons.calculate),
            label: 'Compute',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_outlined),
            activeIcon: Icon(Icons.campaign),
            label: 'Announcements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.help_outline),
            activeIcon: Icon(Icons.help),
            label: 'Hermosa',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHome();
      case 1:
        return _buildMedia();
      case 2:
        return _buildSalesMapTab();
      case 3:
        return _buildCompute();
      case 4:
        return _buildAnnouncements();
      case 5:
        return _buildFaqs();
      default:
        return _placeholder('Home');
    }
  }

  void _onLotSizeChanged(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null) {
      _resetLotOptions();
    }
  }

  void _onProjectSelected(int index) {
    final projectCode = _projects[index];
    setState(() {
      _selectedProject = index;
      _salesMapError = null;
      _salesMapImages = {};
      _salesMapCommercialImages = {};
      _erhdSalesMapImage = null;
      _msccSalesMapItems = [];
      _phaseOptions = List.from(_defaultPhases);
      _phaseIndex = 0;
      _selectedPhase = _phaseOptions.first;
      _lotCategoryOptions = _lotOptionsForProject(index);
      _lotCategoryIndex = 0;
      _selectedLotCategory = _lotCategoryOptions.first;
      _floorLevelIndex = 0;
      _selectedFloorLevel = _msccFloorLevels.first;
      _viewIndex = 0;
      _selectedView = _msccViewOptions.first;
      _selectedEndUnit = _msccEndUnitOptions.last;
      _selectedFurnish = _msccFurnishOptions.first;
      _downpaymentOptions = _downpaymentOptionsForProject(index);
      _downpaymentIndex = 0;
      _paymentYears = 1;
      _isPaymentYearsEnabled = true;
      _faqError = null;
      _isLoadingFaqDoc = false;
      _faqPdfBytes = _faqPdfCache[projectCode];
      _videosError = null;
      _isLoadingVideos = false;
      _tcpAmount = 0;
      _pricePerSqm = 0;
      _originalPricePerSqm = 0;
      _monthlyAmortization = 0;
    });
    _lotSizeController.text = '';
    _updatePaymentYearsConstraints();
    if ((index == 0 || index == 1 || index == 2) && !_isLoadingSalesMap) {
      _loadSalesMaps();
    }
    _projectDevImages = [];
    _mediaError = null;
    _isLoadingMedia = false;
    _futureDevImages = [];
    _futureMediaError = null;
    _isLoadingFutureMedia = false;
    _futureMediaFetched = false;
  }

  void _resetLotOptions() {
    setState(() {
      _lotCategoryOptions = _lotOptionsForProject(_selectedProject);
      _phaseOptions = List.from(_defaultPhases);
      _selectedLotCategory = _lotCategoryOptions.first;
      _selectedPhase = _phaseOptions.first;
      _lotCategoryIndex = 0;
      _phaseIndex = 0;
      _floorLevelIndex = 0;
      _selectedFloorLevel = _msccFloorLevels.first;
      _viewIndex = 0;
      _selectedView = _msccViewOptions.first;
      _selectedEndUnit = _msccEndUnitOptions.last;
      _selectedFurnish = _msccFurnishOptions.first;
      _downpaymentOptions = _downpaymentOptionsForProject(_selectedProject);
      _downpaymentIndex = 0;
    });
    _updatePaymentYearsConstraints();
  }

  List<String> _lotOptionsForProject(int projectIndex) {
    final safeIndex = projectIndex.clamp(0, _projects.length - 1);
    final project = _projects[safeIndex];
    if (project == 'ERHD') {
      return List.from(_erhdLotCategories);
    }
    if (project == 'MVLC') {
      return List.from(_mvlcLotCategories);
    }
    if (project == 'MSCC') {
      return List.from(_msccUnitTypes);
    }
    return List.from(_defaultLotCategories);
  }

  List<int> _downpaymentOptionsForProject(int projectIndex) {
    final safeIndex = projectIndex.clamp(0, _projects.length - 1);
    final project = _projects[safeIndex];
    if (project == 'MSCC') {
      return List.from(_msccDownpaymentOptions);
    }
    return List.from(_defaultDownpaymentOptions);
  }

  Future<void> _loadProjectDevImages() async {
    if (_isLoadingMedia) return;
    setState(() {
      _isLoadingMedia = true;
      _mediaError = null;
    });

    try {
      final project = _projects[_selectedProject];
      final dynamic response = await Supabase.instance.client
          .from('project_dev')
          .select('image_link,project_name')
          .eq('project_name', project);

      final dataList = response is List
          ? response
          : (response is Map && response['data'] is List
              ? response['data'] as List<dynamic>
              : <dynamic>[]);

      final images = <String>[];
      for (final item in dataList) {
        if (item is! Map) continue;
        final projectName = item['project_name']?.toString();
        if (projectName == null ||
            projectName.toUpperCase() != project.toUpperCase()) continue;
        final imageValue = item['image_link'] ??
            item['imageLink'] ??
            item['image_url'] ??
            item['image_URL'];
        final image = imageValue?.toString();
        if (image != null && image.isNotEmpty) {
          images.add(image);
        }
      }

      setState(() {
        _projectDevImages = images;
      });
      _warmImageCache(images);
    } catch (e) {
      setState(() {
        _mediaError = 'Failed to load media: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMedia = false;
        });
      }
    }
  }

  Future<void> _loadFutureDevImages() async {
    if (_isLoadingFutureMedia) return;
    setState(() {
      _isLoadingFutureMedia = true;
      _futureMediaError = null;
    });

    try {
      final project = _projects[_selectedProject];
      final dynamic response = await Supabase.instance.client
          .from('future_dev')
          .select('image_link,project_name')
          .eq('project_name', project);

      final dataList = response is List
          ? response
          : (response is Map && response['data'] is List
              ? response['data'] as List<dynamic>
              : <dynamic>[]);

      final images = <String>[];
      for (final item in dataList) {
        if (item is! Map) continue;
        final projectName = item['project_name']?.toString();
        if (projectName == null ||
            projectName.toUpperCase() != project.toUpperCase()) continue;
        final imageValue = item['image_link'] ??
            item['imageLink'] ??
            item['image_url'] ??
            item['image_URL'];
        final image = imageValue?.toString();
        if (image != null && image.isNotEmpty) {
          images.add(image);
        }
      }

      setState(() {
        _futureDevImages = images;
      });
      _warmImageCache(images);
    } catch (e) {
      setState(() {
        _futureMediaError = 'Failed to load media: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFutureMedia = false;
          _futureMediaFetched = true;
        });
      } else {
        _futureMediaFetched = true;
      }
    }
  }

  String? _extractYoutubeVideoId(String rawLink) {
    final link = rawLink.trim();
    if (link.isEmpty) return null;
    final idFromHelper = ypf.YoutubePlayer.convertUrlToId(link);
    if (idFromHelper != null && idFromHelper.isNotEmpty) return idFromHelper;
    final directIdPattern = RegExp(r'^[A-Za-z0-9_-]{6,}$');
    if (directIdPattern.hasMatch(link)) return link;
    return null;
  }

  Future<void> _loadYoutubeLinks() async {
    if (_isLoadingVideos) return;
    final project = _projects[_selectedProject];
    setState(() {
      _isLoadingVideos = true;
      _videosError = null;
    });

    try {
      final dynamic response = await Supabase.instance.client
          .from('youtube_links')
          .select('link,title,project_name')
          .eq('project_name', project);

      final dataList = response is List
          ? response
          : (response is Map && response['data'] is List
              ? response['data'] as List<dynamic>
              : <dynamic>[]);

      final videos = <_YoutubeVideoItem>[];
      for (final item in dataList) {
        if (item is! Map) continue;
        final projectName = item['project_name']?.toString();
        if (projectName == null ||
            projectName.toUpperCase() != project.toUpperCase()) continue;

        final rawLink = (item['link'] ??
                item['url'] ??
                item['video_link'] ??
                item['videoUrl'])
            ?.toString();
        if (rawLink == null || rawLink.trim().isEmpty) continue;
        final videoId = _extractYoutubeVideoId(rawLink);
        if (videoId == null) continue;

        final title = (item['title'] ?? 'Project Video').toString().trim();
        videos.add(
          _YoutubeVideoItem(
            id: videoId,
            title: title.isEmpty ? 'Project Video' : title,
            originalLink: rawLink,
          ),
        );
      }

      setState(() {
        _youtubeVideosByProject[project] = videos;
      });
    } catch (e) {
      setState(() {
        _videosError = 'Failed to load videos: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingVideos = false;
        });
      }
    }
  }

  Future<void> _loadAnnouncements() async {
    if (_isLoadingAnnouncements) return;
    setState(() {
      _isLoadingAnnouncements = true;
      _announcementsError = null;
    });

    try {
      final dynamic response = await Supabase.instance.client
          .from('announcements')
          .select('title,content,created_at')
          .order('created_at', ascending: false);

      final dataList = response is List
          ? response
          : (response is Map && response['data'] is List
              ? response['data'] as List<dynamic>
              : <dynamic>[]);

      final announcements = <_AnnouncementItem>[];
      for (final item in dataList) {
        if (item is! Map) continue;
        final title = (item['title'] ?? '').toString().trim();
        final content = (item['content'] ?? '').toString().trim();
        final createdAtRaw = item['created_at'];
        DateTime? createdAt;
        if (createdAtRaw is DateTime) {
          createdAt = createdAtRaw;
        } else if (createdAtRaw != null) {
          createdAt = DateTime.tryParse(createdAtRaw.toString());
        }
        if (title.isEmpty && content.isEmpty) continue;
        announcements.add(
          _AnnouncementItem(
            title: title.isEmpty ? 'Untitled announcement' : title,
            content: content,
            createdAt: createdAt,
          ),
        );
      }

      setState(() {
        _announcements = announcements;
      });
    } catch (e) {
      setState(() {
        _announcementsError = 'Failed to load announcements: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAnnouncements = false;
        });
      }
    }
  }

  Future<void> _setupAnnouncementNotifications() async {
    await _initializeNotifications();
    if (!mounted) return;
    _subscribeToAnnouncementChanges();
  }

  Future<void> _initializeNotifications() async {
    if (_notificationsInitialized) return;

    // Keep the small icon to the default launcher icon for compatibility; use splash image as large icon later.
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _localNotifications.initialize(settings);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _notificationsInitialized = true;
  }

  void _subscribeToAnnouncementChanges() {
    _announcementsChannel?.unsubscribe();
    _announcementsChannel = Supabase.instance.client.channel(
      'public:announcements',
    );

    _announcementsChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'announcements',
          callback: (payload) {
            final record = payload.newRecord;
            final title = (record['title'] ?? '').toString().trim();
            _showAnnouncementNotification(
              title.isEmpty ? 'New announcement posted' : title,
            );
          },
        )
        .subscribe();
  }

  Future<void> _showAnnouncementNotification(String title) async {
    if (!_notificationsInitialized) return;
    const androidDetails = AndroidNotificationDetails(
      'announcements_channel',
      'Announcements',
      channelDescription: 'Notifications for new announcements',
      importance: Importance.max,
      priority: Priority.high,
      largeIcon: DrawableResourceAndroidBitmap('ic_notification'),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'New Announcement',
      title,
      details,
    );
  }

  bool _isSvgUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    // Check file extension
    final path = uri.path.toLowerCase();
    if (path.endsWith('.svg')) return true;

    // Check query parameters for format
    final format = uri.queryParameters['format']?.toLowerCase();
    if (format == 'svg') return true;

    return false;
  }

  Widget _cachedNetworkImage(
    BuildContext context,
    String url, {
    double? height,
    double? width,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? error,
    bool useFullQuality = false,
    bool allowOptimization = true,
  }) {
    final normalizedUrl = _normalizeImageUrl(url);
    // Check if the URL is an SVG file
    if (_isSvgUrl(normalizedUrl)) {
      return SvgPicture.network(
        normalizedUrl,
        width: width,
        height: height,
        fit: fit,
        placeholderBuilder: (context) => Container(
          height: height,
          width: width,
          color: const Color(0xFFF4F7FB),
          alignment: Alignment.center,
          child: placeholder ??
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
        ),
      );
    }

    final mediaQuery = MediaQuery.of(context);
    final dpr = mediaQuery.devicePixelRatio;
    final effectiveWidth =
        (width != null && width.isFinite ? width : mediaQuery.size.width);

    final optimizedUrl = allowOptimization
        ? _optimizedImageUrl(
            normalizedUrl,
            logicalWidth: effectiveWidth,
            logicalHeight: height,
            devicePixelRatio: dpr,
          )
        : normalizedUrl;

    final provider = NetworkImage(optimizedUrl);
    bool evicted = false;

    return Image(
      image: provider,
      width: width,
      height: height,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame != null && !evicted) {
          // Evict from in-memory cache after first render.
          evicted = true;
          imageCache.evict(provider);
        }
        return child;
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          height: height,
          width: width,
          color: const Color(0xFFF4F7FB),
          alignment: Alignment.center,
          child: placeholder ??
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
        );
      },
      errorBuilder: (context, _, __) {
        if (allowOptimization && optimizedUrl != normalizedUrl) {
          return _cachedNetworkImage(
            context,
            normalizedUrl,
            width: width,
            height: height,
            fit: fit,
            placeholder: placeholder,
            error: error,
            allowOptimization: false,
          );
        }
        debugPrint('Image load failed: $optimizedUrl');
        return Container(
          height: height,
          width: width,
          color: const Color(0xFFF4F7FB),
          alignment: Alignment.center,
          child: error ??
              const Icon(
                Icons.broken_image,
                color: Color(0xFF6C7A89),
                size: 32,
              ),
        );
      },
    );
  }

  int _targetCacheWidthPx({
    double? logicalWidth,
    double? logicalHeight,
    double devicePixelRatio = 2.0,
  }) {
    final baseWidth = logicalWidth ??
        (logicalHeight != null
            ? logicalHeight * 1.2
            : 600); // rough fallback to avoid huge downloads
    final px = (baseWidth * devicePixelRatio).round();
    return px.clamp(320, 2048).toInt();
  }

  String _optimizedImageUrl(
    String url, {
    double? logicalWidth,
    double? logicalHeight,
    double devicePixelRatio = 2.0,
  }) {
    final normalizedUrl = _normalizeImageUrl(url);
    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null) return normalizedUrl;

    // Don't optimize SVG files
    if (_isSvgUrl(normalizedUrl)) return normalizedUrl;

    // Only rewrite Supabase storage URLs; otherwise return as-is.
    final host = uri.host.toLowerCase();
    final isSupabaseHost =
        host.contains('supabase.co') || host.contains('supabase.in');

    if (!isSupabaseHost) return normalizedUrl;

    const publicPrefix = '/storage/v1/object/public/';
    final isRenderPath = uri.path.contains('/storage/v1/render/image/');
    final isPublicObject = uri.path.contains(publicPrefix);
    if (!isRenderPath && !isPublicObject) {
      return normalizedUrl;
    }

    final targetWidthPx = _targetCacheWidthPx(
      logicalWidth: logicalWidth,
      logicalHeight: logicalHeight,
      devicePixelRatio: devicePixelRatio,
    );
    final targetHeightPx = logicalHeight != null
        ? _targetCacheWidthPx(
            logicalWidth: logicalHeight,
            devicePixelRatio: devicePixelRatio,
          )
        : null;

    final params = Map<String, String>.from(uri.queryParameters);
    params.putIfAbsent('format', () => 'webp');
    params.putIfAbsent('quality', () => '70');
    params['width'] = '$targetWidthPx';
    if (targetHeightPx != null) {
      params['height'] = '$targetHeightPx';
    }

    final renderPath = isRenderPath
        ? uri.path
        : uri.path.replaceFirst(
            publicPrefix,
            '/storage/v1/render/image/public/',
          );
    final optimizedUri = uri.replace(path: renderPath, queryParameters: params);
    return optimizedUri.toString();
  }

  String _normalizeImageUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;
    final encoded = Uri.encodeFull(trimmed);
    final uri = Uri.tryParse(encoded);
    if (uri == null) return encoded;
    if (uri.scheme == 'http') {
      return uri.replace(scheme: 'https').toString();
    }
    return uri.toString();
  }

  void _warmImageCache(List<String> urls, {double? logicalHeight}) {
    if (!mounted || urls.isEmpty) return;

    // Intentionally no-op: user requested no memory caching.
  }

  String _sanitizeFileName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[<>:"/\\\\|?*]'), '_').trim();
    return cleaned.isEmpty ? 'image' : cleaned;
  }

  Future<void> _downloadImage(
    BuildContext context,
    String url,
    String title,
  ) async {
    try {
      final sanitizedTitle = _sanitizeFileName(title.isEmpty ? 'image' : title);
      final now = DateTime.now();
      final timestamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final fileName = '${sanitizedTitle}_$timestamp.jpg';

      final savedPath = kIsWeb
          ? await saveUrlToDownloads(url, fileName)
          : await () async {
              final uri = Uri.parse(url);
              final byteData = await NetworkAssetBundle(
                uri,
              ).load(uri.toString());
              final bytes = byteData.buffer.asUint8List();
              return saveBytesToDownloads(bytes, fileName);
            }();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              savedPath != null
                  ? 'Downloaded to $savedPath'
                  : 'Download is not supported on this platform.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }

  Future<void> _downloadFaqPdf(String project) async {
    final assetPath = _faqAssetPathForProject(project);
    if (assetPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No FAQ document available to download.'),
          ),
        );
      }
      return;
    }

    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      final now = DateTime.now();
      final timestamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final fileName = '${_sanitizeFileName('$project FAQs')}_$timestamp.pdf';

      final savedPath = await saveBytesToDownloads(bytes, fileName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedPath != null
                ? 'Downloaded to $savedPath'
                : 'Download is not supported on this platform.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  Future<void> _loadSalesMaps() async {
    if (_isLoadingSalesMap) return;
    final project = _projects[_selectedProject].toUpperCase();
    setState(() {
      _isLoadingSalesMap = true;
      _salesMapError = null;
      _salesMapCommercialImages = {};
      _msccSalesMapItems = [];
    });

    try {
      final dynamic response = await Supabase.instance.client
          .from('uploads')
          .select('Phase,image_URL,project,type')
          .eq('project', project)
          .order('Phase');

      final dataList = response is List
          ? response
          : (response is Map && response['data'] is List
              ? response['data'] as List<dynamic>
              : <dynamic>[]);

      if (project == 'ERHD') {
        String? imageUrl;
        for (final item in dataList) {
          if (item is! Map) continue;
          final projectValue = item['project']?.toString();
          if (projectValue != null && projectValue.toUpperCase() != project)
            continue;
          final imageValue = item['image_URL'] ?? item['image_url'];
          final candidate = imageValue?.toString();
          if (candidate != null && candidate.isNotEmpty) {
            imageUrl = candidate;
            break;
          }
        }

        setState(() {
          _salesMapImages = {};
          _salesMapCommercialImages = {};
          _msccSalesMapItems = [];
          _erhdSalesMapImage = imageUrl;
          if (imageUrl == null) {
            _salesMapError = 'No sales map found for this project.';
          }
        });
        if (imageUrl != null) {
          _warmImageCache([imageUrl]);
        }
        return;
      }

      if (project == 'MSCC') {
        final msccItems = <MapEntry<int?, _SalesMapGalleryItem>>[];
        for (final item in dataList) {
          if (item is! Map) continue;
          final projectValue = item['project']?.toString();
          if (projectValue == null || projectValue.toUpperCase() != project)
            continue;
          final imageValue = item['image_URL'] ?? item['image_url'];
          final imageUrl = imageValue?.toString();
          if (imageUrl == null || imageUrl.isEmpty) continue;

          final phasesRow = item['phases'];
          final phaseUpper = item['Phase'] ?? item['phase'];
          final typeValue = item['type'] ?? item['Type'];

          int? phaseNumber;
          if (phaseUpper is num) {
            phaseNumber = phaseUpper.toInt();
          } else if (phaseUpper != null) {
            phaseNumber = int.tryParse(phaseUpper.toString());
          }
          if (phaseNumber == null &&
              phasesRow is Map &&
              phasesRow['name'] != null) {
            final nameString = phasesRow['name'].toString();
            final match = RegExp(r'\d+').firstMatch(nameString);
            if (match != null) {
              phaseNumber = int.tryParse(match.group(0)!);
            }
          }

          int? floorNumber = phaseNumber;
          if (floorNumber == null && typeValue != null) {
            final match = RegExp(r'\d+').firstMatch(typeValue.toString());
            if (match != null) {
              floorNumber = int.tryParse(match.group(0)!);
            }
          }

          final title = 'Floor ${floorNumber ?? (msccItems.length + 1)}';

          msccItems.add(
            MapEntry(
              floorNumber,
              _SalesMapGalleryItem(title: title, url: imageUrl),
            ),
          );
        }

        msccItems.sort((a, b) {
          final aNum = a.key;
          final bNum = b.key;
          if (aNum != null && bNum != null) {
            return aNum.compareTo(bNum);
          }
          if (aNum != null) return -1;
          if (bNum != null) return 1;
          return 0;
        });

        setState(() {
          _erhdSalesMapImage = null;
          _salesMapImages = {};
          _salesMapCommercialImages = {};
          _msccSalesMapItems = msccItems.map((e) => e.value).toList();
          if (_msccSalesMapItems.isEmpty) {
            _salesMapError = 'No sales maps found.';
          }
        });
        if (msccItems.isNotEmpty) {
          _warmImageCache(msccItems.map((e) => e.value.url).toList());
        }
        return;
      }

      if (dataList.isEmpty) {
        setState(() {
          _salesMapImages = {};
          _salesMapCommercialImages = {};
          _erhdSalesMapImage = null;
          _msccSalesMapItems = [];
          _salesMapError = 'No sales maps found.';
        });
        return;
      }

      final residentialImages = <int, String>{};
      final commercialImages = <int, String>{};
      for (final item in dataList) {
        if (item is! Map) continue;
        final phasesRow = item['phases'];
        final imageValue = item['image_URL'] ?? item['image_url'];
        final phaseUpper = item['Phase'] ?? item['phase'];
        final projectValue = item['project'];
        final typeValue = item['type'] ?? item['Type'];
        final normalizedType = typeValue?.toString().toLowerCase().trim();

        int? phaseNumber;
        // direct numeric Phase column (uppercase)
        if (phaseUpper is num) {
          phaseNumber = phaseUpper.toInt();
        } else if (phaseUpper != null) {
          phaseNumber = int.tryParse(phaseUpper.toString());
        }
        // fallback: parse from phases.name like "PHASE 1"
        if (phaseNumber == null &&
            phasesRow is Map &&
            phasesRow['name'] != null) {
          final nameString = phasesRow['name'].toString();
          final match = RegExp(r'\d+').firstMatch(nameString);
          if (match != null) {
            phaseNumber = int.tryParse(match.group(0)!);
          }
        }
        final projectString = projectValue?.toString();
        // ensure it matches the current project (MVLC)
        if (projectString != null && projectString.toUpperCase() != project) {
          continue;
        }

        final imageUrl = imageValue?.toString();
        final isCommercial = normalizedType == 'commercial';
        final isResidential = normalizedType == 'residential' ||
            normalizedType == null ||
            normalizedType.isEmpty;

        if (phaseNumber != null && imageUrl != null && imageUrl.isNotEmpty) {
          if (isCommercial) {
            commercialImages[phaseNumber] = imageUrl;
          } else if (isResidential && phaseNumber >= 1 && phaseNumber <= 3) {
            residentialImages[phaseNumber] = imageUrl;
          }
        }
      }

      setState(() {
        _erhdSalesMapImage = null;
        _salesMapImages = residentialImages;
        _salesMapCommercialImages = commercialImages;
        _msccSalesMapItems = [];
        if (_salesMapImages.isEmpty && _salesMapCommercialImages.isEmpty) {
          _salesMapError = 'No sales maps found.';
        }
      });
      final cacheImages = [
        ...residentialImages.values,
        ...commercialImages.values,
      ];
      if (cacheImages.isNotEmpty) {
        _warmImageCache(cacheImages);
      }
    } catch (e) {
      setState(() {
        _salesMapError = 'Failed to load sales maps. $e';
        _erhdSalesMapImage = null;
        _msccSalesMapItems = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSalesMap = false;
        });
      }
    }
  }

  void _updatePaymentYearsConstraints() {
    final downpayment = _downpaymentOptions[_downpaymentIndex.round()];
    if (_isMsccProject) {
      if (downpayment == 100) {
        _isPaymentYearsEnabled = false;
        _paymentYears = 1;
      } else {
        _isPaymentYearsEnabled = true;
        _paymentYears = _paymentYears.clamp(1, 10);
      }
      return;
    }

    if (downpayment == 0) {
      _isPaymentYearsEnabled = true;
      _paymentYears = _paymentYears.clamp(1, 7);
    } else if (downpayment == 100) {
      _isPaymentYearsEnabled = false;
      _paymentYears = 1;
    } else {
      _isPaymentYearsEnabled = true;
      if (_paymentYears > 5) {
        _paymentYears = 5;
      }
    }
  }

  double _discountedPricePerSqm(double basePrice, double lotSize) {
    final downpayment = _downpaymentOptions[_downpaymentIndex.round()];
    final project = _projects[_selectedProject];
    if (project == 'ERHD') {
      // ERHD fixed discount table
      if (downpayment == 100) return basePrice * 0.60;
      if (downpayment == 50) return basePrice * 0.70;
      if (downpayment == 30) return basePrice * 0.80;
      if (downpayment == 10) return basePrice * 0.90;
      return basePrice;
    }

    double discount = 0;
    final isLargeLot = lotSize >= 500;
    if (downpayment == 100) {
      discount = isLargeLot ? 0.35 : 0.30;
    } else if (downpayment == 50) {
      discount = isLargeLot ? 0.25 : 0.20;
    } else if (downpayment == 30) {
      discount = isLargeLot ? 0.20 : 0.15;
    } else if (downpayment == 10) {
      discount = 0.10;
    } else {
      discount = 0;
    }
    return basePrice * (1 - discount);
  }

  double _computeMonthlyAmortization(double tcp, double lotSize) {
    final downpayment = _downpaymentOptions[_downpaymentIndex.round()];
    const reservationFee = 20000.0;
    final dpAmount = tcp * (downpayment / 100);
    final balance = downpayment == 0 ? tcp - reservationFee : tcp - dpAmount;
    if (balance <= 0 || downpayment > 50) return 0;

    final isMsccProject = _projects[_selectedProject] == 'MSCC';
    final maxYears = isMsccProject ? 10 : 7;
    final years = _paymentYears.round().clamp(1, maxYears);
    double annualRate;
    if (isMsccProject) {
      if (years <= 2) {
        annualRate = 0;
      } else if (years <= 5) {
        annualRate = 0.14;
      } else {
        annualRate = 0.16;
      }
    } else {
      if (years <= 2) {
        annualRate = 0;
      } else if (years == 3) {
        annualRate = 0.12;
      } else if (years == 4) {
        annualRate = 0.14;
      } else {
        annualRate = 0.16;
      }
    }

    final months = years * 12;
    final monthlyRate = annualRate / 12;
    if (monthlyRate == 0) {
      return balance / months;
    }
    final factor = monthlyRate *
        (pow(1 + monthlyRate, months)) /
        (pow(1 + monthlyRate, months) - 1);
    return balance * factor;
  }

  double _applyMsccDiscount(double pricePerSqm) {
    if (_projects[_selectedProject] != 'MSCC') return pricePerSqm;
    final downpayment = _downpaymentOptions[_downpaymentIndex.round()];
    if (downpayment >= 100) return pricePerSqm * 0.70;
    if (downpayment >= 50) return pricePerSqm * 0.80;
    if (downpayment >= 30) return pricePerSqm * 0.90;
    return pricePerSqm;
  }

  double _downpaymentAmount(double tcp) {
    if (tcp <= 0) return 0;
    final percent = _downpaymentOptions[_downpaymentIndex.round()];
    return tcp * (percent / 100);
  }

  String _formatCurrency(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts[0];
    final cents = parts[1];
    final buffer = StringBuffer();
    for (int i = 0; i < whole.length; i++) {
      final idxFromEnd = whole.length - i;
      buffer.write(whole[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return '${buffer.toString()}.$cents';
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String _normalizeKey(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  double? _msccUnitAreaForSelection() {
    if (_projects[_selectedProject] != 'MSCC') return null;
    final unit = _selectedLotCategory.toLowerCase();
    if (unit.contains('1 bed')) return 27.0;
    if (unit.contains('2 bed room deluxe')) return 75.28;
    if (unit.contains('2 bed')) return 54.0;
    return null;
  }

  double _msccFloorAdditional(double baseTcp) {
    if (_projects[_selectedProject] != 'MSCC') return 0;
    final match = RegExp(r'\d+').firstMatch(_selectedFloorLevel);
    final floor = match != null ? int.tryParse(match.group(0) ?? '') ?? 0 : 0;
    double additionalRate = 0;
    if (floor == 3) {
      additionalRate = 0.03;
    } else if (floor == 4) {
      additionalRate = 0.06;
    } else if (floor == 5) {
      additionalRate = 0.09;
    } else if (floor >= 6) {
      additionalRate = 0.12;
    }
    return baseTcp * additionalRate;
  }

  double _msccViewAdditional(double baseTcp) {
    if (_projects[_selectedProject] != 'MSCC') return 0;
    return _selectedView.toLowerCase().contains('facing amenities')
        ? baseTcp * 0.05
        : 0;
  }

  double _msccEndUnitAdditional(double baseTcp) {
    if (_projects[_selectedProject] != 'MSCC') return 0;
    return _selectedEndUnit.toLowerCase() == 'yes' ? baseTcp * 0.20 : 0;
  }

  double _msccFurnishAdjustment(double baseTcp) {
    if (_projects[_selectedProject] != 'MSCC') return 0;
    final furnish = _selectedFurnish.toLowerCase();
    if (furnish.contains('bare')) return -300000.0;
    if (furnish.contains('fully')) return 500000.0;
    return 0;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _computeMsccPrice() async {
    setState(() {
      _isComputing = true;
      _tcpAmount = 0;
      _pricePerSqm = 0;
      _originalPricePerSqm = 0;
      _monthlyAmortization = 0;
    });

    try {
      final dynamic response =
          await Supabase.instance.client.from('mscc_price').select();
      final dataList = response is List
          ? response
          : (response is Map && response['data'] is List
              ? response['data'] as List<dynamic>
              : <dynamic>[]);

      Map<String, dynamic>? selectedRow;
      final normalizedUnit = _normalizeKey(_selectedLotCategory);
      final normalizedFloor = _normalizeKey(_selectedFloorLevel);
      final normalizedView = _normalizeKey(_selectedView);
      final normalizedEndUnit = _normalizeKey(_selectedEndUnit);
      final normalizedFurnish = _normalizeKey(_selectedFurnish);

      for (final item in dataList) {
        if (item is! Map) continue;
        final row = item.cast<String, dynamic>();
        final unitValue =
            (row['unit_type'] ?? row['unitType'] ?? row['unit'] ?? row['type'])
                ?.toString();
        if (unitValue == null || _normalizeKey(unitValue) != normalizedUnit)
          continue;

        bool matches = true;
        final floorValue =
            (row['floor_level'] ?? row['floorLevel'] ?? row['floor'])
                ?.toString();
        if (floorValue != null &&
            _normalizeKey(floorValue) != normalizedFloor) {
          matches = false;
        }
        final viewValue =
            (row['view'] ?? row['view_type'] ?? row['viewType'])?.toString();
        if (viewValue != null && _normalizeKey(viewValue) != normalizedView) {
          matches = false;
        }
        final endUnitValue = (row['end_unit'] ?? row['endUnit'])?.toString();
        if (endUnitValue != null &&
            _normalizeKey(endUnitValue) != normalizedEndUnit) {
          matches = false;
        }
        final furnishValue = (row['furnish'] ??
                row['furnish_type'] ??
                row['type_of_furnish'] ??
                row['furnishType'])
            ?.toString();
        if (furnishValue != null &&
            _normalizeKey(furnishValue) != normalizedFurnish) {
          matches = false;
        }

        selectedRow = matches ? row : (selectedRow ?? row);
        if (matches) break;
      }

      if (selectedRow == null) {
        for (final item in dataList) {
          if (item is Map) {
            selectedRow = item.cast<String, dynamic>();
            break;
          }
        }
      }

      if (selectedRow == null) {
        _showMessage('No price found for the selected MSCC unit.');
        return;
      }

      final pricePerSqm = _parseDouble(
        selectedRow['price_per_sqm'] ??
            selectedRow['pricePerSqm'] ??
            selectedRow['price'],
      );
      if (pricePerSqm == null) {
        _showMessage('Price per sqm is missing for the selected MSCC unit.');
        return;
      }

      final discountedPricePerSqm = _applyMsccDiscount(pricePerSqm);

      final unitArea = _parseDouble(
        selectedRow['area_sqm'] ??
            selectedRow['unit_area'] ??
            selectedRow['sqm'] ??
            selectedRow['floor_area'] ??
            selectedRow['area'],
      );
      final areaOverride = _msccUnitAreaForSelection();
      final effectiveArea = areaOverride ?? unitArea ?? 1.0;
      final baseTcp = discountedPricePerSqm * effectiveArea;
      final floorExtra = _msccFloorAdditional(baseTcp);
      final viewExtra = _msccViewAdditional(baseTcp);
      final endUnitExtra = _msccEndUnitAdditional(baseTcp);
      final furnishAdjust = _msccFurnishAdjustment(baseTcp);
      final tcp =
          baseTcp + floorExtra + viewExtra + endUnitExtra + furnishAdjust;
      final amortization = _computeMonthlyAmortization(tcp, effectiveArea);

      setState(() {
        _originalPricePerSqm = pricePerSqm;
        _pricePerSqm = discountedPricePerSqm;
        _tcpAmount = tcp;
        _monthlyAmortization = amortization;
      });

      if (unitArea == null) {}
    } catch (e) {
      setState(() {
        _tcpAmount = 0;
        _pricePerSqm = 0;
        _originalPricePerSqm = 0;
        _monthlyAmortization = 0;
      });
      _showMessage('Failed to fetch MSCC price: $e');
    } finally {
      if (mounted) {
        setState(() => _isComputing = false);
      }
    }
  }

  Future<void> _startComputation() async {
    if (_isComputing) return;
    final project = _projects[_selectedProject];
    final isMvProject = project == 'MVLC';
    final isErhdProject = project == 'ERHD';
    final isMsccProject = project == 'MSCC';
    if (isMsccProject) {
      await _computeMsccPrice();
      return;
    }
    if (!isMvProject && !isErhdProject) {
      setState(() {
        _tcpAmount = 0;
        _pricePerSqm = 0;
        _originalPricePerSqm = 0;
        _monthlyAmortization = 0;
      });
      _showMessage('Pricing is available for MVLC and ERHD only.');
      return;
    }

    final lotSize = double.tryParse(_lotSizeController.text.trim());
    if (lotSize == null || lotSize <= 0) {
      setState(() {
        _tcpAmount = 0;
        _pricePerSqm = 0;
        _originalPricePerSqm = 0;
        _monthlyAmortization = 0;
      });
      _showMessage('Enter a valid lot size.');
      return;
    }

    String categoryKey;
    if (isErhdProject) {
      // ERHD column mapping
      if (_selectedLotCategory == 'Regular') {
        categoryKey = 'regular';
      } else if (_selectedLotCategory == 'Prime') {
        categoryKey = 'prime';
      } else {
        categoryKey = 'prime_corner';
      }
    } else {
      categoryKey = _selectedLotCategory.toLowerCase().replaceAll(' ', '_');
    }
    int phaseNumber = 1;
    if (isMvProject) {
      final phaseNumberString = RegExp(
        r'\d+',
      ).firstMatch(_selectedPhase)?.group(0);
      final parsed =
          phaseNumberString != null ? int.tryParse(phaseNumberString) : null;
      phaseNumber = parsed ?? (_phaseIndex.round() + 1);
      if (phaseNumber < 1 || phaseNumber > _phaseOptions.length) {
        phaseNumber = 1;
      }
    }

    setState(() => _isComputing = true);

    try {
      final tableName = isMvProject ? 'mvlc_price' : 'erhd_price';
      final response = isMvProject
          ? await Supabase.instance.client
              .from(tableName)
              .select()
              .eq('phase', phaseNumber)
              .limit(1)
          : await Supabase.instance.client.from(tableName).select().limit(1);

      final dataList = response as List<dynamic>? ?? [];
      final data =
          dataList.isNotEmpty ? dataList.first as Map<String, dynamic>? : null;

      if (data == null || !data.containsKey(categoryKey)) {
        setState(() {
          _tcpAmount = 0;
          _pricePerSqm = 0;
          _originalPricePerSqm = 0;
          _monthlyAmortization = 0;
        });
        _showMessage(
          'No price found for ${isMvProject ? _selectedPhase : project} / $_selectedLotCategory.',
        );
        return;
      }

      final priceValue = data[categoryKey];
      final price = priceValue is num
          ? priceValue.toDouble()
          : double.tryParse(priceValue.toString());
      if (price == null) {
        setState(() {
          _tcpAmount = 0;
          _pricePerSqm = 0;
          _originalPricePerSqm = 0;
          _monthlyAmortization = 0;
        });
        _showMessage('Price data is invalid.');
        return;
      }

      setState(() {
        final discountedPrice = _discountedPricePerSqm(price, lotSize);
        _tcpAmount = discountedPrice * lotSize;
        _originalPricePerSqm = price;
        _pricePerSqm = discountedPrice;
        _monthlyAmortization = _computeMonthlyAmortization(_tcpAmount, lotSize);
      });
    } catch (e) {
      setState(() {
        _tcpAmount = 0;
        _pricePerSqm = 0;
        _originalPricePerSqm = 0;
        _monthlyAmortization = 0;
      });
      _showMessage('Failed to fetch price: $e');
    } finally {
      if (mounted) {
        setState(() => _isComputing = false);
      }
    }
  }

  Widget _buildCompute() {
    final colorScheme = Theme.of(context).colorScheme;
    final isMsccProject = _projects[_selectedProject] == 'MSCC';
    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomInset = MediaQuery.of(context).padding.bottom;
        // Reserve space for the bottom nav so the card never tucks underneath it.
        final navPadding = kBottomNavigationBarHeight + 8;
        final double safeHeight = (constraints.maxHeight - bottomInset)
            .clamp(0.0, double.infinity)
            .toDouble();
        final double heroHeight = safeHeight * 0.20;
        final double cardHeight = (safeHeight - heroHeight - navPadding)
            .clamp(320.0, safeHeight)
            .toDouble();
        final double decorLarge = (constraints.maxWidth * 0.28).clamp(
          140.0,
          220.0,
        );
        final double decorMedium = (constraints.maxWidth * 0.22).clamp(
          110.0,
          180.0,
        );
        final double decorSmall = (constraints.maxWidth * 0.16).clamp(
          80.0,
          120.0,
        );
        final downpaymentValue = _downpaymentOptions[_downpaymentIndex.round()];
        final isZeroDown = downpaymentValue == 0;
        final maxPaymentYears = _isPaymentYearsEnabled
            ? (isMsccProject ? 10.0 : (isZeroDown ? 7.0 : 5.0))
            : 1.0;
        final paymentYearsDivisions = _isPaymentYearsEnabled
            ? (isMsccProject ? 9 : (isZeroDown ? 6 : 4))
            : 1;

        return Stack(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F88D5), Color(0xFF035F9B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              top: -30,
              left: -50,
              child: Container(
                width: decorLarge,
                height: decorLarge,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: -40,
              child: Container(
                width: decorMedium,
                height: decorMedium,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: CustomPaint(
                size: const Size(130, 120),
                painter: _TrianglePainter(
                  color: Colors.white.withOpacity(0.10),
                ),
              ),
            ),
            Positioned(
              bottom: heroHeight * 0.4,
              left: 24,
              child: Container(
                width: decorSmall,
                height: decorSmall,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.06),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: heroHeight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${isMsccProject ? "Base Price" : "Original price"} per sqm: ₱${_formatCurrency(_originalPricePerSqm)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Discounted Price per sqm: ₱${_formatCurrency(_pricePerSqm)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'TCP ₱${_formatCurrency(_tcpAmount)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Downpayment (${_downpaymentOptions[_downpaymentIndex.round()]}%): ₱${_formatCurrency(_downpaymentAmount(_tcpAmount))}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Monthly Amortization: ₱${_formatCurrency(_monthlyAmortization)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Container(
                  height: cardHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: LayoutBuilder(
                      builder: (context, innerConstraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: innerConstraints.maxHeight,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Payment Calculator',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF2D3A4B),
                                      ),
                                    ),
                                    Icon(
                                      Icons.payments_outlined,
                                      color: const Color(0xFF2BB673),
                                    ),
                                  ],
                                ),
                                TabBar(
                                  controller: _computeTabController,
                                  labelColor: colorScheme.primary,
                                  unselectedLabelColor: const Color(0xFF6C7A89),
                                  indicatorColor: colorScheme.primary,
                                  labelStyle: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                  tabs: const [
                                    Tab(text: 'In-House Financing'),
                                    Tab(text: 'Bank Financing'),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_computeTabIndex == 0) ...[
                                  if (!isMsccProject) ...[
                                    Text(
                                      'Lot size (sqm)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _lotSizeController,
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      onChanged: _onLotSizeChanged,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'[0-9.]'),
                                        ),
                                      ],
                                      decoration: InputDecoration(
                                        hintText: 'Enter lot size',
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFF4F7FB),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE4E9F1),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE4E9F1),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  if (_selectedProject == 0) ...[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Phase',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        Text(
                                          _selectedPhase,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: colorScheme.primary,
                                        inactiveTrackColor: const Color(
                                          0xFFE0E6EF,
                                        ),
                                        thumbColor: colorScheme.primary,
                                        overlayColor: const Color(0x1F0F88D5),
                                      ),
                                      child: Slider(
                                        min: 0,
                                        max: (_phaseOptions.length - 1)
                                            .toDouble(),
                                        divisions: _phaseOptions.length > 1
                                            ? _phaseOptions.length - 1
                                            : 1,
                                        value: _phaseIndex.clamp(
                                          0,
                                          (_phaseOptions.length - 1).toDouble(),
                                        ),
                                        onChanged: (val) {
                                          final idx = val.round().clamp(
                                                0,
                                                _phaseOptions.length - 1,
                                              );
                                          setState(() {
                                            _phaseIndex = idx.toDouble();
                                            _selectedPhase = _phaseOptions[idx];
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        isMsccProject
                                            ? 'Unit type'
                                            : 'Lot category',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      Text(
                                        _selectedLotCategory,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: colorScheme.primary,
                                      inactiveTrackColor: const Color(
                                        0xFFE0E6EF,
                                      ),
                                      thumbColor: colorScheme.primary,
                                      overlayColor: const Color(0x1F0F88D5),
                                    ),
                                    child: Slider(
                                      min: 0,
                                      max: (_lotCategoryOptions.length - 1)
                                          .toDouble(),
                                      divisions: _lotCategoryOptions.length > 1
                                          ? _lotCategoryOptions.length - 1
                                          : 1,
                                      value: _lotCategoryIndex.clamp(
                                        0,
                                        (_lotCategoryOptions.length - 1)
                                            .toDouble(),
                                      ),
                                      onChanged: (val) {
                                        final idx = val.round().clamp(
                                              0,
                                              _lotCategoryOptions.length - 1,
                                            );
                                        setState(() {
                                          _lotCategoryIndex = idx.toDouble();
                                          _selectedLotCategory =
                                              _lotCategoryOptions[idx];
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  if (isMsccProject) ...[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Floor level',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        Text(
                                          _selectedFloorLevel,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: colorScheme.primary,
                                        inactiveTrackColor: const Color(
                                          0xFFE0E6EF,
                                        ),
                                        thumbColor: colorScheme.primary,
                                        overlayColor: const Color(0x1F0F88D5),
                                      ),
                                      child: Slider(
                                        min: 0,
                                        max: (_msccFloorLevels.length - 1)
                                            .toDouble(),
                                        divisions: _msccFloorLevels.length > 1
                                            ? _msccFloorLevels.length - 1
                                            : 1,
                                        value: _floorLevelIndex.clamp(
                                          0,
                                          (_msccFloorLevels.length - 1)
                                              .toDouble(),
                                        ),
                                        onChanged: (val) {
                                          final idx = val.round().clamp(
                                                0,
                                                _msccFloorLevels.length - 1,
                                              );
                                          setState(() {
                                            _floorLevelIndex = idx.toDouble();
                                            _selectedFloorLevel =
                                                _msccFloorLevels[idx];
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    LayoutBuilder(
                                      builder: (context, ddConstraints) {
                                        final totalWidth =
                                            ddConstraints.maxWidth;
                                        final threeColWidth =
                                            (totalWidth - 24) / 3;
                                        final twoColWidth =
                                            (totalWidth - 12) / 2;
                                        final fieldWidth = (threeColWidth < 160
                                                ? twoColWidth
                                                : threeColWidth)
                                            .clamp(120.0, totalWidth);
                                        return Wrap(
                                          spacing: 12,
                                          runSpacing: 12,
                                          children: [
                                            SizedBox(
                                              width: fieldWidth,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'View',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.grey[800],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  DropdownButtonFormField<
                                                      String>(
                                                    value: _selectedView,
                                                    items: _msccViewOptions
                                                        .map(
                                                          (view) =>
                                                              DropdownMenuItem<
                                                                  String>(
                                                            value: view,
                                                            child: Text(
                                                              view,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                        .toList(),
                                                    onChanged: (val) {
                                                      if (val == null) return;
                                                      setState(() {
                                                        _selectedView = val;
                                                        _viewIndex =
                                                            _msccViewOptions
                                                                .indexOf(val)
                                                                .toDouble();
                                                      });
                                                    },
                                                    decoration: InputDecoration(
                                                      contentPadding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                        horizontal: 14,
                                                        vertical: 12,
                                                      ),
                                                      filled: true,
                                                      fillColor: const Color(
                                                        0xFFF4F7FB,
                                                      ),
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          12,
                                                        ),
                                                        borderSide:
                                                            const BorderSide(
                                                          color: Color(
                                                            0xFFE4E9F1,
                                                          ),
                                                        ),
                                                      ),
                                                      enabledBorder:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          12,
                                                        ),
                                                        borderSide:
                                                            const BorderSide(
                                                          color: Color(
                                                            0xFFE4E9F1,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    icon: const Icon(
                                                      Icons
                                                          .keyboard_arrow_down_rounded,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              width: fieldWidth,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'End Unit?',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.grey[800],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  DropdownButtonFormField<
                                                      String>(
                                                    value: _selectedEndUnit,
                                                    items: _msccEndUnitOptions
                                                        .map(
                                                          (value) =>
                                                              DropdownMenuItem<
                                                                  String>(
                                                            value: value,
                                                            child: Text(
                                                              value,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                        .toList(),
                                                    onChanged: (val) {
                                                      if (val == null) return;
                                                      setState(() {
                                                        _selectedEndUnit = val;
                                                      });
                                                    },
                                                    decoration: InputDecoration(
                                                      contentPadding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                        horizontal: 14,
                                                        vertical: 12,
                                                      ),
                                                      filled: true,
                                                      fillColor: const Color(
                                                        0xFFF4F7FB,
                                                      ),
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          12,
                                                        ),
                                                        borderSide:
                                                            const BorderSide(
                                                          color: Color(
                                                            0xFFE4E9F1,
                                                          ),
                                                        ),
                                                      ),
                                                      enabledBorder:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          12,
                                                        ),
                                                        borderSide:
                                                            const BorderSide(
                                                          color: Color(
                                                            0xFFE4E9F1,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    icon: const Icon(
                                                      Icons
                                                          .keyboard_arrow_down_rounded,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              width: fieldWidth,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Type of delivery',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.grey[800],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  DropdownButtonFormField<
                                                      String>(
                                                    value: _selectedFurnish,
                                                    items: _msccFurnishOptions
                                                        .map(
                                                          (value) =>
                                                              DropdownMenuItem<
                                                                  String>(
                                                            value: value,
                                                            child: Text(
                                                              value,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                        .toList(),
                                                    onChanged: (val) {
                                                      if (val == null) return;
                                                      setState(() {
                                                        _selectedFurnish = val;
                                                      });
                                                    },
                                                    decoration: InputDecoration(
                                                      contentPadding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                        horizontal: 14,
                                                        vertical: 12,
                                                      ),
                                                      filled: true,
                                                      fillColor: const Color(
                                                        0xFFF4F7FB,
                                                      ),
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          12,
                                                        ),
                                                        borderSide:
                                                            const BorderSide(
                                                          color: Color(
                                                            0xFFE4E9F1,
                                                          ),
                                                        ),
                                                      ),
                                                      enabledBorder:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          12,
                                                        ),
                                                        borderSide:
                                                            const BorderSide(
                                                          color: Color(
                                                            0xFFE4E9F1,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    icon: const Icon(
                                                      Icons
                                                          .keyboard_arrow_down_rounded,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 18),
                                  ],
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Downpayment',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      Text(
                                        '${_downpaymentOptions[_downpaymentIndex.round()]}%',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: colorScheme.primary,
                                      inactiveTrackColor: const Color(
                                        0xFFE0E6EF,
                                      ),
                                      thumbColor: colorScheme.primary,
                                      overlayColor: const Color(0x1F0F88D5),
                                    ),
                                    child: Slider(
                                      min: 0,
                                      max: (_downpaymentOptions.length - 1)
                                          .toDouble(),
                                      divisions: _downpaymentOptions.length - 1,
                                      value: _downpaymentIndex,
                                      onChanged: (val) {
                                        setState(() {
                                          _downpaymentIndex = val;
                                          _updatePaymentYearsConstraints();
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Payment years',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2D3A4B),
                                        ),
                                      ),
                                      Text(
                                        '${_paymentYears.round()} yrs',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: colorScheme.primary,
                                      inactiveTrackColor: const Color(
                                        0xFFE0E6EF,
                                      ),
                                      thumbColor: colorScheme.primary,
                                      overlayColor: const Color(0x1F0F88D5),
                                    ),
                                    child: Slider(
                                      min: 1,
                                      max: maxPaymentYears,
                                      divisions: paymentYearsDivisions,
                                      value: _paymentYears.clamp(
                                        1,
                                        maxPaymentYears,
                                      ),
                                      onChanged: _isPaymentYearsEnabled
                                          ? (val) => setState(
                                                () => _paymentYears = val,
                                              )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isComputing
                                          ? null
                                          : _startComputation,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF0F88D5,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'Start a computation',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 20),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 24,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4F7FB),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFE4E9F1),
                                      ),
                                    ),
                                    child: Column(
                                      children: const [
                                        Icon(
                                          Icons.account_balance,
                                          color: Color(0xFF2BB673),
                                          size: 32,
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'Bank financing calculator coming soon.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF2D3A4B),
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'We’ll display bank financing computations here once available.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF4A5565),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHome() {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: _HomeBackgroundPainter()),
        ),
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                _buildHeroSection(),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = _contentMaxWidth(constraints.maxWidth);
                    return Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Column(
                          children: [
                            Transform.translate(
                              offset: const Offset(0, -10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: _cardEntrance(_buildProjectCard()),
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(0, 15),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: _cardEntrance(_buildStatusCard()),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 30, 16, 0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Explore ${_projects[_selectedProject]}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2D3A4B),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: _cardEntrance(
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final firstCard = _exploreActionCard(
                                      title:
                                          'Virtual Tour at ${_projects[_selectedProject]}',
                                      icon: Icons.vrpano_outlined,
                                      onTap: () =>
                                          setState(() => _currentIndex = 1),
                                    );
                                    final secondCard = _exploreActionCard(
                                      title: 'Price Computation',
                                      icon:
                                          Icons.account_balance_wallet_outlined,
                                      onTap: () =>
                                          setState(() => _currentIndex = 3),
                                    );

                                    return IntrinsicHeight(
                                      child: Row(
                                        children: [
                                          Expanded(child: firstCard),
                                          const SizedBox(width: 12),
                                          Expanded(child: secondCard),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: _cardEntrance(_buildMapSection()),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    final projectCode = _projects[_selectedProject];
    final imagePath = _projectImages[projectCode];
    final screenWidth = MediaQuery.of(context).size.width;
    final heroTitleSize =
        screenWidth < 380 ? 22.0 : (screenWidth < 420 ? 24.0 : 28.0);
    final heroLocationSize = screenWidth < 380 ? 14.0 : 16.0;
    return FadeTransition(
      opacity: _heroBgOpacity,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
          gradient: const LinearGradient(
            colors: [Color(0xFF0F88D5), Color(0xFF035F9B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 900),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: imagePath != null
                      ? SizedBox.expand(
                          key: ValueKey(imagePath),
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                        )
                      : const SizedBox.expand(key: ValueKey('no-image')),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.45),
                        const Color(0xFF035F9B).withOpacity(0.25),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SlideTransition(
                  position: _heroTextSlide,
                  child: FadeTransition(
                    opacity: _heroTextOpacity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 36),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.apartment_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'VHBC APP',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const SizedBox(height: 6),
                        Text(
                          _projectTitles[_selectedProject],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: heroTitleSize,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _projectLocations[_selectedProject],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: heroLocationSize,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardEntrance(Widget child) {
    return FadeTransition(
      opacity: _cardsOpacity,
      child: ScaleTransition(scale: _cardsScale, child: child),
    );
  }

  Widget _buildProjectCard() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SELECT DEVELOPMENT',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_projects.length, (index) {
                final isSelected = index == _selectedProject;
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == _projects.length - 1 ? 0 : 10,
                  ),
                  child: GestureDetector(
                    onTap: () => _onProjectSelected(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0F88D5)
                            : const Color(0xFFF1F4F8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF0F88D5)
                              : const Color(0xFFE3E7EC),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.apartment_rounded,
                            size: 18,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF6C7A89),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _projects[index],
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF3A4A5B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _exploreActionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 120),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: const Color(0xFFE4E9F1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F88D5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF2BB673)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3A4B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'STATUS UPDATE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6C7A89),
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Pre-Selling',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D3A4B),
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => setState(() => _currentIndex = 2),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F88D5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.map_outlined, size: 18),
            label: const Text(
              'View Map',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    final isMvOrMscc = _selectedProject == 0 || _selectedProject == 2;
    final isErhd = _selectedProject == 1;
    const mvlcMsccCoords = '14.09219845872134,120.69419417143793';
    const erhdCoords = '14.190250081143637,120.83691884017821';
    final locationLabel = _projectLocations[_selectedProject];
    final mapQuery = isMvOrMscc
        ? '$mvlcMsccCoords (Mountain View Leisure Community)'
        : isErhd
            ? '$erhdCoords (Eastwest Resorts Hub and Development)'
            : locationLabel;
    final mapEmbedUrl =
        'https://www.google.com/maps?q=${Uri.encodeComponent(mapQuery)}&hl=en&t=k&z=19&output=embed';
    final mapOpenUrl =
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(mapQuery)}&hl=en';
    final mapWebView = LayoutBuilder(
      builder: (context, constraints) {
        final mapHeight = _salesMapMediaHeight(constraints.maxWidth);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _openMapFullScreen(
              mapEmbedUrl,
              mapOpenUrl,
              isMvOrMscc ? 'Mountain View Leisure Community' : locationLabel,
            ),
            child: Stack(
              children: [
                Container(
                  height: mapHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE4E9F1)),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: IgnorePointer(
                    // Prevents the inline map from capturing taps that try to open an intent.
                    child: kIsWeb
                        ? buildMapEmbed(mapEmbedUrl)
                        : Builder(
                            builder: (_) {
                              final controller = WebViewController();
                              controller.setJavaScriptMode(
                                JavaScriptMode.unrestricted,
                              );
                              controller.loadHtmlString('''
                            <html>
                              <head>
                                <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes">
                                <style>
                                  html, body { margin: 0; padding: 0; height: 100%; overflow: hidden; }
                                  iframe { border: 0; width: 100%; height: 100%; pointer-events: none; }
                                </style>
                              </head>
                              <body>
                                <iframe
                                  src="$mapEmbedUrl"
                                  allowfullscreen
                                  loading="lazy"
                                  referrerpolicy="no-referrer-when-downgrade">
                                </iframe>
                              </body>
                            </html>
                            ''');
                              return WebViewWidget(controller: controller);
                            },
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.white70,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(
                        Icons.fullscreen,
                        color: Color(0xFF2BB673),
                      ),
                      onPressed: () => _openMapFullScreen(
                        mapEmbedUrl,
                        mapOpenUrl,
                        isMvOrMscc
                            ? 'Mountain View Leisure Community'
                            : locationLabel,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.map_outlined, color: Color(0xFF2BB673)),
              SizedBox(width: 8),
              Text(
                'Project Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D3A4B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          mapWebView,
        ],
      ),
    );
  }

  Future<void> _openMapFullScreen(
    String mapEmbedUrl,
    String mapOpenUrl,
    String title,
  ) async {
    if (kIsWeb) {
      final uri = Uri.parse(mapOpenUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open Google Maps in a new tab.'),
          ),
        );
      }
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(title),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F88D5),
            elevation: 1,
          ),
          body: Builder(
            builder: (_) {
              final controller = WebViewController();
              controller.setJavaScriptMode(JavaScriptMode.unrestricted);
              controller.loadHtmlString('''
                <html>
                  <head>
                    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes">
                    <style>
                      html, body { margin: 0; padding: 0; height: 100%; overflow: hidden; }
                      iframe { border: 0; width: 100%; height: 100%; }
                    </style>
                  </head>
                  <body>
                    <iframe
                      src="$mapEmbedUrl"
                      allowfullscreen
                      loading="lazy"
                      referrerpolicy="no-referrer-when-downgrade">
                    </iframe>
                  </body>
                </html>
                ''');
              return WebViewWidget(controller: controller);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSalesMapTab() {
    return Stack(
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: _HomeBackgroundPainter()),
        ),
        _buildSalesMapContent(),
      ],
    );
  }

  Widget _buildSalesMapContent() {
    final project = _projects[_selectedProject];
    final isMvProject = project == 'MVLC';
    final isErhdProject = project == 'ERHD';
    final isMsccProject = project == 'MSCC';
    final hasMvSalesMaps =
        _salesMapImages.isNotEmpty || _salesMapCommercialImages.isNotEmpty;
    final hasMsccSalesMaps = _msccSalesMapItems.isNotEmpty;

    if (!isMvProject && !isErhdProject && !isMsccProject) {
      return const Center(
        child: Text(
          'Sales maps are not available for this project.',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      );
    }

    if (isMvProject) {
      if (!hasMvSalesMaps && !_isLoadingSalesMap && _salesMapError == null) {
        _loadSalesMaps();
      }

      if (_isLoadingSalesMap && !hasMvSalesMaps) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_salesMapError != null && !hasMvSalesMaps) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _salesMapError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isLoadingSalesMap ? null : _loadSalesMaps,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F88D5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      }

      final commercialEntries = _salesMapCommercialImages.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      final maps = <Widget>[
        for (var i = 0; i < 3; i++)
          _buildSalesMapCard('Phase ${i + 1}', _salesMapImages[i + 1]),
        for (final entry in commercialEntries)
          _buildSalesMapCard('Phase ${entry.key} - commercial', entry.value),
      ];

      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final horizontalPadding = _pageHorizontalPadding(width);
          final maxWidth = _contentMaxWidth(width);
          final wrappedMaps = maps
              .map(
                (card) => Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: card,
                  ),
                ),
              )
              .toList();
          return ListView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              20,
              horizontalPadding,
              24,
            ),
            children: wrappedMaps,
          );
        },
      );
    }

    if (isMsccProject) {
      if (!hasMsccSalesMaps && !_isLoadingSalesMap && _salesMapError == null) {
        _loadSalesMaps();
      }

      if (_isLoadingSalesMap && !hasMsccSalesMaps) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_salesMapError != null && !hasMsccSalesMaps) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _salesMapError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isLoadingSalesMap ? null : _loadSalesMaps,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F88D5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      }

      final galleryImages = _msccSalesMapItems.map((e) => e.url).toList();
      final galleryCaptions = _msccSalesMapItems.map((e) => e.title).toList();

      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final horizontalPadding = _pageHorizontalPadding(width);
          final maxWidth = min(_contentMaxWidth(width), 720.0);
          return ListView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              20,
              horizontalPadding,
              24,
            ),
            children: [
              for (final item in _msccSalesMapItems)
                Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: _buildSalesMapCard(
                      item.title,
                      item.url,
                      galleryImages: galleryImages,
                      galleryCaptions: galleryCaptions,
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }

    if (isErhdProject) {
      if (_erhdSalesMapImage == null &&
          !_isLoadingSalesMap &&
          _salesMapError == null) {
        _loadSalesMaps();
      }

      if (_isLoadingSalesMap && _erhdSalesMapImage == null) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_salesMapError != null && _erhdSalesMapImage == null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _salesMapError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isLoadingSalesMap ? null : _loadSalesMaps,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F88D5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final horizontalPadding = _pageHorizontalPadding(width);
          final maxWidth = min(_contentMaxWidth(width), 720.0);
          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                20,
                horizontalPadding,
                24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: _buildSalesMapCard(
                  'ERHD Sales Map',
                  _erhdSalesMapImage,
                  galleryImages:
                      _erhdSalesMapImage != null ? [_erhdSalesMapImage!] : null,
                  galleryCaptions:
                      _erhdSalesMapImage != null ? const ['Sales Map'] : null,
                ),
              ),
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  List<_SalesMapGalleryItem> _salesMapGalleryItems() {
    final project = _projects[_selectedProject];
    if (project == 'MSCC') {
      return List<_SalesMapGalleryItem>.from(_msccSalesMapItems);
    }

    final gallery = <_SalesMapGalleryItem>[];
    final residentialEntries = _salesMapImages.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    gallery.addAll(
      residentialEntries.map(
        (entry) =>
            _SalesMapGalleryItem(title: 'Phase ${entry.key}', url: entry.value),
      ),
    );
    final commercialEntries = _salesMapCommercialImages.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    gallery.addAll(
      commercialEntries.map(
        (entry) => _SalesMapGalleryItem(
          title: 'Phase ${entry.key} - commercial',
          url: entry.value,
        ),
      ),
    );
    return gallery;
  }

  Widget _buildSalesMapCard(
    String title,
    String? imageUrl, {
    List<String>? galleryImages,
    List<String>? galleryCaptions,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaHeight = _salesMapMediaHeight(constraints.maxWidth);
        final content = imageUrl == null
            ? Container(
                height: mediaHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FB),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: const Text(
                  'No sales map available.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6C7A89)),
                ),
              )
            : ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _cachedNetworkImage(
                        context,
                        imageUrl,
                        height: mediaHeight,
                        width: constraints.maxWidth,
                        fit: BoxFit.cover,
                        error: const Text(
                          'Failed to load map image.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6C7A89),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.white70,
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(
                            Icons.fullscreen,
                            color: Color(0xFF2BB673),
                          ),
                          onPressed: () {
                            List<String> urls;
                            List<String>? captions;
                            if (galleryImages != null &&
                                galleryImages.isNotEmpty) {
                              urls = List<String>.from(galleryImages);
                              captions = galleryCaptions;
                            } else {
                              final galleryItems = _salesMapGalleryItems();
                              urls = galleryItems.map((e) => e.url).toList();
                              captions =
                                  galleryItems.map((e) => e.title).toList();
                            }
                            if (urls.isEmpty) return;
                            final startIndex = urls.indexOf(imageUrl);
                            _openImageGalleryFullScreen(
                              context,
                              urls,
                              startIndex < 0 ? 0 : startIndex,
                              captions: captions,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: const Color(0xFFE4E9F1)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: imageUrl != null
                ? () {
                    List<String> urls;
                    List<String>? captions;
                    if (galleryImages != null && galleryImages.isNotEmpty) {
                      urls = List<String>.from(galleryImages);
                      captions = galleryCaptions;
                    } else {
                      final galleryItems = _salesMapGalleryItems();
                      urls = galleryItems.map((e) => e.url).toList();
                      captions = galleryItems.map((e) => e.title).toList();
                    }
                    if (urls.isEmpty) return;
                    final startIndex = urls.indexOf(imageUrl);
                    _openImageGalleryFullScreen(
                      context,
                      urls,
                      startIndex < 0 ? 0 : startIndex,
                      captions: captions,
                    );
                  }
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D3A4B),
                    ),
                  ),
                ),
                SizedBox(
                  height: mediaHeight,
                  width: double.infinity,
                  child: content,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoCard({
    required String title,
    required String videoId,
    required String externalUrl,
    required VoidCallback onPlay,
  }) {
    final thumbnailUrl =
        'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFE4E9F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D3A4B),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final mediaHeight = _salesMapMediaHeight(constraints.maxWidth);
              return SizedBox(
                height: mediaHeight,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _cachedNetworkImage(
                          context,
                          thumbnailUrl,
                          width: constraints.maxWidth,
                          height: mediaHeight,
                          fit: BoxFit.cover,
                          error: Container(
                            color: Colors.black,
                            alignment: Alignment.center,
                            child: const Text(
                              'Video thumbnail unavailable',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.32),
                                Colors.black.withOpacity(0.12),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: GestureDetector(
                          onTap: onPlay,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.16),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.black87,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 12,
                        right: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Tap to play fullscreen',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 8,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.fullscreen,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMedia() {
    return Stack(
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: _HomeBackgroundPainter()),
        ),
        DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Container(
                color: Colors.white,
                child: TabBar(
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: const Color(0xFF6C7A89),
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  tabs: const [
                    Tab(text: 'Actual'),
                    Tab(text: 'Perspective'),
                    Tab(text: 'Videos'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildOngoingMedia(),
                    _buildFutureMedia(),
                    _buildVideosTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOngoingMedia() {
    if (_projectDevImages.isEmpty && !_isLoadingMedia && _mediaError == null) {
      _loadProjectDevImages();
    }

    if (_isLoadingMedia && _projectDevImages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_mediaError != null && _projectDevImages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _mediaError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.redAccent,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoadingMedia ? null : _loadProjectDevImages,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F88D5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = _mediaGridColumns(width);
        final spacing = 12.0;
        final horizontalPadding = _pageHorizontalPadding(width);
        final itemWidth =
            ((width - (horizontalPadding * 2) - (spacing * (columns - 1))) /
                    columns)
                .clamp(120.0, 520.0)
                .toDouble();
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            16,
            horizontalPadding,
            16,
          ),
          itemCount: _projectDevImages.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final url = _projectDevImages[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onTap: () {
                  final captions = _projectDevImages
                      .asMap()
                      .entries
                      .map((entry) => 'Media ${entry.key + 1}')
                      .toList();
                  _openImageGalleryFullScreen(
                    context,
                    _projectDevImages,
                    index,
                    captions: captions,
                  );
                },
                child: _cachedNetworkImage(
                  context,
                  url,
                  fit: BoxFit.cover,
                  width: itemWidth,
                  height: itemWidth,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFutureMedia() {
    if (!_futureMediaFetched &&
        !_isLoadingFutureMedia &&
        _futureMediaError == null) {
      _loadFutureDevImages();
    }

    if (_isLoadingFutureMedia && _futureDevImages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_futureMediaError != null && _futureDevImages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _futureMediaError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.redAccent,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoadingFutureMedia ? null : _loadFutureDevImages,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F88D5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    if (_futureMediaFetched &&
        _futureDevImages.isEmpty &&
        !_isLoadingFutureMedia &&
        _futureMediaError == null) {
      return const Center(
        child: Text(
          'No future media available for this project.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6C7A89),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = _mediaGridColumns(width);
        final spacing = 12.0;
        final horizontalPadding = _pageHorizontalPadding(width);
        final itemWidth =
            ((width - (horizontalPadding * 2) - (spacing * (columns - 1))) /
                    columns)
                .clamp(120.0, 520.0)
                .toDouble();
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            16,
            horizontalPadding,
            16,
          ),
          itemCount: _futureDevImages.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final url = _futureDevImages[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onTap: () {
                  final captions = _futureDevImages
                      .asMap()
                      .entries
                      .map((entry) => 'Future ${entry.key + 1}')
                      .toList();
                  _openImageGalleryFullScreen(
                    context,
                    _futureDevImages,
                    index,
                    captions: captions,
                  );
                },
                child: _cachedNetworkImage(
                  context,
                  url,
                  fit: BoxFit.cover,
                  width: itemWidth,
                  height: itemWidth,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVideosTab() {
    final project = _projects[_selectedProject];
    final videos = _youtubeVideosByProject[project] ?? <_YoutubeVideoItem>[];

    if (videos.isEmpty && !_isLoadingVideos && _videosError == null) {
      _loadYoutubeLinks();
    }

    if (_isLoadingVideos && videos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_videosError != null && videos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _videosError!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6C7A89),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (videos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No video available for this project.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6C7A89),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontalPadding = _pageHorizontalPadding(width);
        final maxWidth = min(_contentMaxWidth(width), 720.0);
        return ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            20,
            horizontalPadding,
            24,
          ),
          children: videos.map((video) {
            final externalUrl = video.originalLink.isNotEmpty
                ? video.originalLink
                : 'https://youtu.be/${video.id}';
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: _buildVideoCard(
                  title: video.title,
                  videoId: video.id,
                  externalUrl: externalUrl,
                  onPlay: () =>
                      _openVideoFullScreen(video.id, video.title, externalUrl),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _openVideoFullScreen(String videoId, String title, String externalUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenYouTubePlayer(
          videoId: videoId,
          title: title,
          externalUrl: externalUrl,
        ),
      ),
    );
  }

  Widget _buildAnnouncements() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: const CustomPaint(
              painter: _AnnouncementsBackgroundPainter(),
            ),
          ),
        ),
        _buildAnnouncementsContent(),
      ],
    );
  }

  Widget _buildAnnouncementsContent() {
    if (_announcements.isEmpty &&
        !_isLoadingAnnouncements &&
        _announcementsError == null) {
      _loadAnnouncements();
    }

    final widgets = <Widget>[_announcementsHeader()];

    if (_isLoadingAnnouncements && _announcements.isEmpty) {
      widgets.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 40, horizontal: 8),
          child: Center(
            child: Text(
              'Loading announcements...',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6C7A89),
              ),
            ),
          ),
        ),
      );
    } else if (_announcementsError != null && _announcements.isEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _announcementsError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isLoadingAnnouncements ? null : _loadAnnouncements,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F88D5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_announcements.isEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: const Center(
            child: Text(
              'No Announcement yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6C7A89),
              ),
            ),
          ),
        ),
      );
    } else {
      widgets.addAll(_announcements.map(_announcementCard));
    }

    final listView = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontalPadding = _pageHorizontalPadding(width);
        final maxWidth = _contentMaxWidth(width);
        final wrappedWidgets = widgets
            .map(
              (child) => Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: child,
                ),
              ),
            )
            .toList();
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            16,
            horizontalPadding,
            24,
          ),
          children: wrappedWidgets,
        );
      },
    );

    return RefreshIndicator(onRefresh: _loadAnnouncements, child: listView);
  }

  Widget _announcementsHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Announcements',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2A3D),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Latest updates and news for the team.',
            style: TextStyle(fontSize: 13.5, color: Color(0xFF6C7A89)),
          ),
        ],
      ),
    );
  }

  Widget _announcementCard(_AnnouncementItem item) {
    final preview = item.content.trim().isEmpty
        ? 'No content provided.'
        : item.content.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E9F1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openAnnouncementDetail(item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D3A4B),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F88D5).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatAnnouncementDate(item.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F88D5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  preview,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF4A5565),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openAnnouncementDetail(_AnnouncementItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFFF6F9FC),
          appBar: AppBar(
            title: const Text('Announcement'),
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1F2A3D),
            elevation: 0.5,
          ),
          body: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF6F9FC), Color(0xFFE9F2FB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F88D5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        _formatAnnouncementDate(item.createdAt),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F88D5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F2A3D),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE4E9F1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Text(
                        item.content.trim().isEmpty
                            ? 'No content provided.'
                            : item.content.trim(),
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: Color(0xFF2D3A4B),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAnnouncementDate(DateTime? date) {
    if (date == null) return 'Date TBD';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final safeMonth = (date.month - 1).clamp(0, months.length - 1);
    final month = months[safeMonth];
    final day = date.day.toString().padLeft(2, '0');
    return '$month $day, ${date.year}';
  }

  Widget _buildFaqs() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: const CustomPaint(
              painter: _AnnouncementsBackgroundPainter(),
            ),
          ),
        ),
        _buildHermosaChatContent(),
      ],
    );
  }

  Widget _buildHermosaChatContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontalPadding = _pageHorizontalPadding(width);
        final maxWidth = _contentMaxWidth(width);
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: constraints.maxHeight,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                18,
                horizontalPadding,
                16,
              ),
              child: DefaultTabController(
                length: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TabBar(
                      controller: _faqTabController,
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: const Color(0xFF6C7A89),
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                      tabs: const [
                        Tab(text: 'Hermosa'),
                        Tab(text: 'FAQs'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TabBarView(
                        controller: _faqTabController,
                        children: [
                          _buildHermosaChatTab(),
                          _buildFaqTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHermosaChatTab() {
    return Column(
      children: [
        Expanded(child: _buildHermosaChatMessages()),
        const SizedBox(height: 12),
        _buildHermosaChatComposer(),
      ],
    );
  }

  Widget _buildFaqTab() {
    final project = _projects[_selectedProject];
    final assetPath = _faqAssetPathForProject(project);
    if (_faqPdfBytes == null && !_isLoadingFaqDoc && _faqError == null) {
      _loadFaqDoc();
    }
    return Column(
      children: [
        _faqHeader(project),
        const SizedBox(height: 12),
        Expanded(
          child: _faqContentCard(project, assetPath),
        ),
      ],
    );
  }

  Widget _buildHermosaChatMessages() {
    if (_hermosaMessages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE4E9F1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: const [
            Icon(Icons.support_agent, color: Color(0xFF0F88D5)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Say hello to Hermosa and ask about lots, prices, or project updates.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF4A5565),
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _hermosaScrollController,
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: _hermosaMessages.length,
      itemBuilder: (context, index) {
        final message = _hermosaMessages[index];
        final isUser = message.isUser;
        final bubbleColor = isUser ? const Color(0xFF0F88D5) : Colors.white;
        final textColor = isUser ? Colors.white : const Color(0xFF2D3A4B);
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: const BoxConstraints(maxWidth: 320),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(14),
              border:
                  isUser ? null : Border.all(color: const Color(0xFFE4E9F1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: message.isLoading
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF0F88D5),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Hermosa is typing...',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF4A5565),
                        ),
                      ),
                    ],
                  )
                : Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: textColor,
                      height: 1.45,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildHermosaChatComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E9F1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _hermosaMessageController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendHermosaMessage(),
              decoration: const InputDecoration(
                hintText: 'Type your message...',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: const Color(0xFF0F88D5),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _sendHermosaMessage,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendHermosaMessage() async {
    final text = _hermosaMessageController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _hermosaMessages.add(_HermosaChatMessage(text: text, isUser: true));
      _hermosaMessages.add(
        const _HermosaChatMessage(text: '', isUser: false, isLoading: true),
      );
    });
    _hermosaMessageController.clear();
    _scrollHermosaToBottom();
    final loadingIndex = _hermosaMessages.length - 1;
    final reply = await _requestHermosaReply(text);
    if (!mounted) return;
    setState(() {
      _hermosaMessages[loadingIndex] = _hermosaMessages[loadingIndex].copyWith(
        text: reply,
        isLoading: false,
      );
    });
    _scrollHermosaToBottom();
  }

  void _scrollHermosaToBottom() {
    if (!_hermosaScrollController.hasClients) return;
    _hermosaScrollController.animateTo(
      _hermosaScrollController.position.maxScrollExtent + 80,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<String> _requestHermosaReply(String userMessage) async {
    final kbReady = await _ensureHermosaKnowledgeLoaded();
    if (!kbReady) {
      final error = _hermosaKbError ?? 'Unable to load Hermosa knowledge base.';
      return 'I could not load the knowledge base. $error';
    }

    final contextText = _buildHermosaContext(userMessage);
    final serverUrl = await _getServerUrl();
    if (serverUrl == null || serverUrl.isEmpty) {
      return 'Server configuration missing. Please set SERVER_URL in assets/env.txt.';
    }
    return _requestHermosaReplyFromServer(
      serverUrl: serverUrl,
      userMessage: userMessage,
      contextText: contextText,
    );
  }

  Future<String?> _getServerUrl() async {
    final url = dotenv.env['SERVER_URL']?.trim();
    if (url != null && url.isNotEmpty) {
      return url;
    }
    try {
      await dotenv.load(fileName: 'assets/env.txt');
    } catch (_) {}
    return dotenv.env['SERVER_URL']?.trim();
  }

  Future<String> _requestHermosaReplyFromServer({
    required String serverUrl,
    required String userMessage,
    required String contextText,
  }) async {
    final systemPrompt =
        'You are Hermosa, the VHBC chat support assistant. Answer only using the provided context. You can also greet the user'
        'If the answer is not in the context, say you do not have that information and suggest contacting a sales specialist.';
    final prompt = contextText.isEmpty
        ? '$systemPrompt\n\nUser question:\n$userMessage'
        : '$systemPrompt\n\nContext:\n$contextText\n\nUser question:\n$userMessage';
    final history = _buildHermosaConversationHistory();
    final contents = <Map<String, dynamic>>[
      for (final item in history)
        {
          'role': item['role'] == 'assistant' ? 'model' : 'user',
          'parts': [
            {'text': item['content'] ?? ''},
          ],
        },
      {
        'role': 'user',
        'parts': [
          {'text': prompt},
        ],
      },
    ];

    final configuredModel = dotenv.env['GEMINI_MODEL']?.trim();
    final model = configuredModel != null && configuredModel.isNotEmpty
        ? configuredModel
        : 'gemini-1.5-flash';

    return _postToServer(
      serverUrl: serverUrl,
      model: model,
      contents: contents,
    );
  }

  Future<String> _postToServer({
    required String serverUrl,
    required String model,
    required List<Map<String, dynamic>> contents,
  }) async {
    try {
      // Remove trailing slash from serverUrl if present
      final baseUrl = serverUrl.endsWith('/')
          ? serverUrl.substring(0, serverUrl.length - 1)
          : serverUrl;
      final endpoint = '$baseUrl/api/chat';

      final response = await http
          .post(
        Uri.parse(endpoint),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'contents': contents, 'model': model}),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
            'Request timeout - server took too long to respond',
          );
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'Server error ${response.statusCode}: ${_truncateResponseBody(response.body) ?? response.body}',
        );

        // Try to parse error message from server
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          final errorMessage =
              errorData['message'] ?? errorData['error'] ?? 'Unknown error';
          return 'Hermosa is unavailable right now: $errorMessage';
        } catch (_) {
          return 'Hermosa is unavailable right now (error ${response.statusCode}).';
        }
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Parse Gemini API response format (proxied through our server)
      final candidates = data['candidates'];
      if (candidates is List && candidates.isNotEmpty) {
        final content = candidates.first['content'];
        if (content is Map<String, dynamic>) {
          final parts = content['parts'];
          if (parts is List && parts.isNotEmpty) {
            final text = parts.first['text']?.toString().trim();
            if (text != null && text.isNotEmpty) {
              return text;
            }
          }
        }
      }

      // Fallback: check for direct text field
      final fallbackText = data['text']?.toString().trim();
      if (fallbackText != null && fallbackText.isNotEmpty) {
        return fallbackText;
      }

      return 'Hermosa could not generate a response. Please try again.';
    } on http.ClientException catch (e) {
      debugPrint('Network error connecting to server: $e');
      return 'Could not connect to Hermosa server. Please check your internet connection.';
    } on FormatException catch (e) {
      debugPrint('Invalid response format from server: $e');
      return 'Hermosa sent an invalid response. Please try again.';
    } catch (e) {
      debugPrint('Unexpected error calling server: $e');
      return 'An unexpected error occurred. Please try again later.';
    }
  }

  String? _truncateResponseBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;
    const maxLength = 240;
    if (trimmed.length <= maxLength) return trimmed;
    return '${trimmed.substring(0, maxLength)}...';
  }

  List<Map<String, String>> _buildHermosaConversationHistory() {
    final history = <Map<String, String>>[];
    final recentMessages = _hermosaMessages
        .where((message) => !message.isLoading)
        .toList()
        .reversed
        .take(8)
        .toList()
        .reversed;
    for (final message in recentMessages) {
      history.add({
        'role': message.isUser ? 'user' : 'assistant',
        'content': message.text,
      });
    }
    return history;
  }

  Future<bool> _ensureHermosaKnowledgeLoaded() async {
    if (_hermosaKbReady) return true;
    if (_hermosaKbLoading) {
      while (_hermosaKbLoading) {
        await Future.delayed(const Duration(milliseconds: 120));
      }
      return _hermosaKbReady;
    }

    _hermosaKbLoading = true;
    _hermosaKbError = null;
    try {
      // await pdfrx.pdfrxFlutterInitialize();
      final chunks = <_HermosaKbChunk>[];
      chunks.addAll(await _extractHermosaPdfChunks('assets/mvlc.pdf', 'MVLC'));
      chunks.addAll(await _extractHermosaPdfChunks('assets/erhd.pdf', 'ERHD'));
      chunks.addAll(await _extractHermosaPdfChunks('assets/mscc.pdf', 'MSCC'));
      _hermosaKbChunks
        ..clear()
        ..addAll(chunks);
      _hermosaKbReady = _hermosaKbChunks.isNotEmpty;
      if (!_hermosaKbReady) {
        _hermosaKbError = 'No text could be extracted from the PDFs.';
      }
    } catch (e) {
      _hermosaKbError = 'Failed to extract PDF text: $e';
      _hermosaKbReady = false;
    } finally {
      _hermosaKbLoading = false;
    }
    return _hermosaKbReady;
  }

  Future<List<_HermosaKbChunk>> _extractHermosaPdfChunks(
    String assetPath,
    String source,
  ) async {
    final document = await pdfrx.PdfDocument.openAsset(
      assetPath,
      // useProgressiveLoading: false,
    );
    final chunks = <_HermosaKbChunk>[];
    for (final page in document.pages) {
      final pageText = await page.loadStructuredText();
      final fullText = pageText.fullText.trim();
      if (fullText.isEmpty) continue;
      final pageChunks = _splitHermosaText(fullText, maxChunkLength: 700);
      for (final chunk in pageChunks) {
        final tokens = _tokenizeHermosa(chunk);
        if (tokens.isEmpty) continue;
        chunks.add(
          _HermosaKbChunk(
            source: source,
            pageNumber: page.pageNumber,
            text: chunk,
            tokens: tokens,
          ),
        );
      }
    }
    await document.dispose();
    return chunks;
  }

  String _buildHermosaContext(String query) {
    if (_hermosaKbChunks.isEmpty) return '';
    final queryTokens = _tokenizeHermosa(query);
    if (queryTokens.isEmpty) return '';

    final scored = _hermosaKbChunks
        .map(
          (chunk) => MapEntry(
            chunk,
            _scoreHermosaChunk(queryTokens, chunk.tokens),
          ),
        )
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topChunks = scored.take(5).map((entry) => entry.key).toList();
    if (topChunks.isEmpty) return '';

    final buffer = StringBuffer();
    for (final chunk in topChunks) {
      buffer.writeln('[${chunk.source} p.${chunk.pageNumber}] ${chunk.text}');
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  int _scoreHermosaChunk(Set<String> queryTokens, Set<String> chunkTokens) {
    var score = 0;
    for (final token in queryTokens) {
      if (chunkTokens.contains(token)) score++;
    }
    return score;
  }

  Set<String> _tokenizeHermosa(String text) {
    final matches = RegExp(r'[A-Za-z0-9]+').allMatches(text.toLowerCase());
    return matches
        .map((m) => m.group(0)!)
        .where((token) => token.length > 1)
        .toSet();
  }

  List<String> _splitHermosaText(String text, {required int maxChunkLength}) {
    final words =
        text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return const [];
    final chunks = <String>[];
    final buffer = StringBuffer();
    for (final word in words) {
      if (buffer.isNotEmpty &&
          buffer.length + word.length + 1 > maxChunkLength) {
        chunks.add(buffer.toString().trim());
        buffer.clear();
      }
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(word);
    }
    if (buffer.isNotEmpty) {
      chunks.add(buffer.toString().trim());
    }
    return chunks;
  }

  Widget _faqHeader(String project) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FAQs',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2A3D),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Showing FAQs for $project',
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF6C7A89)),
        ),
      ],
    );
  }

  Widget _faqContentCard(String project, String? assetPath) {
    final decoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE4E9F1)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 8),
        ),
      ],
    );

    if (assetPath == null) {
      return _faqMessageCard(
        decoration: decoration,
        icon: Icons.info_outline_rounded,
        title: 'No FAQs uploaded yet',
        message:
            'We do not have FAQ content for $project. Please check again once it is available.',
      );
    }

    if (_isLoadingFaqDoc) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        decoration: decoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F88D5)),
            ),
            SizedBox(height: 12),
            Text(
              'Loading FAQ document...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3A4B),
              ),
            ),
          ],
        ),
      );
    }

    if (_faqError != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: decoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _faqError!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _loadFaqDoc(forceRefresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F88D5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    if (_faqPdfBytes != null) {
      return LayoutBuilder(
        builder: (context, _) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: decoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F88D5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        project,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F88D5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'FAQs Document',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D3A4B),
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Color(0xFF4A5565),
                      ),
                      onSelected: (value) {
                        if (value == 'download') {
                          _downloadFaqPdf(project);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'download',
                          child: Text('Download PDF'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE4E9F1)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Zoom out',
                      onPressed: () => _adjustFaqZoom(-0.25),
                      icon: const Icon(Icons.zoom_out),
                    ),
                    Text(
                      '${_faqZoomLevel.toStringAsFixed(1)}x',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3A4B),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Zoom in',
                      onPressed: () => _adjustFaqZoom(0.25),
                      icon: const Icon(Icons.zoom_in),
                    ),
                    IconButton(
                      tooltip: 'Full screen',
                      onPressed: () => _openFaqPdfFullScreen(context),
                      icon: const Icon(Icons.fullscreen),
                    ),
                  ],
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? pdfrx.PdfViewer.asset(
                            assetPath,
                            controller: _faqPdfControllerWeb,
                            params: _faqPdfrxParams(),
                          )
                        : SfPdfViewer.memory(
                            _faqPdfBytes!,
                            controller: _faqPdfController,
                            canShowPaginationDialog: false,
                            canShowScrollHead: true,
                            canShowScrollStatus: true,
                            interactionMode: PdfInteractionMode.pan,
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return _faqMessageCard(
      decoration: decoration,
      icon: Icons.help_outline,
      title: 'FAQ document',
      message: 'If the FAQ document does not appear, please try again later.',
    );
  }

  Widget _faqWhyVhbcContent() {
    final decoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE4E9F1)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 8),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Why VHBC?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D3A4B),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'We’ll share the highlights that make VHBC special here soon.',
            style: TextStyle(
              fontSize: 13.5,
              color: Color(0xFF4A5565),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  pdfrx.PdfViewerParams _faqPdfrxParams() {
    return pdfrx.PdfViewerParams(
      backgroundColor: Colors.white,
      minScale: 1.0,
      maxScale: 4.0,
      calculateInitialZoom: (
              // _, __, ___, ____
              ) =>
          _faqZoomLevel.clamp(1.0, 4.0).toDouble(),
      onViewerReady: (document, controller) {
        if (!mounted) return;
        setState(() => _faqZoomLevel = controller.currentZoom);
      },
    );
  }

  pdfrx.PdfViewerParams _companyProfilePdfrxParams() {
    return const pdfrx.PdfViewerParams(
      backgroundColor: Colors.white,
      minScale: 1.0,
      maxScale: 4.0,
    );
  }

  Widget _faqMessageCard({
    required BoxDecoration decoration,
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2BB673)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D3A4B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF4A5565),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadFaqDoc({bool forceRefresh = false}) async {
    final project = _projects[_selectedProject];
    final assetPath = _faqAssetPathForProject(project);
    if (assetPath == null) {
      setState(() {
        _faqPdfBytes = null;
        _faqError = null;
        _isLoadingFaqDoc = false;
      });
      return;
    }

    if (!forceRefresh && _faqPdfCache.containsKey(project)) {
      setState(() {
        _faqPdfBytes = _faqPdfCache[project];
        _faqError = null;
      });
      return;
    }

    setState(() {
      _isLoadingFaqDoc = true;
      if (forceRefresh) {
        _faqPdfBytes = null;
      }
      _faqError = null;
    });

    try {
      final data = await rootBundle.load(assetPath);
      final pdfBytes = data.buffer.asUint8List();
      if (!mounted) return;
      setState(() {
        _faqPdfCache[project] = pdfBytes;
        _faqPdfBytes = pdfBytes;
      });
    } catch (e) {
      debugPrint('Failed to load FAQ doc for $project: $e');
      if (!mounted) return;
      setState(() {
        _faqError = 'Failed to load FAQs for $project. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFaqDoc = false;
        });
      }
    }
  }

  String? _faqAssetPathForProject(String project) {
    if (project.toUpperCase() == 'MVLC') return 'assets/mvlc.pdf';
    if (project.toUpperCase() == 'ERHD') return 'assets/erhd.pdf';
    if (project.toUpperCase() == 'MSCC') return 'assets/mscc.pdf';
    return null;
  }

  Widget _placeholder(String label) {
    return Center(
      child: Text(
        '$label Screen',
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _YoutubeVideoItem {
  const _YoutubeVideoItem({
    required this.id,
    required this.title,
    required this.originalLink,
  });

  final String id;
  final String title;
  final String originalLink;
}

class _AnnouncementItem {
  const _AnnouncementItem({
    required this.title,
    required this.content,
    this.createdAt,
  });

  final String title;
  final String content;
  final DateTime? createdAt;
}

class _HermosaChatMessage {
  const _HermosaChatMessage({
    required this.text,
    required this.isUser,
    this.isLoading = false,
  });

  final String text;
  final bool isUser;
  final bool isLoading;

  _HermosaChatMessage copyWith({String? text, bool? isUser, bool? isLoading}) {
    return _HermosaChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class _HermosaKbChunk {
  const _HermosaKbChunk({
    required this.source,
    required this.pageNumber,
    required this.text,
    required this.tokens,
  });

  final String source;
  final int pageNumber;
  final String text;
  final Set<String> tokens;
}

class _GeminiResult {
  const _GeminiResult({required this.statusCode, this.reply, this.bodySnippet});

  final int statusCode;
  final String? reply;
  final String? bodySnippet;
}

class _SalesMapGalleryItem {
  const _SalesMapGalleryItem({required this.title, required this.url});

  final String title;
  final String url;
}

// Simple abstract triangle accent for header corners.
class _TrianglePainter extends CustomPainter {
  _TrianglePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.65)
      ..lineTo(size.width * 0.35, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HomeBackgroundPainter extends CustomPainter {
  const _HomeBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = Colors.white;
    canvas.drawRect(Offset.zero & size, paint);

    final topGreen = Path()
      ..moveTo(0, size.height * 0.06)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.01,
        size.width * 0.55,
        size.height * 0.08,
      )
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.13,
        size.width,
        size.height * 0.07,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
    paint.color = const Color(0xFF136735);
    canvas.drawPath(topGreen, paint);

    final topBlue = Path()
      ..moveTo(0, size.height * 0.1)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.05,
        size.width * 0.48,
        size.height * 0.12,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.18,
        size.width,
        size.height * 0.12,
      )
      ..lineTo(size.width, size.height * 0.05)
      ..quadraticBezierTo(
        size.width * 0.62,
        size.height * 0.12,
        size.width * 0.28,
        size.height * 0.05,
      )
      ..lineTo(0, size.height * 0.08)
      ..close();
    paint.color = const Color(0xFF0F88D5);
    canvas.drawPath(topBlue, paint);

    final bottomGreen = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.86)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.9,
        size.width * 0.58,
        size.height * 0.82,
      )
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.76,
        size.width,
        size.height * 0.82,
      )
      ..lineTo(size.width, size.height)
      ..close();
    paint.color = const Color(0xFF136735);
    canvas.drawPath(bottomGreen, paint);

    final bottomBlue = Path()
      ..moveTo(0, size.height * 0.92)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.9,
        size.width * 0.52,
        size.height * 0.96,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 1.02,
        size.width,
        size.height * 0.95,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    paint.color = const Color(0xFF0F88D5);
    canvas.drawPath(bottomBlue, paint);

    final subtleWave = Path()
      ..moveTo(0, size.height * 0.32)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.28,
        size.width * 0.55,
        size.height * 0.35,
      )
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.4,
        size.width,
        size.height * 0.34,
      )
      ..lineTo(size.width, size.height * 0.42)
      ..quadraticBezierTo(
        size.width * 0.68,
        size.height * 0.48,
        size.width * 0.32,
        size.height * 0.4,
      )
      ..lineTo(0, size.height * 0.45)
      ..close();
    paint.color = Colors.white.withOpacity(0.65);
    canvas.drawPath(subtleWave, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnnouncementsBackgroundPainter extends CustomPainter {
  const _AnnouncementsBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = Colors.white;
    canvas.drawRect(Offset.zero & size, paint);

    paint.color = const Color(0xFFF2F5F9);
    final softWave = Path()
      ..moveTo(0, size.height * 0.05)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.02,
        size.width * 0.55,
        size.height * 0.08,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.12,
        size.width,
        size.height * 0.05,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(softWave, paint);

    paint.color = const Color(0xFFF6F8FB);
    final midWave = Path()
      ..moveTo(0, size.height * 0.20)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.16,
        size.width * 0.52,
        size.height * 0.22,
      )
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.26,
        size.width,
        size.height * 0.18,
      )
      ..lineTo(size.width, size.height * 0.28)
      ..quadraticBezierTo(
        size.width * 0.66,
        size.height * 0.32,
        size.width * 0.32,
        size.height * 0.24,
      )
      ..lineTo(0, size.height * 0.30)
      ..close();
    canvas.drawPath(midWave, paint);

    final bottomGreen = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.90)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.93,
        size.width * 0.55,
        size.height * 0.88,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.82,
        size.width,
        size.height * 0.88,
      )
      ..lineTo(size.width, size.height)
      ..close();
    paint.color = const Color(0xFF136735);
    canvas.drawPath(bottomGreen, paint);

    final bottomBlue = Path()
      ..moveTo(0, size.height * 0.94)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.92,
        size.width * 0.52,
        size.height * 0.96,
      )
      ..quadraticBezierTo(
        size.width * 0.80,
        size.height * 1.00,
        size.width,
        size.height * 0.95,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    paint.color = const Color(0xFF0F88D5);
    canvas.drawPath(bottomBlue, paint);

    paint.color = Colors.white.withOpacity(0.85);
    final highlight = Path()
      ..moveTo(0, size.height * 0.76)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.72,
        size.width * 0.55,
        size.height * 0.78,
      )
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.84,
        size.width,
        size.height * 0.76,
      )
      ..lineTo(size.width, size.height * 0.84)
      ..quadraticBezierTo(
        size.width * 0.68,
        size.height * 0.88,
        size.width * 0.32,
        size.height * 0.82,
      )
      ..lineTo(0, size.height * 0.86)
      ..close();
    canvas.drawPath(highlight, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FullScreenYouTubePlayer extends StatefulWidget {
  const _FullScreenYouTubePlayer({
    required this.videoId,
    required this.title,
    required this.externalUrl,
  });

  final String videoId;
  final String title;
  final String externalUrl;

  @override
  State<_FullScreenYouTubePlayer> createState() =>
      _FullScreenYouTubePlayerState();
}

class _FullScreenYouTubePlayerState extends State<_FullScreenYouTubePlayer> {
  ypf.YoutubePlayerController? _mobileController;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _mobileController = ypf.YoutubePlayerController(
        initialVideoId: widget.videoId,
        flags: const ypf.YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          loop: true,
          controlsVisibleAtStart: true,
          disableDragSeek: false,
          forceHD:
              false, // Allow adaptive quality so playback can start faster on slower connections.
          enableCaption: false,
          useHybridComposition: true, // Better startup performance on Android.
        ),
      );
    }
  }

  @override
  void dispose() {
    _mobileController
      ?..pause()
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Material(
                      color: Colors.white.withOpacity(0.08),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => launchUrl(
                          Uri.parse(widget.externalUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Icon(
                            Icons.open_in_new,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SizedBox.expand(
                  child: kIsWeb
                      ? buildYouTubeEmbed(widget.videoId)
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final mobileController = _mobileController;
    if (mobileController == null) {
      return const SizedBox.shrink();
    }

    return ypf.YoutubePlayerBuilder(
      player: ypf.YoutubePlayer(
        controller: mobileController,
        progressColors: const ypf.ProgressBarColors(
          playedColor: Color(0xFF0F88D5),
          handleColor: Colors.white,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
        topActions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.open_in_new, color: Colors.white),
            onPressed: () => launchUrl(
              Uri.parse(widget.externalUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(children: [Positioned.fill(child: player)]),
          ),
        );
      },
    );
  }
}
