import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../providers/playlist_provider.dart';
import '../theme/app_theme.dart';
import '../models/channel.dart';
import 'video_player_screen.dart';
import 'series_details_screen.dart';

/// IBO Pro Player style: forced landscape, 3-panel layout.
/// Left = categories, Center = channel list, Right = live video preview.
class MainPlayerScreen extends StatefulWidget {
  final int initialTab;
  const MainPlayerScreen({super.key, this.initialTab = 0});

  @override
  State<MainPlayerScreen> createState() => _MainPlayerScreenState();
}

class _MainPlayerScreenState extends State<MainPlayerScreen> {
  late int _currentTab;
  String _selectedGroup = 'All';
  int _selectedChannelIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Video preview
  late final Player _player;
  late final VideoController _videoController;
  bool _isBuffering = false;
  String _previewChannelName = '';

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;

    // Force landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Init player
    _player = Player(
      configuration: const PlayerConfiguration(bufferSize: 32 * 1024 * 1024),
    );
    _videoController = VideoController(_player);

    _player.stream.buffering.listen((buffering) {
      if (mounted) setState(() => _isBuffering = buffering);
    });

    // Auto-play first channel after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoPlayFirstChannel();
    });
  }

  void _autoPlayFirstChannel() {
    final provider = context.read<PlaylistProvider>();
    final channels = _getFilteredChannels(provider);
    if (channels.isNotEmpty) {
      _playPreview(channels[0]);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _searchController.dispose();
    // Restore portrait
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _playPreview(Channel channel) {
    setState(() {
      _previewChannelName = channel.name;
    });

    if (_currentTab == 2) {
      // Do not attempt to play series URLs in preview
      _player.stop();
      return;
    }

    _player.open(Media(channel.streamUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF09030F), // Very deep premium black/purple
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Ambient glows
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
              bottom: -50,
              right: MediaQuery.of(context).size.width * 0.2,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.gold.withValues(alpha: 0.08),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    // ── TOP NAV BAR ──
                    _buildTopBar(),
                    const SizedBox(height: 12),

                    // ── 3 PANEL BODY ──
                    Expanded(
                      child: Consumer<PlaylistProvider>(
                        builder: (context, provider, _) {
                          if (provider.isLoading) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.gold,
                              ),
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ── LEFT: Categories ──
                              Container(
                                width: MediaQuery.of(context).size.width * 0.22,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.05),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 15,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: _buildCategorySidebar(provider),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // ── CENTER: Channel List ──
                              Container(
                                width: MediaQuery.of(context).size.width * 0.35,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.05),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 15,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: _buildChannelList(provider),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // ── RIGHT: Live Video Preview ──
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: AppTheme.gold.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.gold.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: _buildVideoPreview(provider),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
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

  // ═══════════════════════════════════════════
  // TOP BAR
  // ═══════════════════════════════════════════
  Widget _buildTopBar() {
    String tabTitle = 'PLAYLIST';
    if (_currentTab == 0) tabTitle = 'LIVE TV';
    if (_currentTab == 1) tabTitle = 'MOVIES';
    if (_currentTab == 2) tabTitle = 'SERIES';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.transparent,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              children: [
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.textPrimary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Back',
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppTheme.primaryLight.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              tabTitle,
              style: GoogleFonts.outfit(
                color: AppTheme.primaryLight,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Search
          Expanded(
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.bgDark.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.surfaceBorder.withValues(alpha: 0.5),
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                ),
                decoration: InputDecoration(
                  hintText: 'Search in $tabTitle...',
                  hintStyle: GoogleFonts.inter(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    letterSpacing: 0.1,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.textMuted,
                    size: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  isDense: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // LEFT: CATEGORY SIDEBAR
  // ═══════════════════════════════════════════
  Widget _buildCategorySidebar(PlaylistProvider provider) {
    final channels = _getBaseChannels(provider);
    final groupMap = <String, int>{};
    for (final ch in channels) {
      final g = ch.group.isEmpty ? 'Uncategorized' : ch.group;
      groupMap[g] = (groupMap[g] ?? 0) + 1;
    }
    final groups = groupMap.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    final totalCount = channels.length;

    final items = <_CategoryItem>[
      _CategoryItem('All', totalCount, isAll: true),
      _CategoryItem('Favorite', provider.favorites.length, isFavorite: true),
      ...groups.map((e) => _CategoryItem(e.key, e.value)),
    ];

    return Container(
      color: Colors.transparent,
      child: ListView.builder(
        itemCount: items.length,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected =
              _selectedGroup == item.name ||
              (item.isAll && _selectedGroup == 'All') ||
              (item.isFavorite && _selectedGroup == 'Favorite');
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedGroup = item.isFavorite
                    ? 'Favorite'
                    : item.isAll
                    ? 'All'
                    : item.name;
                _selectedChannelIndex = 0;
              });
              // Play first channel of new category
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final chs = _getFilteredChannels(provider);
                if (chs.isNotEmpty) {
                  _playPreview(chs[0]);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppTheme.primaryLight.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                border: isSelected
                    ? const Border(
                        left: BorderSide(
                          color: AppTheme.primaryLight,
                          width: 3,
                        ),
                      )
                    : null,
                borderRadius: isSelected
                    ? const BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      )
                    : BorderRadius.circular(4),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              child: Row(
                children: [
                  if (item.isFavorite)
                    const Padding(
                      padding: EdgeInsets.only(right: 3),
                      child: Icon(
                        Icons.star_rounded,
                        color: AppTheme.gold,
                        size: 14,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? AppTheme.gold
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.count}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppTheme.gold
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════
  // CENTER: CHANNEL LIST
  // ═══════════════════════════════════════════
  Widget _buildChannelList(PlaylistProvider provider) {
    final channels = _getFilteredChannels(provider);

    if (channels.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 40,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty ? 'No results' : 'No channels',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: channels.length,
      padding: const EdgeInsets.symmetric(vertical: 2),
      itemBuilder: (context, index) {
        final ch = channels[index];
        final isSelected = index == _selectedChannelIndex;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedChannelIndex = index);
            _playPreview(ch);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.gold.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border(
                bottom: BorderSide(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.03),
                ),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.gold.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Number
                SizedBox(
                  width: 24,
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppTheme.gold
                          : Colors.white.withValues(alpha: 0.4),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                // Logo
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(
                            color: AppTheme.gold.withValues(alpha: 0.5),
                            width: 1,
                          )
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: ch.logoUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: ch.logoUrl,
                            width: 28,
                            height: 28,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Icon(
                              Icons.live_tv,
                              size: 14,
                              color: AppTheme.textMuted,
                            ),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.live_tv,
                              size: 14,
                              color: AppTheme.textMuted,
                            ),
                          )
                        : const Icon(
                            Icons.live_tv,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                // Name
                Expanded(
                  child: Text(
                    ch.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? AppTheme.gold
                          : Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (provider.isFavorite(ch.streamUrl))
                  const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: AppTheme.gold,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  // RIGHT: VIDEO PREVIEW PANEL
  // ═══════════════════════════════════════════
  Widget _buildVideoPreview(PlaylistProvider provider) {
    final channels = _getFilteredChannels(provider);
    final hasChannels =
        channels.isNotEmpty && _selectedChannelIndex < channels.length;
    final selectedChannel = hasChannels
        ? channels[_selectedChannelIndex]
        : null;
    final isFav =
        selectedChannel != null &&
        provider.isFavorite(selectedChannel.streamUrl);

    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          // ── Channel Title (Top of Video Preview) ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 12,
              bottom: 8,
              left: 16,
              right: 16,
            ),
            child: Text(
              _previewChannelName.isNotEmpty
                  ? _previewChannelName
                  : 'Select a channel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // ── Video Area ──
          Expanded(
            child: _currentTab == 2 && selectedChannel != null
                ? Container(
                    color: Colors.transparent,
                    child: selectedChannel.logoUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: selectedChannel.logoUrl,
                            fit: BoxFit.contain, // Fit to show whole poster
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.gold,
                              ),
                            ),
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.movie_rounded,
                                color: AppTheme.textMuted,
                                size: 64,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.movie_rounded,
                              color: AppTheme.textMuted,
                              size: 64,
                            ),
                          ),
                  )
                : Stack(
                    children: [
                      // Video
                      Positioned.fill(
                        child: Video(
                          controller: _videoController,
                          controls: NoVideoControls,
                          fill: Colors.black,
                        ),
                      ),
                      // Buffering
                      if (_isBuffering)
                        const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.gold,
                            strokeWidth: 2,
                          ),
                        ),
                    ],
                  ),
          ),

          // ── Channel Info + Actions (Sits Below Video) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Action buttons (Compact Icons)
                GestureDetector(
                  onTap: () {
                    if (selectedChannel != null) {
                      _player.pause();
                      if (_currentTab == 2) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SeriesDetailsScreen(
                              seriesChannel: selectedChannel,
                            ),
                          ),
                        ).then((_) {
                          // Return orientation correctly
                          SystemChrome.setPreferredOrientations([
                            DeviceOrientation.landscapeLeft,
                            DeviceOrientation.landscapeRight,
                          ]);
                        });
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoPlayerScreen(
                              channels: channels,
                              initialIndex: _selectedChannelIndex,
                              isLive: _currentTab == 0,
                              restoreToLandscape: true,
                            ),
                          ),
                        ).then((_) {
                          _player.play();
                        });
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.gold.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Icon(
                      _currentTab == 2
                          ? Icons.list_rounded
                          : Icons.fullscreen_rounded,
                      color: AppTheme.gold,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    if (selectedChannel != null) {
                      provider.toggleFavorite(selectedChannel);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isFav
                          ? AppTheme.gold.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isFav
                            ? AppTheme.gold
                            : Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      isFav ? Icons.star_rounded : Icons.star_border_rounded,
                      color: isFav ? AppTheme.gold : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // DATA HELPERS
  // ═══════════════════════════════════════════
  List<Channel> _getBaseChannels(PlaylistProvider provider) {
    switch (_currentTab) {
      case 0:
        return provider.liveChannels;
      case 1:
        return provider.vodChannels;
      case 2:
        return provider.seriesChannels;
      default:
        return provider.liveChannels;
    }
  }

  List<Channel> _getFilteredChannels(PlaylistProvider provider) {
    List<Channel> channels;
    if (_selectedGroup == 'Favorite') {
      channels = provider.favorites;
    } else {
      channels = _getBaseChannels(provider);
      if (_selectedGroup != 'All') {
        channels = channels.where((c) => c.group == _selectedGroup).toList();
      }
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      channels = channels
          .where(
            (c) =>
                c.name.toLowerCase().contains(q) ||
                c.group.toLowerCase().contains(q),
          )
          .toList();
    }
    return channels;
  }
}

// Helper model
class _CategoryItem {
  final String name;
  final int count;
  final bool isAll;
  final bool isFavorite;
  _CategoryItem(
    this.name,
    this.count, {
    this.isAll = false,
    this.isFavorite = false,
  });
}
