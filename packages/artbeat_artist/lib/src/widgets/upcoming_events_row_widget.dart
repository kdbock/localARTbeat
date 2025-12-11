import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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
              const Text('art_walk_upcoming_events'.tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onSeeAllPressed,
                child: const Text('art_walk_see_all'.tr()),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('events')
                .where('isPublic', isEqualTo: true)
                .where('startDate',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(now))
                .orderBy('startDate')
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('art_walk_no_upcoming_events_in_your_area'.tr(),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final events = snapshot.data!.docs
                  .map((doc) => ArtbeatEvent.fromFirestore(doc))
                  .where((event) {
                // Filter to only show events with locations containing the zipCode
                return event.location.contains(zipCode);
              }).toList();

              if (events.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('art_walk_no_upcoming_events_in_your_area'.tr(),
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
                  final formattedDate =
                      DateFormat.MMMd().format(event.dateTime);
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
                              builder: (context) => EventDetailsScreen(
                                eventId: event.id,
                              ),
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
                              child: event.imageUrls.isNotEmpty &&
                                      event.imageUrls.first.isNotEmpty &&
                                      Uri.tryParse(event.imageUrls.first)
                                              ?.hasScheme ==
                                          true
                                  ? Image.network(
                                      event.imageUrls.first,
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
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
