import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:courseria_mobile/controllers/auth_controller.dart';
import '../services/ai_service.dart';
import 'admin_broadcast_screen.dart';
import '../models/course_model.dart';
import '../controllers/teacher_controller.dart';
import '../controllers/course_controller.dart';
import '../core/constants/constants.dart';

class TeacherPanelScreen extends StatefulWidget {
  const TeacherPanelScreen({super.key});

  @override
  State<TeacherPanelScreen> createState() => _TeacherPanelScreenState();
}

class _TeacherPanelScreenState extends State<TeacherPanelScreen> with SingleTickerProviderStateMixin {
  final _teacherController = Get.find<TeacherController>();
  final _courseController = Get.find<CourseController>();
  late TabController _tabController;
  
  // Upload Lesson Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCourseId;

  // New Course Request Controllers
  final _reqTitleController = TextEditingController();
  final _reqSubjectController = TextEditingController();
  final _reqGradeController = TextEditingController();
  final _reqPriceController = TextEditingController();
  final _reqDescController = TextEditingController();
  final _reqNotesController = TextEditingController();

  Course? _selectedCourseForManagement;
  List<Lesson> _courseLessons = [];
  bool _isLoadingLessons = false;
  final Map<String, TextEditingController> _replyControllers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _reqTitleController.dispose();
    _reqSubjectController.dispose();
    _reqGradeController.dispose();
    _reqPriceController.dispose();
    _reqDescController.dispose();
    _reqNotesController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      appBar: AppBar(
        title: const Text('لوحة تحكم المعلم', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.secondaryNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_rounded, color: AppColors.accentTeal),
            onPressed: () => Get.to(() => const AdminBroadcastScreen()),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentTeal,
          labelColor: AppColors.accentTeal,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: "رفع دروس", icon: Icon(Icons.upload_file)),
            Tab(text: "إدارة", icon: Icon(Icons.manage_accounts_outlined)),
            Tab(text: "التعليقات", icon: Icon(Icons.comment_outlined)),
            Tab(text: "طلب كورس", icon: Icon(Icons.add_to_photos)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUploadLessonTab(),
          _buildManagementTab(),
          _buildCommentsTab(),
          _buildRequestCourseTab(),
        ],
      ),
    );
  }

  Widget _buildUploadLessonTab() {
    return Obx(() {
      if (_teacherController.isLoading.value) {
        return _buildLoadingOverlay();
      }

      // Filter courses: Only approved ones can have lessons added
      final currentTeacherId = Get.find<AuthController>().userData['id'];
      final approvedCourses = _courseController.allCourses.where((c) => c.status == 'approved').toList();
      final pendingCourses = _courseController.allCourses.where((c) => c.status == 'pending' && c.teacherId == currentTeacherId).toList();

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pendingCourses.isNotEmpty) ...[
               _buildPendingSection(pendingCourses),
               const SizedBox(height: 30),
               const Divider(color: Colors.white10),
               const SizedBox(height: 10),
            ],
            const Text(
              "إضافة درس جديد",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildTextField(controller: _titleController, label: "عنوان الفيديو", hint: "أدخل عنوان الدرس"),
            const SizedBox(height: 15),
            _buildTextField(controller: _descriptionController, label: "الوصف", hint: "أدخل وصف الدرس", maxLines: 3),
            const SizedBox(height: 15),
            _buildCourseDropdown(approvedCourses),
            const SizedBox(height: 20),
            _buildFilePicker(),
            const SizedBox(height: 30),
            _buildUploadButton(),
          ],
        ),
      );
    });
  }

  Widget _buildRequestCourseTab() {
    return Obx(() {
       if (_teacherController.isLoading.value) {
        return _buildLoadingOverlay();
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "طلب إنشاء كورس جديد",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildTextField(controller: _reqTitleController, label: "عنوان الكورس", hint: "مثال: فيزياء للثانوية العامة"),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildTextField(controller: _reqSubjectController, label: "التخصص/المادة", hint: "مثال: فيزياء")),
                const SizedBox(width: 15),
                Expanded(child: _buildTextField(controller: _reqGradeController, label: "الصف الدراسي", hint: "مثال: الثالث ثانوي")),
              ],
            ),
            const SizedBox(height: 15),
            _buildTextField(controller: _reqPriceController, label: "السعر المقترح", hint: "مثال: 50000", keyboardType: TextInputType.number),
            const SizedBox(height: 15),
            _buildTextField(controller: _reqDescController, label: "وصف الكورس", hint: "أدخل وصفاً مختصراً للكورس", maxLines: 3),
            const SizedBox(height: 15),
            _buildTextField(controller: _reqNotesController, label: "ملاحظات للإدارة", hint: "أي تفاصيل إضافية تود إخبارنا بها", maxLines: 2),
            const SizedBox(height: 30),
            _buildRequestButton(),
          ],
        ),
      );
    });
  }

  Widget _buildPendingSection(List<Course> pendingCourses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "بانتظار موافقة الإدارة",
          style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: pendingCourses.length,
            itemBuilder: (context, index) {
              final course = pendingCourses[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 15),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    Text(course.subject, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                      child: const Text("قيد المراجعة", style: TextStyle(color: Colors.amber, fontSize: 10)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.accentTeal),
            const SizedBox(height: 30),
            Text(
              "جاري العمل... ${( _teacherController.uploadProgress.value * 100).toInt()}%",
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            LinearProgressIndicator(
              value: _teacherController.uploadProgress.value,
              backgroundColor: Colors.white10,
              color: AppColors.accentTeal,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseDropdown(List<Course> courses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("اختر الكورس (المعتمد فقط)", style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: AppColors.secondaryNavy, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCourseId,
              hint: const Text("اختر الكورس التابع له", style: TextStyle(color: Colors.white54)),
              dropdownColor: AppColors.secondaryNavy,
              isExpanded: true,
              style: const TextStyle(color: Colors.white),
              items: courses.map((course) {
                return DropdownMenuItem<String>(value: course.id, child: Text(course.title));
              }).toList(),
              onChanged: (value) => setState(() => _selectedCourseId = value),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("ملف الفيديو", style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _teacherController.pickVideo(),
          child: Container(
            height: 100, width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.secondaryNavy, 
              borderRadius: BorderRadius.circular(10), 
              border: Border.all(color: AppColors.accentTeal.withOpacity(0.3))
            ),
            child: Center(
              child: Obx(() {
                final file = _teacherController.selectedFile.value;
                if (file == null) {
                  return const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.video_library, color: AppColors.accentTeal, size: 30), SizedBox(height: 5), Text("اضغط لاختيار فيديو من المعرض", style: TextStyle(color: Colors.white54))]);
                }
                return Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.check_circle, color: Colors.green, size: 30), const SizedBox(height: 5), Text(file.path.split('/').last, style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)]);
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity, height: 50,
      child: ElevatedButton(
        onPressed: () {
          if (_titleController.text.isEmpty || _descriptionController.text.isEmpty || _selectedCourseId == null) {
            Get.snackbar("تنبيه", "يرجى ملء جميع الحقول");
            return;
          }
          _teacherController.uploadLesson(title: _titleController.text, description: _descriptionController.text, courseId: _selectedCourseId!);
        },
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: const Text("رفع الدرس الآن", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildRequestButton() {
    return SizedBox(
      width: double.infinity, height: 50,
      child: ElevatedButton(
        onPressed: () {
          if (_reqTitleController.text.isEmpty || _reqSubjectController.text.isEmpty || _reqGradeController.text.isEmpty || _reqPriceController.text.isEmpty) {
            Get.snackbar("تنبيه", "يرجى ملء جميع الحقول الأساسية");
            return;
          }
          _teacherController.requestNewCourse({
            'title': _reqTitleController.text,
            'subject': _reqSubjectController.text,
            'grade_level': _reqGradeController.text,
            'price': double.tryParse(_reqPriceController.text) ?? 0,
            'description': _reqDescController.text,
            'general_notes': _reqNotesController.text,
          });
          // Clear form
          _reqTitleController.clear();
          _reqSubjectController.clear();
          _reqGradeController.clear();
          _reqPriceController.clear();
          _reqDescController.clear();
          _reqNotesController.clear();
        },
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: const Text("إرسال الطلب للإدارة", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildManagementTab() {
    return Obx(() {
      final currentTeacherId = Get.find<AuthController>().userData['id'];
      final myCourses = _courseController.allCourses.where((c) => c.teacherId == currentTeacherId).toList();

      if (myCourses.isEmpty) {
        return const Center(child: Text("ليس لديك كورسات لإدارتها بعد", style: TextStyle(color: Colors.white54)));
      }

      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("إدارة الكورسات والفيديوهات", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildManagementCourseSelector(myCourses),
            const SizedBox(height: 20),
            if (_selectedCourseForManagement != null) ...[
              _buildCourseActionButtons(_selectedCourseForManagement!),
              const SizedBox(height: 20),
              const Text("الفيديوهات (اسحب لإعادة الترتيب)", style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 10),
              Expanded(child: _buildLessonsReorderableList()),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildManagementCourseSelector(List<Course> courses) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppColors.secondaryNavy, borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Course>(
          value: _selectedCourseForManagement,
          hint: const Text("اختر الكورس للإدارة", style: TextStyle(color: Colors.white54)),
          dropdownColor: AppColors.secondaryNavy,
          isExpanded: true,
          style: const TextStyle(color: Colors.white),
          items: courses.map((course) {
            return DropdownMenuItem<Course>(value: course, child: Text(course.title));
          }).toList(),
          onChanged: (course) async {
            setState(() {
              _selectedCourseForManagement = course;
              _isLoadingLessons = true;
            });
            // Fetch lessons for this course
            if (course != null) {
              final lessons = await _fetchLessonsForCourse(course.id);
              setState(() {
                _courseLessons = lessons;
                _isLoadingLessons = false;
              });
            }
          },
        ),
      ),
    );
  }

  Future<List<Lesson>> _fetchLessonsForCourse(String courseId) async {
    final response = await Supabase.instance.client
        .from('lessons')
        .select()
        .eq('course_id', courseId)
        .order('sort_order', ascending: true);
    return (response as List).map((json) => Lesson.fromJson(json)).toList();
  }

  Widget _buildCourseActionButtons(Course course) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showDeleteConfirmation(course.title, () => _teacherController.deleteCourse(course.id)),
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            label: const Text("حذف الكورس"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildLessonsReorderableList() {
    if (_isLoadingLessons) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentTeal));
    }
    if (_courseLessons.isEmpty) {
      return const Center(child: Text("لا توجد دروس في هذا الكورس", style: TextStyle(color: Colors.white24)));
    }

    return ReorderableListView(
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final Lesson lesson = _courseLessons.removeAt(oldIndex);
          _courseLessons.insert(newIndex, lesson);
        });
        _teacherController.updateLessonOrder(_selectedCourseForManagement!.id, _courseLessons);
      },
      children: _courseLessons.map<Widget>((lesson) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            key: ValueKey(lesson.id),
            tileColor: AppColors.secondaryNavy,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: const Icon(Icons.drag_handle, color: Colors.white24),
            title: Text(lesson.title, style: const TextStyle(color: Colors.white)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.accentTeal),
                  onPressed: () => _showRenameDialog(lesson),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _showDeleteConfirmation(lesson.title, () => _teacherController.deleteLesson(lesson.id)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showRenameDialog(Lesson lesson) {
    final controller = TextEditingController(text: lesson.title);
    Get.defaultDialog(
      title: "تعديل اسم الدرس",
      backgroundColor: AppColors.secondaryNavy,
      titleStyle: const TextStyle(color: Colors.white),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "اسم الدرس الجديد",
              hintStyle: TextStyle(color: Colors.white24),
            ),
          ),
          const SizedBox(height: 15),
          TextButton.icon(
            onPressed: () async {
              Get.dialog(const Center(child: CircularProgressIndicator(color: AppColors.accentTeal)), barrierDismissible: false);
              try {
                final ai = AIService();
                final suggestion = await ai.suggestSmartReply("كيف يمكنني إعادة تسمية درسي بأسلوب جذاب؟ العنوان الحالي هو: ${lesson.title}");
                Get.back();
                Get.snackbar("اقتراح ذكي 🧠", suggestion, backgroundColor: AppColors.accentTeal, colorText: Colors.white, duration: const Duration(seconds: 10));
              } catch (e) {
                Get.back();
              }
            },
            icon: const Icon(Icons.psychology_outlined, color: AppColors.accentTeal),
            label: const Text("اقتراح اسم ذكي", style: TextStyle(color: AppColors.accentTeal)),
          ),
        ],
      ),
      textConfirm: "تعديل",
      textCancel: "إلغاء",
      confirmTextColor: Colors.white,
      onConfirm: () {
        _teacherController.renameLesson(lesson.id, controller.text);
        setState(() {
          final index = _courseLessons.indexWhere((l) => l.id == lesson.id);
          if (index != -1) {
            _courseLessons[index] = lesson.copyWith(title: controller.text);
          }
        });
        Get.back();
      },
    );
  }

  void _showDeleteConfirmation(String name, VoidCallback onConfirm) {
    Get.defaultDialog(
      title: "تحذير صارم ⚠️",
      middleText: "تحذير: هذا الإجراء سيحذف ($name) وكافة بيانات تقدم الطلاب المرتبطة به نهائياً!",
      backgroundColor: AppColors.secondaryNavy,
      titleStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
      middleTextStyle: const TextStyle(color: Colors.white),
      textConfirm: "تأكيد الحذف النهائي",
      textCancel: "إلغاء",
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        onConfirm();
        Get.back();
      },
    );
  }

  Widget _buildCommentsTab() {
    _teacherController.fetchTeacherComments();
    return Obx(() {
      if (_teacherController.isCommentsLoading.value) {
        return const Center(child: CircularProgressIndicator(color: AppColors.accentTeal));
      }

      if (_teacherController.teacherComments.isEmpty) {
        return const Center(child: Text("لا توجد تعليقات جديدة للرد عليها", style: TextStyle(color: Colors.white54)));
      }

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _teacherController.teacherComments.length,
        itemBuilder: (context, index) {
          final comment = _teacherController.teacherComments[index];
          final String commentId = comment['id'].toString();
          
          if (!_replyControllers.containsKey(commentId)) {
            _replyControllers[commentId] = TextEditingController();
          }
          final replyController = _replyControllers[commentId]!;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.secondaryNavy,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(comment['profiles']['full_name'] ?? "طالب", style: const TextStyle(color: AppColors.accentTeal, fontWeight: FontWeight.bold)),
                    Text(comment['lessons']['title'] ?? "", style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(comment['content'] ?? "", style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 15),
                const Divider(color: Colors.white10),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: replyController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: "اكتب ردك هنا...",
                          hintStyle: TextStyle(color: Colors.white24),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.psychology_outlined, color: AppColors.accentTeal),
                      tooltip: "اقتراح رد ذكي 🧠",
                      onPressed: () async {
                        Get.dialog(const Center(child: CircularProgressIndicator(color: AppColors.accentTeal)), barrierDismissible: false);
                        try {
                          final ai = AIService();
                          final suggestion = await ai.suggestSmartReply(comment['content']);
                          Get.back();
                          replyController.text = suggestion;
                        } catch (e) {
                          Get.back();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppColors.accentTeal),
                      onPressed: () {
                        if (replyController.text.isNotEmpty) {
                          _teacherController.replyToComment(comment['id'].toString(), replyController.text);
                        }
                      },
                    ),
                  ],
                ),
                if (comment['teacher_reply'] != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                    child: Text("ردك السابق: ${comment['teacher_reply']}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ),
                ],
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: AppColors.secondaryNavy,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          ),
        ),
      ],
    );
  }
}

class DashStyle {
  final List<double> array;
  const DashStyle({required this.array});
}
