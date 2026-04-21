import 'package:flutter/material.dart';

class CmsUsersContent extends StatelessWidget {
  const CmsUsersContent({super.key});

  static const _navy = Color(0xFF1A2A4A);

  final _users = const [
    _UserData('Vinod Kumar',    'vinod@gmail.com',    'Active',   '24 poojas', 'Google'),
    _UserData('Priya Sharma',   'priya@gmail.com',    'Active',   '12 poojas', 'Google'),
    _UserData('Raj Naidoo',     'raj@yahoo.com',      'Active',   '8 poojas',  'Apple'),
    _UserData('Sita Govender',  'sita@gmail.com',     'Inactive', '3 poojas',  'Email'),
    _UserData('Anand Pillay',   'anand@outlook.com',  'Active',   '31 poojas', 'Google'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFE0E0E0))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFE0E0E0))),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8)
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                        const Color(0xFFF5F7FA)),
                    headingTextStyle: const TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Activity')),
                      DataColumn(label: Text('Provider')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: _users
                        .map((u) => DataRow(cells: [
                              DataCell(Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: const Color(0xFF1A2A4A),
                                    child: Text(u.name[0],
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(u.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500)),
                                ],
                              )),
                              DataCell(Text(u.email)),
                              DataCell(_StatusChip(status: u.status)),
                              DataCell(Text(u.activity)),
                              DataCell(Text(u.provider)),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                      icon: const Icon(Icons.visibility_outlined,
                                          size: 18, color: Colors.blue),
                                      onPressed: () {}),
                                  IconButton(
                                      icon: const Icon(Icons.block,
                                          size: 18, color: Colors.red),
                                      onPressed: () {}),
                                ],
                              )),
                            ]))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserData {
  const _UserData(
      this.name, this.email, this.status, this.activity, this.provider);
  final String name;
  final String email;
  final String status;
  final String activity;
  final String provider;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = status == 'Active' ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(status,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
