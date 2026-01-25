import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

/// Hub screen for managing all auction-related activities
class AuctionHubScreen extends StatefulWidget {
  const AuctionHubScreen({super.key});

  @override
  State<AuctionHubScreen> createState() => _AuctionHubScreenState();
}

class _AuctionHubScreenState extends State<AuctionHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  List<artwork.ArtworkModel> _activeAuctions = [];
  List<artwork.ArtworkModel> _endedAuctions = [];
  List<artwork.ArtworkModel> _scheduledAuctions = [];
  final Map<String, double> _totalBids = {};
  final Map<String, int> _bidCounts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAuctionData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAuctionData() async {
    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        debugPrint('🔴 Auction Hub: No user logged in');
        setState(() => _isLoading = false);
        return;
      }

      debugPrint('🔍 Auction Hub: Loading auctions for user: $userId');
      final now = DateTime.now();

      // Get all artwork by this artist
      final artworksSnapshot = await FirebaseFirestore.instance
          .collection('artworks')
          .where('userId', isEqualTo: userId)
          .where('auctionEnabled', isEqualTo: true)
          .get();

      debugPrint(
        '✅ Auction Hub: Found ${artworksSnapshot.docs.length} artworks with auctions',
      );

      final allAuctions = artworksSnapshot.docs
          .map((doc) => artwork.ArtworkModel.fromFirestore(doc))
          .toList();

      // Categorize auctions
      final active = <artwork.ArtworkModel>[];
      final ended = <artwork.ArtworkModel>[];
      final scheduled = <artwork.ArtworkModel>[];

      for (final auction in allAuctions) {
        debugPrint(
          '📦 Auction: ${auction.title}, auctionEnd: ${auction.auctionEnd}, now: $now',
        );

        if (auction.auctionEnd == null) {
          debugPrint('   → Scheduled (no end date)');
          scheduled.add(auction);
        } else if (auction.auctionEnd!.isAfter(now)) {
          debugPrint('   → Active (ends in future)');
          active.add(auction);

          // Get bid count for active auctions
          final bidsSnapshot = await FirebaseFirestore.instance
              .collection('artworks')
              .doc(auction.id)
              .collection('bids')
              .get();

          _bidCounts[auction.id] = bidsSnapshot.docs.length;

          if (auction.currentHighestBid != null) {
            _totalBids[auction.id] = auction.currentHighestBid!;
          }
        } else {
          debugPrint('   → Ended (past end date)');
          ended.add(auction);

          if (auction.currentHighestBid != null) {
            _totalBids[auction.id] = auction.currentHighestBid!;
          }
        }
      }

      // Sort by end date
      active.sort((a, b) => a.auctionEnd!.compareTo(b.auctionEnd!));
      ended.sort((a, b) => b.auctionEnd!.compareTo(a.auctionEnd!));

      debugPrint(
        '📊 Auction Hub Summary: Active=${active.length}, Ended=${ended.length}, Scheduled=${scheduled.length}',
      );

      setState(() {
        _activeAuctions = active;
        _endedAuctions = ended;
        _scheduledAuctions = scheduled;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading auction data: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Auction Hub',
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.gavel),
              text: 'Active (${_activeAuctions.length})',
            ),
            Tab(
              icon: const Icon(Icons.history),
              text: 'Ended (${_endedAuctions.length})',
            ),
            Tab(
              icon: const Icon(Icons.schedule),
              text: 'Scheduled (${_scheduledAuctions.length})',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAuctionData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showAuctionSettings,
            tooltip: 'Auction Settings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveAuctionsTab(),
                _buildEndedAuctionsTab(),
                _buildScheduledAuctionsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewAuction,
        icon: const Icon(Icons.add),
        label: const Text('New Auction'),
      ),
    );
  }

  Widget _buildActiveAuctionsTab() {
    if (_activeAuctions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.gavel,
        title: 'No Active Auctions',
        message: 'You don\'t have any active auctions at the moment.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAuctionData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activeAuctions.length,
        itemBuilder: (context, index) {
          final auction = _activeAuctions[index];
          return _buildAuctionCard(auction, isActive: true);
        },
      ),
    );
  }

  Widget _buildEndedAuctionsTab() {
    if (_endedAuctions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No Ended Auctions',
        message: 'Your ended auctions will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAuctionData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _endedAuctions.length,
        itemBuilder: (context, index) {
          final auction = _endedAuctions[index];
          return _buildAuctionCard(auction, isActive: false);
        },
      ),
    );
  }

  Widget _buildScheduledAuctionsTab() {
    if (_scheduledAuctions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.schedule,
        title: 'No Scheduled Auctions',
        message: 'Set up auction dates for your artwork.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAuctionData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _scheduledAuctions.length,
        itemBuilder: (context, index) {
          final auction = _scheduledAuctions[index];
          return _buildAuctionCard(auction, isScheduled: true);
        },
      ),
    );
  }

  Widget _buildAuctionCard(
    artwork.ArtworkModel auction, {
    bool isActive = false,
    bool isScheduled = false,
  }) {
    final timeRemaining = auction.auctionEnd != null
        ? _getTimeRemaining(auction.auctionEnd!)
        : null;
    final currentBid = _totalBids[auction.id] ?? auction.startingPrice ?? 0.0;
    final bidCount = _bidCounts[auction.id] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _viewAuctionDetails(auction),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Artwork image and title
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: auction.imageUrl.isNotEmpty
                        ? Image.network(
                            auction.imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image, size: 40),
                                ),
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 40),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auction.title,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (isScheduled)
                          _buildStatusChip('Scheduled', Colors.blue)
                        else if (isActive)
                          _buildStatusChip('Active', Colors.green)
                        else
                          _buildStatusChip('Ended', Colors.grey),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Auction details
              Row(
                children: [
                  Expanded(
                    child: _buildInfoColumn(
                      'Current Bid',
                      '\$${currentBid.toStringAsFixed(2)}',
                      Icons.attach_money,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoColumn(
                      'Total Bids',
                      bidCount.toString(),
                      Icons.people,
                    ),
                  ),
                  if (timeRemaining != null && isActive)
                    Expanded(
                      child: _buildInfoColumn(
                        'Time Left',
                        timeRemaining,
                        Icons.timer,
                      ),
                    ),
                ],
              ),

              if (auction.reservePrice != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.security, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Reserve: \$${auction.reservePrice!.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (currentBid >= auction.reservePrice!)
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _viewAuctionDetails(auction),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Details'),
                  ),
                  const SizedBox(width: 8),
                  if (isActive || isScheduled)
                    ElevatedButton.icon(
                      onPressed: () => _editAuction(auction),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeRemaining(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now);

    if (difference.isNegative) return 'Ended';

    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inMinutes}m';
    }
  }

  Future<void> _viewAuctionDetails(artwork.ArtworkModel auction) async {
    await Navigator.pushNamed(
      context,
      core.AppRoutes.artworkDetail,
      arguments: {'artworkId': auction.id},
    );
    // Refresh data when returning
    _loadAuctionData();
  }

  Future<void> _editAuction(artwork.ArtworkModel auction) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => artwork.AuctionManagementModal(artwork: auction),
    );

    if (result == true) {
      _loadAuctionData();
    }
  }

  void _createNewAuction() {
    Navigator.pushNamed(
      context,
      core.AppRoutes.artworkUpload,
    ).then((_) => _loadAuctionData());
  }

  void _showAuctionSettings() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const artwork.AuctionSetupWizardScreen(
          mode: artwork.AuctionSetupMode.editing,
        ),
      ),
    ).then((_) => _loadAuctionData());
  }
}
