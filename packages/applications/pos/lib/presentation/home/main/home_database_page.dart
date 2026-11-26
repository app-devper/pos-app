// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:um/presentation/constants.dart';

// Project imports:
import 'package:pos/presentation/constants.dart';

/// The "จัดการ" landing page. Each tile pushes its page on top of this one,
/// so Back (the arrow, Android's button, the browser's) returns here.
class HomeDatabasePage extends StatelessWidget {
  const HomeDatabasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.store,
          title: 'ร้านค้าของฉัน',
          onTap: () {
            _nextToStoreInfo(context);
          },
        ),
        _buildMenuItem(
          icon: Icons.person,
          title: 'จัดการลูกค้า',
          onTap: () {
            Navigator.pushNamed(context, customersRoute);
          },
        ),
        _buildMenuItem(
          icon: Icons.account_box,
          title: 'จัดการผู้ใช้งาน',
          onTap: () {
            _nextToUserManagement(context);
          },
        ),
        _buildMenuItem(
          icon: Icons.receipt_long,
          title: 'ใบรับสินค้า / Goods Receipt',
          onTap: () {
            Navigator.pushNamed(context, receivesRoute);
          },
        ),
        _buildMenuItem(
          icon: Icons.fact_check,
          title: 'นับสต็อก',
          onTap: () {
            _nextToStockCounts(context);
          },
        ),
      ],
    );
  }

  Column _buildMenuItem(
      {required IconData icon,
      required String title,
      required Null Function() onTap}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon),
          title: Text(title, style: const TextStyle(fontSize: 20)),
          onTap: onTap,
        ),
        const Divider(height: 1),
      ],
    );
  }

  void _nextToUserManagement(BuildContext context) {
    Navigator.pushNamed(context, routeUsers);
  }

  void _nextToStoreInfo(BuildContext context) {
    Navigator.pushNamed(context, supplierRoute);
  }

  void _nextToStockCounts(BuildContext context) {
    Navigator.pushNamed(context, stockCountsRoute);
  }
}
