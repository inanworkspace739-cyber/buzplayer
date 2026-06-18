import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/playlist_provider.dart';
import '../theme/app_theme.dart';
import '../models/playlist.dart';
import '../utils/responsive_helper.dart';
import '../widgets/glass_container.dart';
import 'main_player_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
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
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final provider = context.watch<PlaylistProvider>();
    final playlistName = provider.currentPlaylist?.name ?? 'My Playlist';
    final fs = ResponsiveHelper.fontScale(context);
    final hPad = ResponsiveHelper.contentPadding(context);
    
    // Channel Counts
    final liveCount = provider.liveChannels.length;
    final moviesCount = provider.vodChannels.length;
    final seriesCount = provider.seriesChannels.length;

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
        decoration: const BoxDecoration(
          gradient: AppTheme.bgGradient,
        ),
        child: Stack(
          children: [
            // Ambient backdrop glows
            Positioned(
              top: -100,
              left: -50,
              child: Container(
                width: 300,
                height: 300,
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
              bottom: 100,
              right: -80,
              child: Container(
                width: 280,
                height: 280,
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

            // Scroll View
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    // Header Card
                    _buildHeader(context, playlistName, provider),
                    
                    const SizedBox(height: 32),
                    
                    // Welcome & Prompt
                    Text(
                      'Welcome Back',
                      style: GoogleFonts.outfit(
                        fontSize: 16 * fs,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose Content Type',
                      style: GoogleFonts.outfit(
                        fontSize: 26 * fs,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Category Cards Grid
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          if (liveCount > 0)
                            _buildHeroCard(
                              context: context,
                              title: 'LIVE TV',
                              subtitle: '$liveCount channels available',
                              icon: Icons.live_tv_rounded,
                              iconColor: const Color(0xFF00D2FF),
                              bgGradient: const LinearGradient(
                                colors: [Color(0xFF1A1230), Color(0xFF10091E)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              initialTab: 0,
                            ),
                          if (liveCount > 0 && (moviesCount > 0 || seriesCount > 0))
                            const SizedBox(height: 16),
                          if (moviesCount > 0 || seriesCount > 0)
                            Row(
                              children: [
                                if (moviesCount > 0)
                                  Expanded(
                                    child: _buildSplitCard(
                                      context: context,
                                      title: 'MOVIES',
                                      subtitle: '$moviesCount titles',
                                      icon: Icons.movie_filter_rounded,
                                      iconColor: AppTheme.primaryLight,
                                      bgGradient: const LinearGradient(
                                        colors: [Color(0xFF28142A), Color(0xFF150A16)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      initialTab: 1,
                                    ),
                                  ),
                                if (moviesCount > 0 && seriesCount > 0)
                                  const SizedBox(width: 16),
                                if (seriesCount > 0)
                                  Expanded(
                                    child: _buildSplitCard(
                                      context: context,
                                      title: 'SERIES',
                                      subtitle: '$seriesCount shows',
                                      icon: Icons.video_library_rounded,
                                      iconColor: AppTheme.accent,
                                      bgGradient: const LinearGradient(
                                        colors: [Color(0xFF2C1D0D), Color(0xFF180F06)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      initialTab: 2,
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String playlistName, PlaylistProvider provider) {
    final typeText = provider.currentPlaylist?.type == PlaylistType.xtream
        ? 'XTREAM CODES'
        : provider.currentPlaylist?.type == PlaylistType.m3uUrl
            ? 'M3U PLAYLIST'
            : 'LOCAL FILE';

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 24,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.success,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      typeText,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.grid_view_rounded,
              color: Colors.white70,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required LinearGradient bgGradient,
    required int initialTab,
  }) {
    final heroHeight = ResponsiveHelper.heroCardHeight(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MainPlayerScreen(initialTab: initialTab)),
        ).then((_) {
          ResponsiveHelper.setPortraitOrAllOrientations(context);
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        });
      },
      child: Container(
        height: heroHeight,
        decoration: BoxDecoration(
          gradient: bgGradient,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: iconColor.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              // Huge background icon
              Positioned(
                right: -24,
                bottom: -32,
                child: Icon(
                  icon,
                  size: 160,
                  color: iconColor.withValues(alpha: 0.06),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 30),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplitCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required LinearGradient bgGradient,
    required int initialTab,
  }) {
    final splitHeight = ResponsiveHelper.splitCardHeight(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MainPlayerScreen(initialTab: initialTab)),
        ).then((_) {
          ResponsiveHelper.setPortraitOrAllOrientations(context);
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        });
      },
      child: Container(
        height: splitHeight,
        decoration: BoxDecoration(
          gradient: bgGradient,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: iconColor.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              // Background icon
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  icon,
                  size: 110,
                  color: iconColor.withValues(alpha: 0.05),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: iconColor, size: 20),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 10),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
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
}
