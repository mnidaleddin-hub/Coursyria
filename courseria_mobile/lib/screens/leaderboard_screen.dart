import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/constants.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _topStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('full_name, total_points, avatar_url')
          .order('total_points', ascending: false)
          .limit(20);
      
      setState(() {
        _topStudents = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching leaderboard: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      appBar: AppBar(
        title: Text("لوحة المتصدرين 🏆", style: TextStyle(color: Colors.white, fontSize: 18.sp)),
        backgroundColor: AppColors.secondaryNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentTeal))
          : Column(
              children: [
                // 1. Top 3 Podium
                if (_topStudents.length >= 3) _buildPodium(),
                
                // 2. The Rest List
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                    itemCount: _topStudents.length > 3 ? _topStudents.length - 3 : 0,
                    itemBuilder: (context, index) {
                      final student = _topStudents[index + 3];
                      return _buildLeaderboardTile(index + 4, student);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPodium() {
    return Container(
      height: 220.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: const BoxDecoration(
        color: AppColors.secondaryNavy,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildPodiumSpot(_topStudents[1], 2, Colors.grey[400]!, 120.h),
          _buildPodiumSpot(_topStudents[0], 1, Colors.amber, 160.h),
          _buildPodiumSpot(_topStudents[2], 3, Colors.brown[400]!, 100.h),
        ],
      ),
    );
  }

  Widget _buildPodiumSpot(Map<String, dynamic> student, int rank, Color color, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: (rank == 1 ? 35 : 30).r,
          backgroundColor: color,
          child: CircleAvatar(
            radius: (rank == 1 ? 32 : 27).r,
            backgroundColor: AppColors.primaryNavy,
            child: Text(student['full_name'][0], style: const TextStyle(color: Colors.white)),
          ),
        ),
        SizedBox(height: 8.h),
        Text(student['full_name'], style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        Text("${student['total_points']} نقطة", style: TextStyle(color: color, fontSize: 10.sp)),
        SizedBox(height: 10.h),
        Container(
          width: 60.w,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Center(
            child: Text("#$rank", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18.sp)),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTile(int rank, Map<String, dynamic> student) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.secondaryNavy,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Text("#$rank", style: TextStyle(color: Colors.white54, fontSize: 14.sp, fontWeight: FontWeight.bold)),
          SizedBox(width: 15.w),
          CircleAvatar(
            radius: 20.r,
            backgroundColor: AppColors.primaryNavy,
            child: Text(student['full_name'][0], style: const TextStyle(color: Colors.white)),
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: Text(student['full_name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Text(
            "${student['total_points']} نقطة",
            style: const TextStyle(color: AppColors.accentTeal, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
