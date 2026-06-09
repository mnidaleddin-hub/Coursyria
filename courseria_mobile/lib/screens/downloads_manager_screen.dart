import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../core/constants/constants.dart';
import '../core/utils/offline_video_manager.dart';
import 'package:intl/intl.dart';

class DownloadsManagerScreen extends StatefulWidget {
  const DownloadsManagerScreen({super.key});

  @override
  State<DownloadsManagerScreen> createState() => _DownloadsManagerScreenState();
}

class _DownloadsManagerScreenState extends State<DownloadsManagerScreen> {
  final OfflineVideoManager _offlineManager = OfflineVideoManager();
  Map<String, dynamic> _downloads = {};
  double _usedStorageMB = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    setState(() => _isLoading = true);
    _downloads = _offlineManager.getAllDownloads();
    _usedStorageMB = await _offlineManager.getUsedStorageMB();
    setState(() => _isLoading = false);
  }

  Future<void> _deleteVideo(String id) async {
    await _offlineManager.deleteVideo(id);
    _loadDownloads();
    Get.snackbar("تم الحذف", "تم إزالة الفيديو من الجهاز لتوفير المساحة", 
        backgroundColor: AppColors.accentTeal, colorText: Colors.white);
  }

  Future<void> _deleteAllConfirm() async {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.secondaryNavy,
        title: const Text("حذف جميع التنزيلات؟", style: TextStyle(color: Colors.white)),
        content: const Text("هل أنت متأكد من رغبتك في حذف كافة الفيديوهات المحملة لتوفير مساحة؟", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("إلغاء", style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              for (var key in _downloads.keys.toList()) {
                await _offlineManager.deleteVideo(key);
              }
              _loadDownloads();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("حذف الكل"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      appBar: AppBar(
        title: const Text("إدارة التنزيلات", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        actions: [
          if (_downloads.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              onPressed: _deleteAllConfirm,
              tooltip: "حذف الكل",
            ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentTeal))
          : Column(
              children: [
                _buildStorageHeader(),
                Expanded(
                  child: _downloads.isEmpty 
                      ? _buildEmptyState()
                      : _buildDownloadsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildStorageHeader() {
    return Container(
      padding: EdgeInsets.all(24.w),
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.secondaryNavy,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("المساحة المستخدمة", style: TextStyle(color: Colors.white70)),
              Text("${_usedStorageMB.toStringAsFixed(1)} MB", 
                  style: TextStyle(color: AppColors.accentTeal, fontWeight: FontWeight.bold, fontSize: 18.sp)),
            ],
          ),
          SizedBox(height: 16.h),
          LinearProgressIndicator(
            value: _usedStorageMB / 2048, // Assume 2GB soft limit for visualization
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation(AppColors.accentTeal),
            minHeight: 8,
          ),
          SizedBox(height: 8.h),
          const Text("سعة التخزين تعتمد على المساحة المتوفرة في جهازك", 
              style: TextStyle(color: Colors.white24, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildDownloadsList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _downloads.length,
      itemBuilder: (context, index) {
        final key = _downloads.keys.elementAt(index);
        final item = _downloads[key];
        final sizeMB = (item['size'] ?? 0) / (1024 * 1024);
        final date = DateTime.parse(item['downloaded_at']);

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.secondaryNavy,
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Row(
            children: [
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: const Icon(Icons.movie_filter_rounded, color: AppColors.accentTeal),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title'] ?? "فيديو بدون عنوان", 
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4.h),
                    Text("${sizeMB.toStringAsFixed(1)} MB • ${DateFormat('yyyy/MM/dd').format(date)}", 
                        style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _deleteVideo(key),
                icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_download_outlined, size: 80.sp, color: Colors.white10),
          SizedBox(height: 16.h),
          const Text("لا توجد فيديوهات محملة حالياً", style: TextStyle(color: Colors.white24)),
        ],
      ),
    );
  }
}
