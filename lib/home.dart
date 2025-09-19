import 'package:admin/Auth/sigin.dart';
import 'package:admin/Controller/home_controller.dart';
import 'package:admin/Lost_Report/Lost_Report_list.dart';
import 'package:admin/Screens/Complaint/ComplaintPage.dart';
import 'package:admin/Screens/LeadReport/LeadReportPage.dart';
import 'package:admin/Screens/Maker/MakerManagementPage.dart';
import 'package:admin/Screens/Maker/makercontroller.dart';
import 'package:admin/Screens/Orders/Order_report.dart';
import 'package:admin/Screens/PostSaleFollowUp/postsalefollowup.dart';
import 'package:admin/Screens/Sales/listsalesmen.dart';
import 'package:admin/Screens/Sales/salescontroller.dart';
import 'package:admin/Screens/product/listproducts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Dashboard extends StatelessWidget {
  Dashboard({super.key});
  final HomeController controller = Get.put(HomeController());

  final salescontroller = SalesManagementController();
  final makercontroller = MakerManagementController();
  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => Signin()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargeScreen = screenSize.width > 900;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      body: Builder(
        builder: (context) {
          final screenSize = MediaQuery.of(context).size;

          return SafeArea(
            child: Column(
              children: [
                _buildHeader(context, screenSize),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      top: isLandscape ? 8 : screenSize.height * 0.02,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await controller.refreshData();
                      },
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(
                          isLandscape ? 8 : screenSize.width * 0.04,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final availableHeight = constraints.maxHeight;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildWelcomeSection(context, screenSize),
                                SizedBox(
                                  height: isLandscape || availableHeight < 400
                                      ? 8
                                      : screenSize.height * 0.025,
                                ),
                                _buildStatsCards(context, screenSize),
                                SizedBox(
                                  height: isLandscape || availableHeight < 400
                                      ? 8
                                      : screenSize.height * 0.03,
                                ),
                                _buildSalesChart(context, screenSize),
                                SizedBox(
                                  height: isLandscape || availableHeight < 400
                                      ? 8
                                      : screenSize.height * 0.03,
                                ),
                                Text(
                                  'Quick Actions',
                                  style: TextStyle(
                                    fontSize: screenSize.width * 0.05,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                SizedBox(
                                  height: isLandscape || availableHeight < 400
                                      ? 8
                                      : screenSize.height * 0.02,
                                ),
                                _buildDashboardGrid(
                                  context,
                                  screenSize,
                                  isTablet,
                                  isLargeScreen,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Size screenSize) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.05,
        vertical: screenSize.height * 0.015,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 209, 52, 67),
            Color.fromARGB(255, 193, 22, 51),
          ],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Scaffold.of(context).openDrawer();
            },
            child: Container(
              width: screenSize.width * 0.11,
              height: screenSize.width * 0.11,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 209, 52, 67),
                    Color.fromARGB(255, 193, 22, 51),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(
                      255,
                      245,
                      34,
                      11,
                    ).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.menu,
                color: Colors.white,
                size: screenSize.width * 0.045,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'DASHBOARD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenSize.width * 0.045,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: screenSize.width * 0.03,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: screenSize.width * 0.11,
            height: screenSize.width * 0.11,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.logout,
                color: Colors.white,
                size: screenSize.width * 0.05,
              ),
              onPressed: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
                if (shouldLogout == true) {
                  await controller.logout();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, Size screenSize) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Container(
      padding: EdgeInsets.all(isLandscape ? 8 : screenSize.width * 0.04),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 209, 52, 67),
            Color.fromARGB(255, 209, 63, 87),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenSize.width * 0.05,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isLandscape ? 4 : screenSize.height * 0.005),
                Text(
                  'Manage your business efficiently',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: screenSize.width * 0.035,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.dashboard_outlined,
            color: Colors.white,
            size: screenSize.width * 0.08,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, Size screenSize) {
    return Row(
      children: [
        Expanded(
          child: Obx(
            () => _buildStatCard(
              context,
              'Total Sales',
              controller.totalsalescount.value.toString(),
              Icons.trending_up,
              const Color(0xFF10B981),
              screenSize,
            ),
          ),
        ),
        SizedBox(width: screenSize.width * 0.03),
        Expanded(
          child: Obx(
            () => _buildStatCard(
              context,
              'Active Orders',
              controller.totalordercount.value.toString(),
              Icons.shopping_cart,
              const Color.fromARGB(255, 209, 52, 67),
              screenSize,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    context,
    String title,
    String value,
    IconData icon,
    Color color,
    Size screenSize,
  ) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Container(
      padding: EdgeInsets.all(isLandscape ? 8 : screenSize.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: screenSize.width * 0.05),
              ),
            ],
          ),
          SizedBox(height: isLandscape ? 4 : screenSize.height * 0.01),
          Text(
            value,
            style: TextStyle(
              fontSize: screenSize.width * 0.055,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: screenSize.width * 0.032,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart(BuildContext context, Size screenSize) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Container(
      constraints: BoxConstraints(
        maxHeight: isLandscape ? 150 : screenSize.height * 0.35,
        minHeight: 150,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isLandscape ? 8 : screenSize.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sales Growth',
                  style: TextStyle(
                    fontSize: screenSize.width * 0.045,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            SizedBox(height: isLandscape ? 8 : screenSize.height * 0.02),
            Expanded(
              child: Obx(() {
                final data = controller.yearlySalesSpots;
                if (data.isEmpty) {
                  return Center(
                    child: Text(
                      "No sales data available",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: screenSize.width * 0.04,
                      ),
                    ),
                  );
                }

                final maxY = data
                    .map((e) => e.y)
                    .reduce((a, b) => a > b ? a : b);
                final roundedMaxY = ((maxY + 19) ~/ 20) * 20;

                return LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: roundedMaxY.toDouble(),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (value) => const FlLine(
                        color: Color(0xFFE2E8F0),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 10,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value % 10 == 0 && value != 0) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: const Color(0xFF64748B),
                                  fontSize: screenSize.width * 0.028,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            const months = [
                              'Jan',
                              'Feb',
                              'Mar',
                              'Apr',
                              'May',
                              'Jun',
                              'Jul',
                              'Aug',
                              'Sep',
                              'Oct',
                              'Nov',
                              'Dec',
                            ];

                            final currentMonth = DateTime.now().month;

                            if (value.toInt() >= 0 &&
                                value.toInt() < currentMonth) {
                              return Text(
                                months[value.toInt()],
                                style: TextStyle(
                                  color: const Color(0xFF64748B),
                                  fontSize: screenSize.width * 0.028,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: data
                            .where(
                              (spot) =>
                                  spot.x < DateTime.now().month.toDouble(),
                            )
                            .toList(),
                        isCurved: true,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        ),
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 5,
                              color: const Color(0xFF3B82F6),
                              strokeWidth: 3,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF3B82F6).withOpacity(0.1),
                              const Color(0xFF3B82F6).withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardGrid(
    BuildContext context,
    Size screenSize,
    bool isTablet,
    bool isLargeScreen,
  ) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    int crossAxisCount = isLargeScreen
        ? 4
        : isTablet
        ? 3
        : 2;
    double childAspectRatio = isTablet
        ? 1.2
        : isLandscape
        ? 1.5
        : 1.1;

    final List<DashboardItem> items = [
      DashboardItem(
        'Sales Management',
        Icons.analytics_outlined,
        const Color(0xFF3B82F6),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SalesManagementPage(controller: salescontroller),
            ),
          );
        },
      ),
      DashboardItem(
        'Maker Management',
        Icons.people_outline,
        const Color(0xFF10B981),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MakerManagementPage(controller: makercontroller),
            ),
          );
        },
      ),
      DashboardItem(
        'Lead Report',
        Icons.phone_outlined,
        const Color(0xFFF59E0B),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LeadReport()),
          );
        },
      ),
      DashboardItem(
        'Order Report',
        Icons.receipt_long_outlined,
        const Color(0xFF8B5CF6),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => OrderReport()),
          );
        },
      ),
      DashboardItem(
        'Follow Up Report',
        Icons.assignment_outlined,
        const Color(0xFFEF4444),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Postsalefollowup()),
          );
        },
      ),
      DashboardItem(
        'Lost Lead Report',
        Icons.report_gmailerrorred_outlined,
        const Color(0xFFEF4444),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LostReportList()),
          );
        },
      ),
      DashboardItem(
        'Product Adding',
        Icons.add_business_outlined,
        const Color(0xFF06B6D4),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProductListPage()),
          );
        },
      ),
      DashboardItem(
        'Complaint Page',
        Icons.feedback_outlined,
        const Color(0xFFEC4899),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ComplaintPage()),
          );
        },
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: screenSize.width * 0.03,
        mainAxisSpacing: screenSize.width * 0.03,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildDashboardCard(
          item.title,
          item.icon,
          item.color,
          screenSize,
          context,
          item.onTap,
        );
      },
    );
  }

  Widget _buildDashboardCard(
    String title,
    IconData icon,
    Color color,
    Size screenSize,
    BuildContext context,
    VoidCallback? onTap,
  ) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap:
              onTap ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening $title...'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
          child: Padding(
            padding: EdgeInsets.all(isLandscape ? 8 : screenSize.width * 0.04),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: screenSize.width * 0.13,
                  height: screenSize.width * 0.13,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.2), width: 1),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: screenSize.width * 0.06,
                  ),
                ),
                SizedBox(height: isLandscape ? 8 : screenSize.height * 0.015),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenSize.width * 0.035,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  DashboardItem(this.title, this.icon, this.color, {this.onTap});
}
