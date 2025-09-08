
import 'package:admin/Screens/Maker/makercontroller.dart';
import 'package:flutter/material.dart';
import 'package:admin/Screens/Users/individual_user_details.dart';
import 'package:admin/Screens/Users/addusers.dart';

class MakerManagementPage extends StatelessWidget {
  final MakerManagementController controller;

  const MakerManagementPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Makers',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: controller.resetAndFetchUsers,
            color: const Color(0xFF666666),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchSection(controller),
          Expanded(
            child: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: controller.users,
              builder: (context, users, _) {
                final filteredUsers = _getFilteredUsers(users);

                if (filteredUsers.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildUserList(context, filteredUsers);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddUserPage()),
        ),
        backgroundColor: const Color(0xFFD13443),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchSection(MakerManagementController controller) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search makers...',
                hintStyle: const TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF666666),
                  size: 20,
                ),
                suffixIcon: ValueListenableBuilder<String>(
                  valueListenable: controller.searchQuery,
                  builder: (context, query, _) => query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF666666),
                            size: 18,
                          ),
                          onPressed: () => controller.searchController.clear(),
                        )
                      : const SizedBox.shrink(),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<String>(
            valueListenable: controller.selectedFilter,
            builder: (context, filter, _) => Row(
              children: [
                _buildFilterChip(controller, 'All', 'all', filter),
                const SizedBox(width: 8),
                _buildFilterChip(controller, 'Active', 'active', filter),
                const SizedBox(width: 8),
                _buildFilterChip(controller, 'Inactive', 'inactive', filter),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    MakerManagementController controller,
    String label,
    String value,
    String currentFilter,
  ) {
    final isSelected = currentFilter == value;
    return GestureDetector(
      onTap: () => controller.updateFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD13443) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD13443)
                : const Color(0xFFE0E0E0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF666666),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build_circle_outlined, size: 64, color: Color(0xFFCCCCCC)),
          SizedBox(height: 16),
          Text(
            'No makers found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(
    BuildContext context,
    List<Map<String, dynamic>> users,
  ) {
    return ListView.builder(
      controller: controller.scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: users.length + (controller.isLoadingMore.value ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == users.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return _buildUserCard(context, users[index]);
      },
    );
  }

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> user) {
    final isActive = user['isActive'] ?? true;
    final name = user['name'] ?? 'No Name';
    final email = user['email'] ?? 'No Email';
    final phone = user['phone'] ?? 'No Phone';
    final imageUrl = user['imageUrl'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  IndividualUserDetails(userId: user['id'], userData: user),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: const Color(0xFFF5F5F5),
                  ),
                  child: imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.build_circle_rounded,
                                  size: 24,
                                  color: Color(0xFF999999),
                                ),
                          ),
                        )
                      : const Icon(
                          Icons.build_circle_rounded,
                          size: 24,
                          color: Color(0xFF999999),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFFCCCCCC),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredUsers(
    List<Map<String, dynamic>> users,
  ) {
    return users.where((user) {
      final matchesFilter =
          controller.selectedFilter.value == 'all' ||
          (controller.selectedFilter.value == 'active' &&
              (user['isActive'] ?? true)) ||
          (controller.selectedFilter.value == 'inactive' &&
              !(user['isActive'] ?? true));

      final matchesSearch =
          controller.searchQuery.value.isEmpty ||
          (user['name']?.toLowerCase() ?? '').contains(
            controller.searchQuery.value.toLowerCase(),
          );

      return matchesFilter && matchesSearch;
    }).toList();
  }
}
