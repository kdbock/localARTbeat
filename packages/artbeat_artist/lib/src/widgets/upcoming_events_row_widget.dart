import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show OptimizedImage;
import 'package:artbeat_events/artbeat_events.dart';

/// Widget for displaying upcoming local events in a horizontal scrollable row
class UpcomingEventsRowWidget extends StatelessWidget {
  final String zipCode;
  final VoidCallback? onSeeAllPressed;

  const UpcomingEventsRowWidget({
    super.key,
    required this.zipCode,
    this.onSeeAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Get current date for filtering
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr('art_walk_upcoming_events'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onSeeAllPressed,
                child: Text(tr('art_walk_see_all')),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('events')
                .where(
                  'startDate',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(now),
                )
                .where('isPublic', isEqualTo: true)
                .limit(20) // Reduce payload; local filtering still applies
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    tr('art_walk_no_upcoming_events_in_your_area'),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final events = snapshot.data!.docs
                  .map((doc) => ArtbeatEvent.fromFirestore(doc))
                  .where((event) {
                    // Filter to only show public events with locations containing the zipCode
                    return event.isPublic && event.location.contains(zipCode);
                  })
                  .toList();

              // Sort locally by date
              events.sort((a, b) => a.startDate.compareTo(b.startDate));

              if (events.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    tr('art_walk_no_upcoming_events_in_your_area'),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: events.length,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemBuilder: (context, index) {
                  final event = events[index];
                  final formattedDate = DateFormat.MMMd().format(
                    event.dateTime,
                  );
                  final formattedTime = DateFormat.jm().format(event.dateTime);

                  return Container(
                    width: 280,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) =>
                                  EventDetailsScreen(eventId: event.id),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4.0),
                              ),
                              child:
                                  event.imageUrls.isNotEmpty &&
                                      event.imageUrls.first.isNotEmpty
                                  ? OptimizedImage(
                                      imageUrl: event.imageUrls.first,
                                      width: double.infinity,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      isThumbnail: true,
                                      placeholder: Container(
                                        height: 120,
                                        width: double.infinity,
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.grey,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      errorWidget: Container(
                                        height: 120,
                                        width: double.infinity,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.event,
                                          size: 48,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      height: 120,
                                      width: double.infinity,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.event,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$formattedDate at $formattedTime',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    event.location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
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
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
