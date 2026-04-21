import 'package:flutter/material.dart';

class CmsNotificationsContent extends StatelessWidget {
  const CmsNotificationsContent({super.key});

  static const _navy   = Color(0xFF1A2A4A);
  static const _orange = Color(0xFFE8590A);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Send notification card ───────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05), blurRadius: 8)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Send Push Notification',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _navy)),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. Diwali is tomorrow!'),
                ),
                const SizedBox(height: 12),
                const TextField(
                  maxLines: 3,
                  decoration: InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                      hintText: 'Enter notification message...'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                            labelText: 'Target Audience',
                            border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(
                              value: 'all', child: Text('All Users')),
                          DropdownMenuItem(
                              value: 'active',
                              child: Text('Active Users')),
                          DropdownMenuItem(
                              value: 'new', child: Text('New Users')),
                        ],
                        onChanged: (_) {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Schedule (optional)',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today,
                                  size: 18),
                              onPressed: () {}),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Send Notification'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Recent notifications ─────────────────────────────
          const Text('Recently Sent',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _navy)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: const [
                _NotifTile(
                  title: 'Diwali Celebration Reminder',
                  message: 'Don\'t forget tonight\'s Lakshmi Pooja ritual!',
                  sentTo: '1,240 users',
                  time: '2 days ago',
                ),
                _NotifTile(
                  title: 'New Ritual Added',
                  message: 'Shiva Abhishekam is now available in the app.',
                  sentTo: '1,240 users',
                  time: '5 days ago',
                ),
                _NotifTile(
                  title: 'Full Moon Tonight',
                  message: 'Complete your full moon ritual before 9 PM.',
                  sentTo: '1,240 users',
                  time: '1 week ago',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({
    required this.title,
    required this.message,
    required this.sentTo,
    required this.time,
  });
  final String title;
  final String message;
  final String sentTo;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: const Color(0xFFE8590A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.notifications,
                color: Color(0xFFE8590A), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF1A2A4A))),
                const SizedBox(height: 2),
                Text(message,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.people_outline,
                        size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(sentTo,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time,
                        size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(time,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
