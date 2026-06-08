import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../controllers/group_controller.dart';
import 'group_details_screen.dart';
import 'create_group_screen.dart';

import 'package:skeletonizer/skeletonizer.dart';
import '../widgets/app_loading_indicator.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> with SingleTickerProviderStateMixin {
  final GroupController _groupController = Get.put(GroupController());
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _groupController.fetchMyGroups();
    _groupController.fetchPublicGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("المجموعات", style: AppTextStyles.header.copyWith(color: Colors.white, fontSize: 20.sp)),
        backgroundColor: context.theme.primaryColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: Colors.white, size: 28.r),
            onPressed: () => Get.to(() => const CreateGroupScreen()),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 16.sp),
          unselectedLabelStyle: AppTextStyles.body.copyWith(fontSize: 14.sp),
          tabs: const [
            Tab(text: "مجموعاتي"),
            Tab(text: "المجموعات العامة"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyGroupsTab(),
          _buildPublicGroupsTab(),
        ],
      ),
    );
  }

  Widget _buildMyGroupsTab() {
    return Obx(() {
      return Skeletonizer(
        enabled: _groupController.isLoadingGroups.value,
        child: _groupController.myGroups.isEmpty && !_groupController.isLoadingGroups.value
            ? Center(
                child: Text("لم تنضم إلى أي مجموعة بعد.", style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
              )
            : RefreshIndicator(
                onRefresh: _groupController.fetchMyGroups,
                color: context.theme.primaryColor,
                child: ListView.builder(
                  padding: EdgeInsets.all(20.r),
                  itemCount: _groupController.isLoadingGroups.value ? 2 : _groupController.myGroups.length,
                  itemBuilder: (context, index) {
                    if (_groupController.isLoadingGroups.value) {
                      return _buildFakeGroupCard();
                    }
                    final group = _groupController.myGroups[index];
                    return _buildGroupCard(group);
                  },
                ),
              ),
      );
    });
  }

  Widget _buildPublicGroupsTab() {
    return Obx(() {
      return Skeletonizer(
        enabled: _groupController.isLoadingGroups.value,
        child: _groupController.publicGroups.isEmpty && !_groupController.isLoadingGroups.value
            ? Center(
                child: Text("لا توجد مجموعات عامة متاحة.", style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
              )
            : RefreshIndicator(
                onRefresh: _groupController.fetchPublicGroups,
                color: context.theme.primaryColor,
                child: ListView.builder(
                  padding: EdgeInsets.all(20.r),
                  itemCount: _groupController.isLoadingGroups.value ? 2 : _groupController.publicGroups.length,
                  itemBuilder: (context, index) {
                    if (_groupController.isLoadingGroups.value) {
                      return _buildFakeGroupCard();
                    }
                    final group = _groupController.publicGroups[index];
                    return _buildGroupCard(group);
                  },
                ),
              ),
      );
    });
  }

  Widget _buildFakeGroupCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 15.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 120.h, width: double.infinity, color: Colors.grey),
          Padding(
            padding: EdgeInsets.all(15.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 150, height: 18, color: Colors.grey),
                SizedBox(height: 8.h),
                Container(width: double.infinity, height: 12, color: Colors.grey),
                SizedBox(height: 4.h),
                Container(width: 200, height: 12, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(Group group) {
    return GestureDetector(
      onTap: () => Get.to(() => GroupDetailsScreen(group: group)),
      child: Container(
        margin: EdgeInsets.only(bottom: 15.h),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? AppColors.darkCard : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(15.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (group.coverImageUrl != null && group.coverImageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(15.r)),
                child: CachedNetworkImage(
                  imageUrl: group.coverImageUrl!,
                  height: 120.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 120.h,
                    color: Colors.grey[200],
                    child: const AppLoadingIndicator(),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 120.h,
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image, color: AppColors.textMuted, size: 50.r),
                  ),
                ),
              )
            else
              Container(
                height: 120.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15.r)),
                ),
                child: Icon(PhosphorIcons.usersThree(), color: context.theme.primaryColor, size: 50.r),
              ),
            Padding(
              padding: EdgeInsets.all(15.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: AppTextStyles.header.copyWith(fontSize: 18.sp, color: Get.isDarkMode ? Colors.white : AppColors.primaryNavy),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    group.description,
                    style: AppTextStyles.body.copyWith(fontSize: 12.sp, color: AppColors.textMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Icon(PhosphorIcons.users(), size: 18.r, color: context.theme.primaryColor),
                      SizedBox(width: 5.w),
                      Text(
                        '${group.memberCount} أعضاء',
                        style: AppTextStyles.body.copyWith(fontSize: 12.sp, color: Get.isDarkMode ? Colors.white70 : AppColors.textMain),
                      ),
                      SizedBox(width: 15.w),
                      Icon(PhosphorIcons.chats(), size: 18.r, color: context.theme.primaryColor),
                      SizedBox(width: 5.w),
                      Text(
                        '${group.postCount} منشورات',
                        style: AppTextStyles.body.copyWith(fontSize: 12.sp, color: Get.isDarkMode ? Colors.white70 : AppColors.textMain),
                      ),
                      const Spacer(),
                      if (group.isPrivate)
                        Icon(PhosphorIcons.lockSimple(), size: 18.r, color: AppColors.textMuted),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
