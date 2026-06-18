import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../providers/playlist_provider.dart';
import '../services/ad_manager.dart';
import '../theme/app_theme.dart';
import '../models/playlist.dart';
import '../utils/responsive_helper.dart';
import '../widgets/pro_loading_overlay.dart';
import '../widgets/buz_logo.dart';
import '../widgets/glass_container.dart';
import 'add_playlist_screen.dart';
import 'category_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Orientation will be set in didChangeDependencies when context is available
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _loadBannerAd();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ResponsiveHelper.setPortraitOrAllOrientations(context);
  }

  void _loadBannerAd() {
    final String adUnitId = 'ca-app-pub-9283129936552011/7104626672';

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlists = context.watch<PlaylistProvider>().playlists;
    final isTab = ResponsiveHelper.isTablet(context);
    final hPad = ResponsiveHelper.contentPadding(context);
    final fs = ResponsiveHelper.fontScale(context);

    return Scaffold(
      bottomNavigationBar: _isBannerAdLoaded && _bannerAd != null
          ? SafeArea(
              child: SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: Stack(
          children: [
            // Ambient glows
            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: isTab ? 400 : 250,
                height: isTab ? 400 : 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.15),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Positioned(
              top: 300,
              right: -100,
              child: Container(
                width: isTab ? 500 : 300,
                height: isTab ? 500 : 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryLight.withValues(alpha: 0.08),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),

            // Main Scroll View
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  slivers: [
                    // ── Header (Floating Glassmorphic Panel) ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 10),
                        child: GlassContainer(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTab ? 24 : 16,
                            vertical: isTab ? 16 : 12,
                          ),
                          borderRadius: 24,
                          child: Row(
                            children: [
                              BuzLogo(size: isTab ? 56 : 44, borderRadius: 12),
                              SizedBox(width: isTab ? 16 : 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ShaderMask(
                                      shaderCallback: (bounds) =>
                                          const LinearGradient(
                                            colors: [
                                              Colors.white,
                                              Color(0xFFD6C8E6),
                                            ],
                                          ).createShader(bounds),
                                      child: Text(
                                        'Buzar - Smart IPTV Player',
                                        style: GoogleFonts.outfit(
                                          fontSize: 22 * fs,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Premium Video Player',
                                      style: GoogleFonts.inter(
                                        fontSize: 11 * fs,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textSecondary
                                            .withValues(alpha: 0.6),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.settings_rounded,
                                    color: Colors.white,
                                    size: isTab ? 28 : 22,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SettingsScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Hero Banner (Welcome or Active Stream) ──
                    SliverToBoxAdapter(
                      child: _buildHeroSection(context, playlists),
                    ),

                    SliverToBoxAdapter(
                      child: SizedBox(height: isTab ? 32 : 20),
                    ),

                    // ── Connection Grid section header ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad + 4),
                        child: Text(
                          'Quick Connect',
                          style: GoogleFonts.outfit(
                            fontSize: 18 * fs,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: SizedBox(height: isTab ? 20 : 14),
                    ),

                    // ── 3 Connection Grid Options (Horizontal side-by-side) ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildGridOption(
                                icon: Icons.link_rounded,
                                title: 'M3U URL',
                                color: AppTheme.primaryLight,
                                onTap: () => _navigateToAddPlaylist(context, 0),
                              ),
                              SizedBox(width: isTab ? 20 : 12),
                              _buildGridOption(
                                icon: Icons.folder_open_rounded,
                                title: 'Local File',
                                color: const Color(0xFF00D2FF),
                                onTap: () => _navigateToAddPlaylist(context, 1),
                              ),
                              SizedBox(width: isTab ? 20 : 12),
                              _buildGridOption(
                                icon: Icons.dns_rounded,
                                title: 'Xtream Codes',
                                color: AppTheme.accent,
                                onTap: () => _navigateToAddPlaylist(context, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, List<Playlist> playlists) {
    final isTab = ResponsiveHelper.isTablet(context);
    final hPad = ResponsiveHelper.contentPadding(context);
    final fs = ResponsiveHelper.fontScale(context);

    if (playlists.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: hPad, vertical: 10),
        padding: EdgeInsets.all(isTab ? 32 : 22),
        decoration: BoxDecoration(
          color: AppTheme.bgCard.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.surfaceBorder.withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isTab ? 12 : 8),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.star_rounded,
                    color: AppTheme.gold,
                    size: isTab ? 28 : 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'WELCOME TO BUZAR - SMART IPTV PLAYER',
                    style: GoogleFonts.inter(
                      fontSize: 11 * fs,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.gold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Begin Your Journey',
              style: GoogleFonts.outfit(
                fontSize: 22 * fs,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your M3U playlists, local files, or Xtream Codes credentials below to stream live channels and movies instantly.',
              style: GoogleFonts.inter(
                fontSize: 13 * fs,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (playlists.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              left: hPad + 4,
              right: hPad + 4,
              bottom: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Playlists',
                  style: GoogleFonts.outfit(
                    fontSize: 18 * fs,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (playlists.length > 1)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Swipe',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.swipe_right_rounded,
                        size: 14,
                        color: AppTheme.textSecondary.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        SizedBox(
          height: ResponsiveHelper.playlistCardHeight(context),
          child: PageView.builder(
            controller: PageController(
              viewportFraction: ResponsiveHelper.carouselViewportFraction(
                context,
              ),
            ),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              final IconData typeIcon = playlist.type == PlaylistType.xtream
                  ? Icons.dns_rounded
                  : playlist.type == PlaylistType.m3uUrl
                  ? Icons.link_rounded
                  : Icons.folder_open_rounded;

              final Color glowColor = playlist.type == PlaylistType.xtream
                  ? AppTheme.accent
                  : playlist.type == PlaylistType.m3uUrl
                  ? AppTheme.primaryLight
                  : const Color(0xFF00D2FF);

              return Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: EdgeInsets.all(isTab ? 28 : 22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF38126E), Color(0xFF16062B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.surfaceBorder.withValues(alpha: 0.8),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: glowColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: glowColor.withValues(alpha: 0.25),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(typeIcon, color: glowColor, size: 12),
                                    const SizedBox(width: 6),
                                    Text(
                                      playlist.type == PlaylistType.xtream
                                          ? 'XTREAM CODES'
                                          : playlist.type == PlaylistType.m3uUrl
                                          ? 'M3U PLAYLIST'
                                          : 'LOCAL PLAYLIST',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: glowColor,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert_rounded,
                                  color: Colors.white70,
                                ),
                                color: AppTheme.bgElevated,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                    color: AppTheme.surfaceBorder,
                                  ),
                                ),
                                onSelected: (value) {
                                  if (value == 'rename') {
                                    _showRenameDialog(context, playlist);
                                  } else if (value == 'delete') {
                                    _showDeleteDialog(context, playlist);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'rename',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.edit_rounded,
                                          color: AppTheme.textPrimary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Rename',
                                          style: GoogleFonts.inter(
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.delete_rounded,
                                          color: AppTheme.error,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Delete',
                                          style: GoogleFonts.inter(
                                            color: AppTheme.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            playlist.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 24 * fs,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ready to stream • Click below to launch the media center',
                            style: GoogleFonts.inter(
                              fontSize: 12 * fs,
                              color: AppTheme.textSecondary.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            height: isTab ? 64 : 54,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(27),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: () =>
                                    _openPlaylist(context, playlist),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(27),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.play_arrow_rounded,
                                      size: isTab ? 30 : 24,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Watch Now',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16 * fs,
                                        letterSpacing: 0.5,
                                        color: Colors.white,
                                      ),
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGridOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveHelper.isTablet(context) ? 28 : 18,
            horizontal: ResponsiveHelper.isTablet(context) ? 16 : 8,
          ),
          decoration: BoxDecoration(
            color: AppTheme.bgCard.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.surfaceBorder.withValues(alpha: 0.7),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: ResponsiveHelper.isTablet(context) ? 44 : 32,
              ),
              SizedBox(height: ResponsiveHelper.isTablet(context) ? 16 : 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: ResponsiveHelper.isTablet(context) ? 18 : 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title == 'M3U URL'
                    ? 'Web Link'
                    : title == 'Local File'
                    ? 'Upload file'
                    : 'Server login',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: ResponsiveHelper.isTablet(context) ? 13 : 10,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAddPlaylist(BuildContext context, int initialTab) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPlaylistScreen(initialTab: initialTab),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Playlist playlist) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Playlist',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${playlist.name}"?',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.textPrimary),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<PlaylistProvider>().deletePlaylist(playlist.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${playlist.name} deleted')),
              );
            },
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, Playlist playlist) {
    final controller = TextEditingController(text: playlist.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Rename Playlist',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Playlist Name',
            hintStyle: GoogleFonts.inter(color: AppTheme.textMuted),
            filled: true,
            fillColor: AppTheme.bgCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.gold),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.textPrimary),
            ),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                context.read<PlaylistProvider>().renamePlaylist(
                  playlist.id,
                  newName,
                );
              }
              Navigator.pop(ctx);
            },
            child: Text('Save', style: GoogleFonts.inter(color: AppTheme.gold)),
          ),
        ],
      ),
    );
  }

  void _openPlaylist(BuildContext context, Playlist playlist) async {
    // Show a pro loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (_) => ProLoadingOverlay(
        subtitle: 'Fetching channels for\n"${playlist.name}"',
      ),
    );

    final provider = context.read<PlaylistProvider>();
    await provider.loadPlaylist(playlist);

    if (context.mounted) {
      // Dismiss the loading indicator
      Navigator.pop(context);

      if (provider.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(provider.error!)));
      } else {
        AdManager.instance.showInterstitialAd(
          onAdClosed: () {
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoryScreen()),
              ).then((_) {
                // Ensure we return to portrait when coming back from the player
                ResponsiveHelper.setPortraitOrAllOrientations(context);
                SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
              });
            }
          },
        );
      }
    }
  }
}
