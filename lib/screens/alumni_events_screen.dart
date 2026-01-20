import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../services/firestore_service.dart';
import '../models/new_model.dart';
import '../models/user_model.dart';
import 'create_event_screen.dart';

class AlumniEventsScreen extends StatefulWidget {
  const AlumniEventsScreen({Key? key}) : super(key: key);

  @override
  State<AlumniEventsScreen> createState() => _AlumniEventsScreenState();
}

class _AlumniEventsScreenState extends State<AlumniEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F0F1E), const Color(0xFF1A1A2E)]
                : [const Color(0xFFF8F9FE), const Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              _buildTabBar(isDark),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUpcomingEvents(isDark),
                    _buildMyEvents(isDark),
                    _buildPastEvents(isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildCreateEventButton(),
    );
  }

  Widget _buildHeader(bool isDark) {
    final userId = _currentUserId;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                iconSize: 28,
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Events',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      'Create & Manage Events',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search_rounded),
                iconSize: 28,
              ),
              
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.filter_list_rounded),
                iconSize: 28,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Next Event Banner - excludes own events
          StreamBuilder<Event?>(
            stream: userId != null 
                ? _firestoreService.streamNextEventExcludingOwn(userId)
                : _firestoreService.streamNextEvent(),
            builder: (context, snapshot) {
              final nextEvent = snapshot.data;
              
              return GestureDetector(
                onTap: nextEvent != null ? () => _showEventDetails(nextEvent, isDark) : null,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B9D), Color(0xFFFFA726)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.event_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Next Event',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nextEvent?.title ?? 'No upcoming events',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (nextEvent != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${_formatDate(nextEvent.eventDate)}, ${nextEvent.time}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 20,
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

  Widget _buildTabBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF4E9FFF)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'My Events'),
            Tab(text: 'Past'),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEvents(bool isDark) {
    final userId = _currentUserId;
    if (userId == null) {
      return const Center(child: Text('Not signed in'));
    }
    
    // Exclude own events from Upcoming - they appear in My Events
    return StreamBuilder<List<Event>>(
      stream: _firestoreService.streamUpcomingEventsExcludingOwn(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final events = snapshot.data ?? [];
        
        if (events.isEmpty) {
          return _buildEmptyState(isDark, 'No Upcoming Events', 'Check back soon for new events');
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: events.length,
          itemBuilder: (context, index) {
            return _buildEventCard(events[index], isDark);
          },
        );
      },
    );
  }

  Widget _buildMyEvents(bool isDark) {
    final userId = _currentUserId;
    if (userId == null) {
      return const Center(child: Text('Not signed in'));
    }
    
    return StreamBuilder<List<Event>>(
      stream: _firestoreService.streamMyCreatedEvents(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final events = snapshot.data ?? [];
        
        if (events.isEmpty) {
          return _buildEmptyState(isDark, 'No Events Created', 'Tap + to create your first event');
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: events.length,
          itemBuilder: (context, index) {
            return _buildEventCard(events[index], isDark, isMyEvent: true);
          },
        );
      },
    );
  }

  Widget _buildPastEvents(bool isDark) {
    return StreamBuilder<List<Event>>(
      stream: _firestoreService.streamPastEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final events = snapshot.data ?? [];
        
        if (events.isEmpty) {
          return _buildEmptyState(isDark, 'No Past Events', 'Your attended events will appear here');
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: events.length,
          itemBuilder: (context, index) {
            return _buildEventCard(events[index], isDark, isPast: true);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.event_busy_rounded,
              size: 56,
              color: isDark ? Colors.white54 : Colors.black38,
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event, bool isDark, {bool isMyEvent = false, bool isPast = false}) {
    final percentage = event.maxAttendees > 0 
        ? (event.attendeesCount / event.maxAttendees * 100).toInt() 
        : 0;
    final userId = _currentUserId;
    final isRegistered = userId != null && event.isUserRegistered(userId);
    final isOwnEvent = userId != null && event.createdByUserId == userId;
    
    return GestureDetector(
      onTap: () => _showEventDetails(event, isDark),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Event Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF6C63FF + (event.title.hashCode % 1000)),
                    Color(0xFF4E9FFF + (event.title.hashCode % 1000)),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          event.eventDate.day.toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _getMonthAbbr(event.eventDate.month),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                event.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isOwnEvent)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Your Event',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.time,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
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
            
            // Event Details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildEventBadge(
                        Icons.location_on_rounded,
                        event.location,
                        const Color(0xFF6C63FF),
                      ),
                      const SizedBox(width: 12),
                      
                      _buildEventBadge(
                        Icons.videocam_rounded,
                        event.type,
                        const Color(0xFF00D4AA),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: event.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6C63FF),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Attendees Progress
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  event.isFull ? 'FULL' : '$percentage% Full',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: event.isFull 
                                        ? Colors.red 
                                        : (isDark ? Colors.white70 : Colors.black54),
                                  ),
                                ),
                                Text(
                                  '${event.attendeesCount}/${event.maxAttendees}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: event.maxAttendees > 0 
                                    ? event.attendeesCount / event.maxAttendees 
                                    : 0,
                                backgroundColor: isDark ? Colors.white12 : Colors.black12,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  event.isFull ? Colors.red : const Color(0xFF6C63FF),
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action Button - Don't show for own events or past events
                  if (!isPast && !isOwnEvent)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: event.isFull && !isRegistered 
                            ? null 
                            : () => _handleRegistration(event, isRegistered),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isRegistered
                              ? const Color(0xFF00D4AA)
                              : (event.isFull ? Colors.grey : const Color(0xFF6C63FF)),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isRegistered
                                  ? Icons.check_circle_rounded
                                  : (event.isFull ? Icons.block_rounded : Icons.event_available_rounded),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isRegistered 
                                  ? 'Registered' 
                                  : (event.isFull ? 'Seats Full' : 'Register Now'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Show "Your Event" badge for own events in My Events tab
                  if (isOwnEvent && !isPast)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star_rounded, color: Color(0xFF6C63FF)),
                          SizedBox(width: 8),
                          Text(
                            'You created this event',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6C63FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateEventButton() {
    return FloatingActionButton.extended(
      onPressed: () => _navigateToCreateEvent(),
      backgroundColor: const Color(0xFF6C63FF),
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text(
        'Create Event',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _navigateToCreateEvent() {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(builder: (_) => const CreateEventScreen()),
  );
}

  void _showEventDetails(Event event, bool isDark) {
    final userId = _currentUserId;
    final isRegistered = userId != null && event.isUserRegistered(userId);
    final isOwnEvent = userId != null && event.createdByUserId == userId;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text('${_formatDate(event.eventDate)} at ${event.time}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(event.location),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        const Icon(Icons.groups_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text('${event.attendeesCount}/${event.maxAttendees} seats'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    const Text(
                      'Description',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    if (event.speakers.isNotEmpty) ...[
                      const Text(
                        'Speakers',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: event.speakers.map((s) => Chip(label: Text(s))).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    if (event.tags.isNotEmpty) ...[
                      const Text(
                        'Tags',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: event.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: Color(0xFF6C63FF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 32),
                    
                    // Don't show registration button for own events
                    if (!event.isPast && !isOwnEvent)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: event.isFull && !isRegistered 
                              ? null 
                              : () {
                                  _handleRegistration(event, isRegistered);
                                  Navigator.pop(context);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRegistered
                                ? const Color(0xFF00D4AA)
                                : (event.isFull ? Colors.grey : const Color(0xFF6C63FF)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            isRegistered 
                                ? 'Cancel Registration' 
                                : (event.isFull ? 'Seats Full' : 'Register Now'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    
                    if (isOwnEvent && !event.isPast)
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star_rounded, color: Color(0xFF6C63FF)),
                            SizedBox(width: 8),
                            Text(
                              'You created this event',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6C63FF),
                              ),
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

  void _handleRegistration(Event event, bool isRegistered) async {
    final userId = _currentUserId;
    if (userId == null) return;
    
    // Prevent self-registration for own events
    if (event.createdByUserId == userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot register for your own event')),
      );
      return;
    }
    
    if (isRegistered) {
      await _firestoreService.unregisterFromEvent(event.id, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration cancelled')),
        );
      }
    } else {
      final success = await _firestoreService.registerForEvent(event.id, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Registered successfully!' : 'Registration failed - event may be full')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getMonthAbbr(int month) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
