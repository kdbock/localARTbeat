import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/artwork_model.dart' as artist_artwork;
import '../services/artist_auction_read_service.dart';

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
  List<artist_artwork.ArtworkModel> _activeAuctions = [];
  List<artist_artwork.ArtworkModel> _endedAuctions = [];
  List<artist_artwork.ArtworkModel> _scheduledAuctions = [];
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
      final data = await context
          .read<ArtistAuctionReadService>()
          .loadAuctionDashboard();

      setState(() {
        _activeAuctions = data.activeAuctions;
        _endedAuctions = data.endedAuctions;
        _scheduledAuctions = data.scheduledAuctions;
        _totalBids
          ..clear()
          ..addAll(data.totalBids);
        _bidCounts
          ..clear()
          ..addAll(data.bidCounts);
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
    artist_artwork.ArtworkModel auction, {
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

  Future<void> _viewAuctionDetails(artist_artwork.ArtworkModel auction) async {
    await Navigator.pushNamed(
      context,
      core.AppRoutes.artworkDetail,
      arguments: {'artworkId': auction.id},
    );
    // Refresh data when returning
    _loadAuctionData();
  }

  Future<void> _editAuction(artist_artwork.ArtworkModel auction) async {
    final result = await Navigator.pushNamed<bool>(
      context,
      core.AppRoutes.artworkAuctionManage,
      arguments: {'artworkId': auction.id},
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
    Navigator.pushNamed(
      context,
      core.AppRoutes.artworkAuctionSetup,
      arguments: {'mode': 'editing'},
    ).then((_) => _loadAuctionData());
  }
}
