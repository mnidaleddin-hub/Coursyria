import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../models/group_model.dart';
import '../models/group_member_model.dart';
import '../controllers/group_controller.dart';
import '../controllers/ai_controller.dart';
import 'group_posts_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final Group group;
  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> with SingleTickerProviderStateMixin {
  final GroupController _groupController = Get.find<GroupController>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _groupController.fetchGroupDetails(widget.group.id); // Fetch latest details
    _groupController.fetchGroupMembers(widget.group.id); // Fetch members
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Obx(() {
        final group = _groupController.currentGroup.value ?? widget.group; // Use observable if available

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 250.h,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsetsDirectional.only(start: 20.w, bottom: 15.h),
                title: Text(group.name, style: AppTextStyles.header.copyWith(color: Colors.white, fontSize: 18.sp)),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (group.coverImageUrl != null && group.coverImageUrl!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: group.coverImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[800],
                          child: const Center(child: CircularProgressIndicator(color: AppColors.accentTeal, strokeWidth: 2)),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[800],
                          child: Center(child: Icon(Icons.broken_image, color: AppColors.textMuted, size: 50.r)),
                        ),
                      )
                    else
                      Container(
                        color: AppColors.primaryNavy,
                        child: Center(child: Icon(PhosphorIcons.usersThree(), color: Colors.white, size: 80.r)),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.5),
                            Colors.transparent,
                            Colors.black.withOpacity(0.7)
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Get.back(),
              ),
              actions: [
                // TODO: Add group settings/edit button for owner
                if (group.ownerId == _groupController.supabase.auth.currentUser?.id)
                  IconButton(
                    icon: const Icon(Icons.settings_rounded, color: Colors.white),
                    onPressed: () {
                      Get.snackbar("إعدادات المجموعة", "سيتم تنفيذ شاشة الإعدادات قريباً");
                    },
                  ),
              ],
            ),
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.darkBg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.description, style: AppTextStyles.body.copyWith(color: Colors.white70, fontSize: 14.sp, height: 1.5)),
                    SizedBox(height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(group.memberCount, "أعضاء"),
                        _buildStatItem(group.postCount, "منشورات"),
                        _buildPrivacyStatus(group.isPrivate),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    _buildJoinLeaveButton(group),
                    if (group.isMember == true) ...[
                      SizedBox(height: 16.h),
                      _buildGroupAIActions(group),
                    ],
                    SizedBox(height: 20.h),
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.accentTeal,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      labelStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 16.sp),
                      unselectedLabelStyle: AppTextStyles.body.copyWith(fontSize: 14.sp),
                      tabs: const [
                        Tab(text: "المنشورات"),
                        Tab(text: "الأعضاء"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  GroupPostsScreen(groupId: group.id), // Display group posts
                  _buildMembersList(), // Display group members
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildGroupAIActions(Group group) {
    final aiController = Get.find<AIController>();
    return Row(
      children: [
        Expanded(
          child: _buildSmallAIAction(
            "أسئلة ذكية",
            Icons.help_center_rounded,
            AppColors.accentTeal,
            () => aiController.getGroupQuestions(group.name, [group.description]),
            isLoading: aiController.isGeneratingGroupQuestions,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildSmallAIAction(
            "تقسيم المهام",
            Icons.assignment_ind_rounded,
            Colors.orangeAccent,
            () => aiController.suggestTasks(
              _groupController.groupMembers.map((m) => m.userName ?? "عضو").toList(),
              group.description,
            ),
            isLoading: aiController.isSuggestingTasks,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallAIAction(String title, IconData icon, Color color, VoidCallback onTap, {required RxBool isLoading}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() => isLoading.value
                ? SizedBox(height: 16.r, width: 16.r, child: CircularProgressIndicator(strokeWidth: 2, color: color))
                : Icon(icon, color: color, size: 20.r)),
            SizedBox(width: 8.w),
            Text(title, style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(int count, String label) {
    return Column(
      children: [
        Text(count.toString(), style: AppTextStyles.header.copyWith(color: Colors.white, fontSize: 20.sp)),
        Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textMuted, fontSize: 12.sp)),
      ],
    );
  }

  Widget _buildPrivacyStatus(bool isPrivate) {
    return Column(
      children: [
        Icon(isPrivate ? PhosphorIcons.lockSimple() : PhosphorIcons.globeHemisphereWest(),
            color: isPrivate ? Colors.orangeAccent : AppColors.accentTeal, size: 24.r),
        Text(isPrivate ? "خاصة" : "عامة", style: AppTextStyles.body.copyWith(color: AppColors.textMuted, fontSize: 12.sp)),
      ],
    );
  }

  void _showJoinCodeDialog(Group group) {
    final TextEditingController codeController = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.primaryNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text("كود الانضمام", style: AppTextStyles.header.copyWith(color: Colors.white, fontSize: 18.sp)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("هذه المجموعة خاصة، يرجى إدخال كود الانضمام لتتمكن من الدخول.",
                style: AppTextStyles.body.copyWith(color: Colors.white70, fontSize: 13.sp)),
            SizedBox(height: 20.h),
            TextField(
              controller: codeController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "أدخل الكود هنا...",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("إلغاء", style: AppTextStyles.body.copyWith(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              if (codeController.text.isNotEmpty) {
                Get.back();
                _groupController.joinGroup(group.id, joinCode: codeController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentTeal),
            child: Text("انضمام", style: AppTextStyles.button.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinLeaveButton(Group group) {
    if (group.isMember == true) {
      return ElevatedButton(
        onPressed: _groupController.isLoadingGroups.value
            ? null
            : () => _groupController.leaveGroup(group.id),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent.withOpacity(0.8),
          minimumSize: Size(double.infinity, 50.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        ),
        child: _groupController.isLoadingGroups.value
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                "مغادرة المجموعة",
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
      );
    } else {
      return ElevatedButton(
        onPressed: _groupController.isLoadingGroups.value
            ? null
            : () {
                if (group.isPrivate) {
                  _showJoinCodeDialog(group);
                } else {
                  _groupController.joinGroup(group.id);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentTeal,
          minimumSize: Size(double.infinity, 50.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
          elevation: 5,
        ),
        child: _groupController.isLoadingGroups.value
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                "الانضمام إلى المجموعة",
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
      );
    }
  }

  Widget _buildMembersList() {
    return Obx(() {
      if (_groupController.isLoadingGroups.value) {
        return const Center(child: CircularProgressIndicator(color: AppColors.accentTeal));
      } else if (_groupController.groupMembers.isEmpty) {
        return Center(
            child: Text("لا يوجد أعضاء في هذه المجموعة.", style: AppTextStyles.body.copyWith(color: AppColors.textMuted)));
      } else {
        return ListView.builder(
          padding: EdgeInsets.all(20.r),
          itemCount: _groupController.groupMembers.length,
          itemBuilder: (context, index) {
            final member = _groupController.groupMembers[index];
            return Card(
              margin: EdgeInsets.only(bottom: 10.h),
              color: AppColors.surfaceWhite,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 20.r,
                  backgroundColor: AppColors.accentTeal.withOpacity(0.2),
                  backgroundImage: member.userAvatarUrl != null && member.userAvatarUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(member.userAvatarUrl!)
                      : null,
                  child: member.userAvatarUrl == null || member.userAvatarUrl!.isEmpty
                      ? Icon(PhosphorIcons.user(), color: AppColors.accentTeal, size: 24.r)
                      : null,
                ),
                title: Text(member.userName ?? "مستخدم كورسيريا", style: AppTextStyles.header.copyWith(fontSize: 14.sp, color: AppColors.primaryNavy)),
                subtitle: Text(member.role, style: AppTextStyles.body.copyWith(fontSize: 12.sp, color: AppColors.textMuted)),
                trailing: member.userId == _groupController.supabase.auth.currentUser?.id
                    ? const Icon(Icons.star, color: Colors.amber) // Indicate current user
                    : null,
              ),
            );
          },
        );
      }
    });
  }
}
