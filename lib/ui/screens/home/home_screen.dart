import 'package:flutter/material.dart';
import 'package:health_tracker/data/models/article_model.dart';
import 'package:health_tracker/data/models/recipe_model.dart';
import 'package:health_tracker/data/repositories/article_api.dart';
import 'package:health_tracker/shared/styles/animations.dart';
import 'package:health_tracker/shared/widgets/scale_tap.dart';
import 'package:health_tracker/shared/widgets/particle_background.dart';
import 'package:health_tracker/shared/widgets/glassmorphic_card.dart';
import 'package:health_tracker/ui/screens/articles/article_list_screen.dart';
import 'package:health_tracker/ui/screens/quiz/health_assessment_screen.dart';
import 'package:health_tracker/ui/screens/recipes/recipe_detail_new_screen.dart';
import 'package:health_tracker/ui/screens/together/meditation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  List<Map<String, dynamic>> _articles = [];
  List<Map<String, dynamic>> _healthTips = [];
  List<Map<String, dynamic>> _recipes = [];
  List<Recipe> _recipeModels = [];
  final List<Recipe> _allRecipes = [
    Recipe(
      id: 1,
      title: 'Salad bơ cá hồi tốt cho tim mạch',
      author: 'Health Kitchen',
      description: 'Món salad tươi mát với bơ và cá hồi giàu omega-3, vị thanh nhẹ, béo nhẹ từ bơ, tươi mát, ít dầu mỡ.',
      cookingTime: 20,
      servings: 2,
      imageUrl: 'assets/images/ui/5037007.jpg',
      ingredients: ['2 quả trứng', '1 quả bơ', '100g cá hồi', '50g rau xanh', '1 muỗng dầu olive'],
      preparation: [
        {'steps': [
          {'step': 'Rửa sạch rau và sơ chế nguyên liệu'},
          {'step': 'Áp chảo cá hồi trong 5 phút với lửa vừa'},
          {'step': 'Cắt bơ thành miếng nhỏ vừa ăn'},
          {'step': 'Trộn salad với dầu olive và gia vị'},
        ]},
      ],
    ),
    Recipe(
      id: 2,
      title: 'Yến mạch trái cây cho bữa sáng',
      author: 'Nutrition Pro',
      description: 'Bữa sáng giàu chất xơ và vitamin từ yến mạch kết hợp trái cây tươi, ngọt tự nhiên, tốt cho tiêu hóa.',
      cookingTime: 15,
      servings: 1,
      imageUrl: 'assets/images/ui/2.jpg',
      ingredients: ['50g yến mạch', '1 quả chuối', '100ml sữa hạnh nhân', '1 muỗng mật ong', 'Dâu tây'],
      preparation: [
        {'steps': [
          {'step': 'Ngâm yến mạch trong sữa 10 phút'},
          {'step': 'Cắt chuối và dâu tây thành lát mỏng'},
          {'step': 'Trộn yến mạch với trái cây và mật ong'},
        ]},
      ],
    ),
    Recipe(
      id: 3,
      title: 'Bột yến mạch trái cây',
      author: 'Healthy Life',
      description: 'Bột yến mạch ấm nóng kết hợp cùng trái cây tươi và các loại hạt, giàu năng lượng cho ngày mới.',
      cookingTime: 10,
      servings: 2,
      imageUrl: 'assets/images/ui/5037007.jpg',
      ingredients: ['100g bột yến mạch', '200ml sữa tươi', '1 quả táo', '20g hạt óc chó', '1 muỗng siro phong'],
      preparation: [
        {'steps': [
          {'step': 'Nấu bột yến mạch với sữa ở lửa nhỏ trong 5 phút'},
          {'step': 'Cắt táo thành hạt lựu'},
          {'step': 'Rắc hạt óc chó và táo lên bột yến mạch'},
          {'step': 'Rưới siro phong và thưởng thức'},
        ]},
      ],
    ),
    Recipe(
      id: 4,
      title: 'Súp gà nấm bổ dưỡng',
      author: 'Home Chef',
      description: 'Súp gà nấm thơm ngon, bổ dưỡng với thịt gà mềm và nấm tươi, thích hợp cho bữa tối nhẹ nhàng.',
      cookingTime: 35,
      servings: 4,
      imageUrl: 'assets/images/ui/2.jpg',
      ingredients: ['200g thịt gà', '100g nấm hương', '1 củ cà rốt', '1 lít nước dùng', 'Hành lá', 'Gia vị'],
      preparation: [
        {'steps': [
          {'step': 'Luộc gà chín, xé nhỏ thịt'},
          {'step': 'Nấm ngâm mềm, cà rốt cắt hạt lựu'},
          {'step': 'Phi thơm hành, cho nấm và cà rốt vào xào'},
          {'step': 'Thêm nước dùng, thịt gà, nấu 20 phút'},
        ]},
      ],
    ),
    Recipe(
      id: 5,
      title: 'Sinh tố xanh tăng năng lượng',
      author: 'Green Kitchen',
      description: 'Sinh tố xanh giàu vitamin và khoáng chất từ rau xanh và trái cây, giúp tăng cường năng lượng tức thì.',
      cookingTime: 5,
      servings: 1,
      imageUrl: 'assets/images/ui/5037007.jpg',
      ingredients: ['1 quả chuối', '1 nắm rau bina', '100ml sữa dừa', '1 muỗng hạt chia', '1/2 quả táo xanh'],
      preparation: [
        {'steps': [
          {'step': 'Rửa sạch rau bina và táo'},
          {'step': 'Cho tất cả nguyên liệu vào máy xay'},
          {'step': 'Xay nhuyễn trong 30 giây'},
          {'step': 'Rót ra ly và thưởng thức ngay'},
        ]},
      ],
    ),
  ];

  final List<String> tabs = ['TẤT CẢ', 'Ngủ ngon hơn', 'Kiểm tra', 'Bài Viết', 'Công Thức Món Ăn'];

  final List<Map<String, dynamic>> _categoryMetas = [
    {'title': 'Tim mạch', 'image': 'assets/images/ui/5 (1).png', 'category': 'tim_mach'},
    {'title': 'Giấc ngủ', 'image': 'assets/images/ui/5 (2).png', 'category': 'giac_ngu'},
    {'title': 'Dinh dưỡng', 'image': 'assets/images/ui/5 (3).png', 'category': 'dinh_duong'},
    {'title': 'Nước', 'image': 'assets/images/ui/5 (4).png', 'category': 'nuoc'},
    {'title': 'Calo', 'image': 'assets/images/ui/5 (5).png', 'category': 'calo'},
    {'title': 'Tập luyện', 'image': 'assets/images/ui/5 (6).png', 'category': 'tap_luyen'},
    {'title': 'Căng thẳng', 'image': 'assets/images/ui/5 (7).png', 'category': 'cang_thang'},
  ];
  final List<Map<String, dynamic>> healthTipData = [
    {'title': 'Sức khỏe tim mạch', 'content': 'Tập thể dục 30 phút mỗi ngày, ăn nhiều rau xanh và cá béo, hạn chế muối để bảo vệ trái tim của bạn.', 'image': 'assets/images/ui/5037007.jpg'},
    {'title': 'Giảm căng thẳng', 'content': 'Thiền 10 phút mỗi sáng, hít thở sâu, viết nhật ký và dành thời gian cho sở thích cá nhân.', 'image': 'assets/images/ui/5037007.jpg'},
    {'title': 'Giảm lo âu', 'content': 'Tập yoga, nghe nhạc thư giãn, hạn chế caffeine và chia sẻ cảm xúc với người thân.', 'image': 'assets/images/ui/5037007.jpg'},
    {'title': 'Điều trị trầm cảm', 'content': 'Duy trì kết nối xã hội, tập thể dục đều đặn, ngủ đủ giấc và tìm kiếm sự hỗ trợ từ chuyên gia tâm lý.', 'image': 'assets/images/ui/5037007.jpg'},
  ];

  static final List<AssessmentCategory> _assessmentCategories = [
    // GAD-7: Generalized Anxiety Disorder (lo âu)
    AssessmentCategory(
      name: 'Lo âu (GAD-7)',
      icon: Icons.psychology_outlined,
      color: Color(0xFF7B1FA2),
      description: 'Đánh giá mức độ lo âu dựa trên thang đo GAD-7 (Generalized Anxiety Disorder-7) - công cụ sàng lọc lo âu phổ biến trên toàn thế giới.',
      purpose: 'Trong 2 tuần qua, bạn có bao nhiêu lần gặp phải các vấn đề sau?',
      estimatedMinutes: 3,
      imageAsset: 'assets/images/ui/7 (1).png',
      suggestionTitle: 'Kiểm soát lo âu',
      suggestionBody: 'Thực hành thở sâu 4-7-8, thiền mindfulness 10 phút/ngày, tập thể dục đều đặn, hạn chế caffeine và rượu bia. Nếu điểm số cao, hãy tham khảo ý kiến chuyên gia tâm lý.',
      questions: [
        AssessmentQuestion(
          question: 'Cảm thấy lo lắng, căng thẳng hoặc quá lo âu?',
          options: [
            AssessmentOption(text: 'Hoàn toàn không', score: 3),
            AssessmentOption(text: 'Vài ngày', score: 2),
            AssessmentOption(text: 'Hơn nửa số ngày', score: 1),
            AssessmentOption(text: 'Hầu như mỗi ngày', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Không thể ngừng lo lắng hoặc không kiểm soát được sự lo lắng?',
          options: [
            AssessmentOption(text: 'Hoàn toàn không', score: 3),
            AssessmentOption(text: 'Vài ngày', score: 2),
            AssessmentOption(text: 'Hơn nửa số ngày', score: 1),
            AssessmentOption(text: 'Hầu như mỗi ngày', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Lo lắng quá nhiều về những điều khác nhau?',
          options: [
            AssessmentOption(text: 'Hoàn toàn không', score: 3),
            AssessmentOption(text: 'Vài ngày', score: 2),
            AssessmentOption(text: 'Hơn nửa số ngày', score: 1),
            AssessmentOption(text: 'Hầu như mỗi ngày', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Khó thư giãn?',
          options: [
            AssessmentOption(text: 'Hoàn toàn không', score: 3),
            AssessmentOption(text: 'Vài ngày', score: 2),
            AssessmentOption(text: 'Hơn nửa số ngày', score: 1),
            AssessmentOption(text: 'Hầu như mỗi ngày', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Bồn chồn đến mức khó ngồi yên?',
          options: [
            AssessmentOption(text: 'Hoàn toàn không', score: 3),
            AssessmentOption(text: 'Vài ngày', score: 2),
            AssessmentOption(text: 'Hơn nửa số ngày', score: 1),
            AssessmentOption(text: 'Hầu như mỗi ngày', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Dễ cáu kỉnh hoặc khó chịu?',
          options: [
            AssessmentOption(text: 'Hoàn toàn không', score: 3),
            AssessmentOption(text: 'Vài ngày', score: 2),
            AssessmentOption(text: 'Hơn nửa số ngày', score: 1),
            AssessmentOption(text: 'Hầu như mỗi ngày', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Cảm thấy sợ hãi như thể điều khủng khiếp sắp xảy ra?',
          options: [
            AssessmentOption(text: 'Hoàn toàn không', score: 3),
            AssessmentOption(text: 'Vài ngày', score: 2),
            AssessmentOption(text: 'Hơn nửa số ngày', score: 1),
            AssessmentOption(text: 'Hầu như mỗi ngày', score: 0),
          ],
        ),
      ],
    ),
    // PHQ-9: Patient Health Questionnaire (trầm cảm)
    AssessmentCategory(
      name: 'Trầm cảm (PHQ-9)',
      icon: Icons.cloud_outlined,
      color: Color(0xFF1E88E5),
      description: 'Đánh giá mức độ trầm cảm dựa trên thang đo PHQ-9 (Patient Health Questionnaire-9) - công cụ chuẩn quốc tế để sàng lọc trầm cảm.',
      purpose: 'Trong 2 tuần qua, bạn có bao nhiêu lần gặp phải các vấn đề sau?',
      estimatedMinutes: 4,
      imageAsset: 'assets/images/ui/7 (2).png',
      suggestionTitle: 'Cải thiện tâm trạng',
      suggestionBody: 'Duy trì kết nối xã hội, tập thể dục 30 phút/ngày, thiết lập thói quen ngủ lành mạnh. Ghi lại 3 điều tốt đẹp mỗi ngày. Nếu điểm số cao, hãy tìm kiếm sự hỗ trợ từ chuyên gia tâm lý.',
      questions: [
        AssessmentQuestion(
          question: 'Ít hứng thú hoặc niềm vui khi làm mọi việc?',
          options: [
            AssessmentOption(text: 'Hoàn toàn không', score: 3),
            AssessmentOption(text: 'Vài ngày', score: 2),
            AssessmentOption(text: 'Hơn nửa số ngày', score: 1),
            AssessmentOption(text: 'Hầu như mỗi ngày', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Cảm thấy buồn bã, chán nản hoặc tuyệt vọng?',
          options: [
            AssessmentOption(text: 'Hoàn toàn không', score: 3),
            AssessmentOption(text: 'Vài ngày', score: 2),
            AssessmentOption(text: 'Hơn nửa số ngày', score: 1),
            AssessmentOption(text: 'Hầu như mỗi ngày', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Khó đi vào giấc ngủ, hay thức giấc hoặc ngủ quá nhiều?',
          options: [
            AssessmentOption(text: 'Hoàn toàn không', score: 3),
            AssessmentOption(text: 'Vài ngày', score: 2),
            AssessmentOption(text: 'Hơn nửa số ngày', score: 1),
            AssessmentOption(text: 'Hầu như mỗi ngày', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Cảm thấy mệt mỏi hoặc thiếu năng lượng?',
          options: [
            AssessmentOption(text: 'Hoàn toàn không', score: 3),
            AssessmentOption(text: 'Vài ngày', score: 2),
            AssessmentOption(text: 'Hơn nửa số ngày', score: 1),
            AssessmentOption(text: 'Hầu như mỗi ngày', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Chán ăn hoặc ăn quá nhiều?',
          options: [
            AssessmentOption(text: 'Hoàn toàn không', score: 3),
            AssessmentOption(text: 'Vài ngày', score: 2),
            AssessmentOption(text: 'Hơn nửa số ngày', score: 1),
            AssessmentOption(text: 'Hầu như mỗi ngày', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Cảm thấy tồi tệ về bản thân, nghĩ rằng mình đã thất bại?',
          options: [
            AssessmentOption(text: 'Hoàn toàn không', score: 3),
            AssessmentOption(text: 'Vài ngày', score: 2),
            AssessmentOption(text: 'Hơn nửa số ngày', score: 1),
            AssessmentOption(text: 'Hầu như mỗi ngày', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Khó tập trung vào mọi việc (đọc báo, xem TV)?',
          options: [
            AssessmentOption(text: 'Hoàn toàn không', score: 3),
            AssessmentOption(text: 'Vài ngày', score: 2),
            AssessmentOption(text: 'Hơn nửa số ngày', score: 1),
            AssessmentOption(text: 'Hầu như mỗi ngày', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Di chuyển hoặc nói chậm hơn bình thường, hoặc ngược lại bồn chồn?',
          options: [
            AssessmentOption(text: 'Hoàn toàn không', score: 3),
            AssessmentOption(text: 'Vài ngày', score: 2),
            AssessmentOption(text: 'Hơn nửa số ngày', score: 1),
            AssessmentOption(text: 'Hầu như mỗi ngày', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Có ý nghĩ tự làm hại bản thân hoặc nghĩ rằng mình nên chết?',
          options: [
            AssessmentOption(text: 'Hoàn toàn không', score: 3),
            AssessmentOption(text: 'Vài ngày', score: 2),
            AssessmentOption(text: 'Hơn nửa số ngày', score: 1),
            AssessmentOption(text: 'Hầu như mỗi ngày', score: 0),
          ],
        ),
      ],
    ),
    // PSS: Perceived Stress Scale (căng thẳng)
    AssessmentCategory(
      name: 'Căng thẳng (PSS)',
      icon: Icons.bolt_outlined,
      color: Color(0xFFFFAA44),
      description: 'Đánh giá mức độ căng thẳng nhận thức dựa trên thang đo PSS (Perceived Stress Scale) - công cụ đo lường căng thẳng tâm lý được sử dụng rộng rãi.',
      purpose: 'Trong tháng qua, bạn có bao nhiêu lần gặp phải các tình huống sau?',
      estimatedMinutes: 5,
      imageAsset: 'assets/images/ui/7 (3).png',
      suggestionTitle: 'Quản lý căng thẳng',
      suggestionBody: 'Tập thở sâu 5 phút mỗi sáng, yoga hoặc thiền, dành thời gian cho sở thích, ngủ đủ giấc, học cách nói "không" khi quá tải. Hạn chế caffeine và rượu bia.',
      questions: [
        AssessmentQuestion(
          question: 'Bạn thấy bối rối vì những điều xảy ra bất ngờ?',
          options: [
            AssessmentOption(text: 'Không bao giờ', score: 4),
            AssessmentOption(text: 'Hiếm khi', score: 3),
            AssessmentOption(text: 'Thỉnh thoảng', score: 2),
            AssessmentOption(text: 'Khá thường xuyên', score: 1),
            AssessmentOption(text: 'Rất thường xuyên', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Bạn thấy không thể kiểm soát được những điều quan trọng trong cuộc sống?',
          options: [
            AssessmentOption(text: 'Không bao giờ', score: 4),
            AssessmentOption(text: 'Hiếm khi', score: 3),
            AssessmentOption(text: 'Thỉnh thoảng', score: 2),
            AssessmentOption(text: 'Khá thường xuyên', score: 1),
            AssessmentOption(text: 'Rất thường xuyên', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Bạn cảm thấy lo lắng và căng thẳng?',
          options: [
            AssessmentOption(text: 'Không bao giờ', score: 4),
            AssessmentOption(text: 'Hiếm khi', score: 3),
            AssessmentOption(text: 'Thỉnh thoảng', score: 2),
            AssessmentOption(text: 'Khá thường xuyên', score: 1),
            AssessmentOption(text: 'Rất thường xuyên', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Bạn cảm thấy thiếu tự tin khi giải quyết vấn đề?',
          options: [
            AssessmentOption(text: 'Không bao giờ', score: 4),
            AssessmentOption(text: 'Hiếm khi', score: 3),
            AssessmentOption(text: 'Thỉnh thoảng', score: 2),
            AssessmentOption(text: 'Khá thường xuyên', score: 1),
            AssessmentOption(text: 'Rất thường xuyên', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Bạn thấy mọi việc không diễn ra như ý muốn?',
          options: [
            AssessmentOption(text: 'Không bao giờ', score: 4),
            AssessmentOption(text: 'Hiếm khi', score: 3),
            AssessmentOption(text: 'Thỉnh thoảng', score: 2),
            AssessmentOption(text: 'Khá thường xuyên', score: 1),
            AssessmentOption(text: 'Rất thường xuyên', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Bạn thấy không thể làm hết mọi việc cần làm?',
          options: [
            AssessmentOption(text: 'Không bao giờ', score: 4),
            AssessmentOption(text: 'Hiếm khi', score: 3),
            AssessmentOption(text: 'Thỉnh thoảng', score: 2),
            AssessmentOption(text: 'Khá thường xuyên', score: 1),
            AssessmentOption(text: 'Rất thường xuyên', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Bạn khó kiểm soát sự cáu kỉnh của mình?',
          options: [
            AssessmentOption(text: 'Không bao giờ', score: 4),
            AssessmentOption(text: 'Hiếm khi', score: 3),
            AssessmentOption(text: 'Thỉnh thoảng', score: 2),
            AssessmentOption(text: 'Khá thường xuyên', score: 1),
            AssessmentOption(text: 'Rất thường xuyên', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Bạn cảm thấy mất kiểm soát cuộc sống của mình?',
          options: [
            AssessmentOption(text: 'Không bao giờ', score: 4),
            AssessmentOption(text: 'Hiếm khi', score: 3),
            AssessmentOption(text: 'Thỉnh thoảng', score: 2),
            AssessmentOption(text: 'Khá thường xuyên', score: 1),
            AssessmentOption(text: 'Rất thường xuyên', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Bạn tức giận vì những điều nằm ngoài tầm kiểm soát?',
          options: [
            AssessmentOption(text: 'Không bao giờ', score: 4),
            AssessmentOption(text: 'Hiếm khi', score: 3),
            AssessmentOption(text: 'Thỉnh thoảng', score: 2),
            AssessmentOption(text: 'Khá thường xuyên', score: 1),
            AssessmentOption(text: 'Rất thường xuyên', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Bạn thấy khó khăn dồn dập đến mức không thể vượt qua?',
          options: [
            AssessmentOption(text: 'Không bao giờ', score: 4),
            AssessmentOption(text: 'Hiếm khi', score: 3),
            AssessmentOption(text: 'Thỉnh thoảng', score: 2),
            AssessmentOption(text: 'Khá thường xuyên', score: 1),
            AssessmentOption(text: 'Rất thường xuyên', score: 0),
          ],
        ),
      ],
    ),
    // WHO-5: World Health Organization Five Well-Being Index (tinh thần)
    AssessmentCategory(
      name: 'Tinh thần (WHO-5)',
      icon: Icons.self_improvement_rounded,
      color: Color(0xFF36B78B),
      description: 'Đánh giá sức khỏe tinh thần tích cực dựa trên thang đo WHO-5 (Well-Being Index) của Tổ chức Y tế Thế giới.',
      purpose: 'Trong 2 tuần qua, có bao nhiêu thời gian bạn cảm thấy như sau?',
      estimatedMinutes: 2,
      imageAsset: 'assets/images/ui/7 (4).png',
      suggestionTitle: 'Nâng cao tinh thần',
      suggestionBody: 'Dành thời gian cho sở thích, tập thể dục ngoài trời, thực hành lòng biết ơn, kết nối với bạn bè. Nếu điểm dưới 50%, hãy cân nhắc trao đổi với chuyên gia sức khỏe tâm thần.',
      questions: [
        AssessmentQuestion(
          question: 'Tôi cảm thấy vui vẻ và tinh thần thoải mái',
          options: [
            AssessmentOption(text: 'Luôn luôn', score: 5),
            AssessmentOption(text: 'Hầu hết thời gian', score: 4),
            AssessmentOption(text: 'Hơn một nửa thời gian', score: 3),
            AssessmentOption(text: 'Chưa đến một nửa thời gian', score: 2),
            AssessmentOption(text: 'Thỉnh thoảng', score: 1),
            AssessmentOption(text: 'Chưa bao giờ', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Tôi cảm thấy bình tĩnh và thư giãn',
          options: [
            AssessmentOption(text: 'Luôn luôn', score: 5),
            AssessmentOption(text: 'Hầu hết thời gian', score: 4),
            AssessmentOption(text: 'Hơn một nửa thời gian', score: 3),
            AssessmentOption(text: 'Chưa đến một nửa thời gian', score: 2),
            AssessmentOption(text: 'Thỉnh thoảng', score: 1),
            AssessmentOption(text: 'Chưa bao giờ', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Tôi cảm thấy năng động và tràn đầy sức sống',
          options: [
            AssessmentOption(text: 'Luôn luôn', score: 5),
            AssessmentOption(text: 'Hầu hết thời gian', score: 4),
            AssessmentOption(text: 'Hơn một nửa thời gian', score: 3),
            AssessmentOption(text: 'Chưa đến một nửa thời gian', score: 2),
            AssessmentOption(text: 'Thỉnh thoảng', score: 1),
            AssessmentOption(text: 'Chưa bao giờ', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Tôi thức dậy với cảm giác sảng khoái và nghỉ ngơi tốt',
          options: [
            AssessmentOption(text: 'Luôn luôn', score: 5),
            AssessmentOption(text: 'Hầu hết thời gian', score: 4),
            AssessmentOption(text: 'Hơn một nửa thời gian', score: 3),
            AssessmentOption(text: 'Chưa đến một nửa thời gian', score: 2),
            AssessmentOption(text: 'Thỉnh thoảng', score: 1),
            AssessmentOption(text: 'Chưa bao giờ', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Cuộc sống hàng ngày của tôi có nhiều điều thú vị',
          options: [
            AssessmentOption(text: 'Luôn luôn', score: 5),
            AssessmentOption(text: 'Hầu hết thời gian', score: 4),
            AssessmentOption(text: 'Hơn một nửa thời gian', score: 3),
            AssessmentOption(text: 'Chưa đến một nửa thời gian', score: 2),
            AssessmentOption(text: 'Thỉnh thoảng', score: 1),
            AssessmentOption(text: 'Chưa bao giờ', score: 0),
          ],
        ),
      ],
    ),
    // PSQI: Pittsburgh Sleep Quality Index (giấc ngủ)
    AssessmentCategory(
      name: 'Giấc ngủ (PSQI)',
      icon: Icons.nightlight_round,
      color: Color(0xFF6658DA),
      description: 'Đánh giá chất lượng giấc ngủ dựa trên thang đo PSQI (Pittsburgh Sleep Quality Index) - công cụ chuẩn quốc tế về đánh giá giấc ngủ.',
      purpose: 'Trong tháng qua, hãy đánh giá các khía cạnh sau về giấc ngủ của bạn.',
      estimatedMinutes: 3,
      imageAsset: 'assets/images/ui/7 (5).png',
      suggestionTitle: 'Cải thiện chất lượng giấc ngủ',
      suggestionBody: 'Duy trì giờ ngủ cố định, tắt thiết bị điện tử 1 giờ trước khi ngủ, không dùng caffeine sau 14h, tạo không gian ngủ tối và yên tĩnh. Nếu điểm cao, hãy tham khảo bác sĩ về giấc ngủ.',
      questions: [
        AssessmentQuestion(
          question: 'Chất lượng giấc ngủ của bạn trong tháng qua?',
          options: [
            AssessmentOption(text: 'Rất tốt', score: 3),
            AssessmentOption(text: 'Khá tốt', score: 2),
            AssessmentOption(text: 'Khá tệ', score: 1),
            AssessmentOption(text: 'Rất tệ', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Bạn thường mất bao lâu để đi vào giấc ngủ?',
          options: [
            AssessmentOption(text: '≤ 15 phút', score: 3),
            AssessmentOption(text: '16-30 phút', score: 2),
            AssessmentOption(text: '31-60 phút', score: 1),
            AssessmentOption(text: '> 60 phút', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Bạn ngủ trung bình bao nhiêu tiếng mỗi đêm?',
          options: [
            AssessmentOption(text: '> 7 tiếng', score: 3),
            AssessmentOption(text: '6-7 tiếng', score: 2),
            AssessmentOption(text: '5-6 tiếng', score: 1),
            AssessmentOption(text: '< 5 tiếng', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Bạn có gặp rối loạn giấc ngủ (tỉnh giấc giữa đêm, ngáy, khó thở)?',
          options: [
            AssessmentOption(text: 'Không gặp', score: 3),
            AssessmentOption(text: 'Hiếm khi (1-2 lần/tháng)', score: 2),
            AssessmentOption(text: 'Thỉnh thoảng (1-2 lần/tuần)', score: 1),
            AssessmentOption(text: 'Thường xuyên (≥ 3 lần/tuần)', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Bạn có dùng thuốc hỗ trợ giấc ngủ (kê đơn hoặc tự mua)?',
          options: [
            AssessmentOption(text: 'Không dùng', score: 3),
            AssessmentOption(text: 'Ít hơn 1 lần/tuần', score: 2),
            AssessmentOption(text: '1-2 lần/tuần', score: 1),
            AssessmentOption(text: '≥ 3 lần/tuần', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Bạn có cảm thấy buồn ngủ khi lái xe, ăn uống hoặc làm việc?',
          options: [
            AssessmentOption(text: 'Không buồn ngủ', score: 3),
            AssessmentOption(text: 'Hiếm khi (1-2 lần/tháng)', score: 2),
            AssessmentOption(text: 'Thỉnh thoảng (1-2 lần/tuần)', score: 1),
            AssessmentOption(text: 'Thường xuyên (≥ 3 lần/tuần)', score: 0),
          ],
        ),
        AssessmentQuestion(
          question: 'Bạn có thiếu năng lượng/nhiệt tình để làm mọi việc?',
          options: [
            AssessmentOption(text: 'Không thiếu', score: 3),
            AssessmentOption(text: 'Hiếm khi', score: 2),
            AssessmentOption(text: 'Thỉnh thoảng', score: 1),
            AssessmentOption(text: 'Thường xuyên', score: 0),
          ],
        ),
      ],
    ),
  ];

  final List<GlobalKey> _tabKeys = [];

  @override
  void initState() {
    super.initState();
    _tabKeys.addAll(List.generate(tabs.length, (_) => GlobalKey()));
    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTabIndex = _tabController.index);
        _scrollToTab(_tabController.index);
      }
    });
    _healthTips = List.from(healthTipData);
    _loadArticleCounts();
    _initRecipes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToTab(0);
    });
  }

  void _scrollToTab(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (index < _tabKeys.length) {
        final context = _tabKeys[index].currentContext;
        if (context != null && context.mounted) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.5,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  Future<void> _loadArticleCounts() async {
    final api = ArticleApiService();
    final mockAll = await api.getAllArticles();

    void updateCounts(List<Article> articles) {
      final Map<String, int> countByCategory = {};
      for (final a in articles) {
        countByCategory[a.category] = (countByCategory[a.category] ?? 0) + 1;
      }
      final List<Map<String, dynamic>> articleList = [];
      for (final meta in _categoryMetas) {
        final cat = meta['category'] as String;
        final count = countByCategory[cat] ?? 0;
        articleList.add({
          'id': articleList.length + 1,
          'title': meta['title'],
          'description': '$count Thông tin chi tiết',
          'image': meta['image'],
          'category': cat,
        });
      }
      setState(() {
        _articles = articleList;
      });
    }

    updateCounts(mockAll);

    final results = await Future.wait(
      api.categories.map((cat) => api.getArticlesByCategory(cat)),
    );
    final allWithApi = <Article>[];
    for (final list in results) {
      allWithApi.addAll(list);
    }
    if (mounted) updateCounts(allWithApi);
  }

  void _initRecipes() {
    _recipeModels = List<Recipe>.from(_allRecipes);
    const caloriesMap = {1: 320, 2: 280, 3: 417, 4: 250, 5: 180};
    const localImages = [
      'assets/images/hh/images.jpeg',
      'assets/images/hh/tải xuống.webp',
      'assets/images/hh/tải xuống (1).webp',
      'assets/images/hh/tải xuống (2).webp',
      'assets/images/hh/tải xuống (3).webp',
    ];
    _recipes = _recipeModels.asMap().entries.map((e) {
      final r = e.value;
      return {
        'id': r.id,
        'title': r.title,
        'time': '${r.cookingTime} Min',
        'calories': '${caloriesMap[r.id] ?? 0} Kcal',
        'image': e.key < localImages.length ? localImages[e.key] : r.imageUrl,
      };
    }).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Recipes - loaded from API

  // Sleep tips - NGỦ NGON HƠN
  final List<Map<String, dynamic>> sleepTips = [
    {
      'id': 1,
      'title': 'Nhạc thiền sáng',
      'image': 'assets/images/meditation/1.jpg',
      'trackKey': 'morning',
      'theme': 'sleep',
    },
    {
      'id': 2,
      'title': 'Âm thanh mưa',
      'image': 'assets/images/meditation/2.jpg',
      'trackKey': 'heaven_water',
      'theme': 'water',
    },
    {
      'id': 3,
      'title': 'Dreamer',
      'image': 'assets/images/meditation/3.jpg',
      'trackKey': 'dreamer',
      'theme': 'space',
    },
    {
      'id': 4,
      'title': 'Thiền tĩnh tâm',
      'image': 'assets/images/meditation/4.jpg',
      'trackKey': 'om_chanting',
      'theme': 'meditation',
    },
    {
      'id': 5,
      'title': 'Ngủ sâu',
      'image': 'assets/images/meditation/5.jpg',
      'trackKey': 'deep_sleep',
      'theme': 'sleep',
    },
    {
      'id': 6,
      'title': 'Rừng yên bình',
      'image': 'assets/images/meditation/6.jpg',
      'trackKey': 'peaceful',
      'theme': 'nature',
    },
  ];

  // Health checks - KIỂM TRA
  final List<Map<String, dynamic>> healthChecks = [
    {
      'id': 1,
      'title': 'Sóng biển',
      'image': 'assets/images/ui/5037007.jpg',
      'trackKey': 'endless_sea',
      'theme': 'water',
    },
    {
      'id': 2,
      'title': 'Tiếng chim hót',
      'image': 'assets/images/ui/2.jpg',
      'trackKey': 'morning',
      'theme': 'nature',
    },
    {
      'id': 3,
      'title': 'Suối chảy',
      'image': 'assets/images/ui/5037007.jpg',
      'trackKey': 'heaven_water',
      'theme': 'water',
    },
  ];

  final List<Map<String, dynamic>> _healthCheckData = [
    {
      'id': 0,
      'title': 'Lo âu (GAD-7)',
      'image': 'assets/images/ui/7 (1).png',
      'description': 'Đánh giá mức độ lo âu',
    },
    {
      'id': 1,
      'title': 'Trầm cảm (PHQ-9)',
      'image': 'assets/images/ui/7 (2).png',
      'description': 'Đánh giá trầm cảm',
    },
    {
      'id': 2,
      'title': 'Căng thẳng (PSS)',
      'image': 'assets/images/ui/7 (3).png',
      'description': 'Đo lường căng thẳng',
    },
    {
      'id': 3,
      'title': 'Tinh thần (WHO-5)',
      'image': 'assets/images/ui/7 (4).png',
      'description': 'Sức khỏe tinh thần',
    },
    {
      'id': 4,
      'title': 'Giấc ngủ (PSQI)',
      'image': 'assets/images/ui/7 (5).png',
      'description': 'Chất lượng giấc ngủ',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Color(0xFF0F0F0F) : Color(0xFFFAFAFA);
    final textColor = isDark ? Colors.white : Colors.black87;
    final screenWidth = MediaQuery.of(context).size.width;
    final articleCardWidth = screenWidth * 0.7;
    final articleCardHeight = 140.0;// Adjusted height for better aspect ratio

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: ParticleBackground(
        particleCount: 15,
        particleColor: Color(0xFF2DBB7A),
        maxParticleSize: 3,
        child: RefreshIndicator(
        color: const Color(0xFF2DBB7A),
        backgroundColor: bgColor,
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
         child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Tab Bar - Scrollable Pill Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: List.generate(
                      tabs.length,
                      (index) {
                        final isSelected = _selectedTabIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 18),
                          child: GestureDetector(
                            onTap: () => _tabController.animateTo(index),
                            child: Container(
                              key: _tabKeys[index],
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF2DBB7A)
                                    : (isDark
                                        ? Colors.grey.shade800.withOpacity(0.6)
                                        : Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              child: Text(
                                tabs[index],
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      isSelected ? FontWeight.w800 : FontWeight.w400,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
        
              const SizedBox(height: 16),

              if (_selectedTabIndex == 0) ...[
                // TẤT CẢ TAB
                // Featured Articles - Flex Horizontal
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bài viết',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _tabController.animateTo(3);
                        },
                        child: Text(
                          'Xem thêm',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2DBB7A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  height: articleCardHeight,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _articles.length,
                    itemBuilder: (context, index) {
                      final article = _articles[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () {
                            _navigateToArticleDetail(article);
                          },
                          child: Container(
                            width: articleCardWidth,
                            height: articleCardHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              image: DecorationImage(
                                image: AssetImage(article['image']),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.4),
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        article['title'],
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFFFF8E7),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: article['description'].split(' ')[0] + ' ',
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFFFFF8E7),
                                              ),
                                            ),
                                            TextSpan(
                                              text: article['description'].split(' ').sublist(1).join(' '),
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white.withOpacity(0.65),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                      },
                    ),
                    ),

                const SizedBox(height: 32),

                // Health Tips Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mẹo Sức khỏe',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _healthTips.length,
                      itemBuilder: (context, index) {
                        final tip = _healthTips[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 180,
                            child: ScaleTap(
                              scale: 0.96,
                              onTap: () => _navigateToHealthTipDetail(index),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  image: DecorationImage(
                                    image: AssetImage(tip['image']),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withOpacity(0.2),
                                        Colors.transparent,
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tip['title'],
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 32),

                // Recipes Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Công thức nấu ăn',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _tabController.animateTo(tabs.indexOf('Công Thức Món Ăn'));
                        },
                        child: Text(
                          'Xem thêm',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2DBB7A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  height: 210,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = _recipes[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: SizedBox(
                          width: 170,
                          child: ScaleTap(
                            scale: 0.96,
                            onTap: () {
                              if (index < _recipeModels.length) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NewRecipeDetailScreen(
                                      recipe: _recipeModels[index],
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    height: 135,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2DBB7A).withOpacity(0.08),
                                    ),
                                    child: Image.asset(
                                      recipe['image'],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        SizedBox(
                                          height: 36,
                                          child: Text(
                                            recipe['title'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: textColor,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.schedule, size: 13, color: isDark ? Colors.white70 : Colors.black54),
                                            const SizedBox(width: 3),
                                            Text(
                                              recipe['time'],
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: isDark ? Colors.grey.shade400 : Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(width: 24),
                                            Icon(Icons.local_fire_department, size: 13, color: isDark ? Colors.white70 : Colors.black54),
                                            const SizedBox(width: 3),
                                            Text(
                                              recipe['calories'],
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: isDark ? Colors.grey.shade400 : Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Health Check Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kiểm tra sức khỏe',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _tabController.animateTo(2);
                        },
                        child: Text(
                          'Xem thêm',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2DBB7A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  height: 210,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _healthCheckData.length,
                    itemBuilder: (context, index) {
                      final item = _healthCheckData[index];
                      final cat = _assessmentCategories[item['id']];
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: SizedBox(
                          width: 170,
                          child: ScaleTap(
                            scale: 0.96,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AssessmentIntroScreen(
                                    category: cat,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    height: 135,
                                    decoration: BoxDecoration(
                                      color: cat.color.withOpacity(0.08),
                                    ),
                                    child: Image.asset(
                                      item['image'],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Title
                                Text(
                                  item['title'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                // Badges
                                Row(
                                  children: [
                                    _buildBadge(
                                      Icons.timer_outlined,
                                      '${cat.estimatedMinutes} Min',
                                      cat.color,
                                    ),
                                    const SizedBox(width: 10),
                                    _buildBadge(
                                      Icons.help_outline,
                                      '${cat.questions.length} Câu hỏi',
                                      cat.color,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // Sleep Tips Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ngủ ngon hơn',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _tabController.animateTo(1);
                        },
                        child: Text(
                          'Xem thêm',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2DBB7A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  height: 135,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: sleepTips.length,
                    itemBuilder: (context, index) {
                      final tip = sleepTips[index];
                      final bgColor = _themeBg[tip['theme']] ?? const Color(0xFFF2F2F7);
                      final overlayColor = _themeOverlay[tip['theme']] ?? const Color(0xFF1C1C1E);
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () {
                            final track = MeditationScreen.tracks.firstWhere((t) => t.key == tip['trackKey']);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => RelaxSoundPlayerScreen(track: track, mixerLibrary: MeditationMixerData.library)));
                          },
                          child: Container(
                            width: screenWidth * 0.36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  bgColor,
                                  bgColor,
                                  Color.lerp(bgColor, overlayColor, 0.18)!,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                              border: Border.all(
                                color: overlayColor.withOpacity(0.08),
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundImage: AssetImage(tip['image']),
                                    ),
                                    const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  tip['title'],
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else if (_selectedTabIndex == 1) ...[
                // NGỦ NGON HƠN TAB
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Nhạc thiền',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: sleepTips.length,
                    itemBuilder: (context, index) {
                      final tip = sleepTips[index];
                      return _buildMeditationCard(
                        tip['title'],
                        tip['image'],
                        tip['theme'],
                        () {
                          final track = MeditationScreen.tracks.firstWhere((t) => t.key == tip['trackKey']);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => RelaxSoundPlayerScreen(track: track, mixerLibrary: MeditationMixerData.library)));
                        },
                      );
                    },
                    ),
                    ),

                const SizedBox(height: 32),

                // Health checks section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Nhạc thiên nhiên',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: healthChecks.length,
                    itemBuilder: (context, index) {
                      final check = healthChecks[index];
                      return _buildMeditationCard(
                        check['title'],
                        check['image'],
                        check['theme'],
                        () {
                          final track = MeditationScreen.tracks.firstWhere((t) => t.key == check['trackKey']);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => RelaxSoundPlayerScreen(track: track, mixerLibrary: MeditationMixerData.library)));
                        },
                      );
                    },
                  ),
                ),
              ] else if (_selectedTabIndex == 2) ...[
                // KIỂM TRA TAB
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Kiểm tra sức khỏe',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: _healthCheckData.length,
                    itemBuilder: (context, index) {
                      final item = _healthCheckData[index];
                      final cat = _assessmentCategories[item['id']];
                      return ScaleTap(
                        scale: 0.96,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AssessmentIntroScreen(
                                category: cat,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: double.infinity,
                                height: 135,
                                decoration: BoxDecoration(
                                  color: cat.color.withOpacity(0.08),
                                ),
                                child: Image.asset(
                                  item['image'],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 36,
                                    child: Text(
                                      cat.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.timer_outlined, size: 12, color: isDark ? Colors.white70 : Colors.black54),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${cat.estimatedMinutes} Min',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? Colors.grey.shade400 : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(Icons.help_outline, size: 12, color: isDark ? Colors.white70 : Colors.black54),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${cat.questions.length} Câu hỏi',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? Colors.grey.shade400 : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              ] else if (_selectedTabIndex == 3) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _articles.length,
                    itemBuilder: (context, index) {
                      final article = _articles[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ScaleTap(
                          scale: 0.97,
                          onTap: () {
                            Navigator.push(
                              context,
                              FadeSlideRoute(
                                page: ArticleListScreen(
                                    category: article['category'] ?? ''),
                              ),
                            );
                          },
                          child: Container(
                            height: 180,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(article['image']),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withOpacity(0.15),
                                        Colors.transparent,
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        article['title'],
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFFFF8E7),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: article['description']
                                                      .split(' ')[0] +
                                                  ' ',
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFFFFF8E7),
                                              ),
                                            ),
                                            TextSpan(
                                              text: article['description']
                                                  .split(' ')
                                                  .sublist(1)
                                                  .join(' '),
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white
                                                    .withOpacity(0.65),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else if (_selectedTabIndex == 4) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: _recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = _recipes[index];
                      return ScaleTap(
                        scale: 0.96,
                        onTap: () {
                          if (index < _recipeModels.length) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NewRecipeDetailScreen(
                                  recipe: _recipeModels[index],
                                ),
                              ),
                            );
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: double.infinity,
                                height: 135,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2DBB7A).withOpacity(0.08),
                                ),
                                child: Image.asset(
                                  recipe['image'],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 36,
                                    child: Text(
                                      recipe['title'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.schedule, size: 13, color: isDark ? Colors.white70 : Colors.black54),
                                      const SizedBox(width: 3),
                                      Text(
                                        recipe['time'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? Colors.grey.shade400 : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Icon(Icons.local_fire_department, size: 13, color: isDark ? Colors.white70 : Colors.black54),
                                      const SizedBox(width: 3),
                                      Text(
                                        recipe['calories'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? Colors.grey.shade400 : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      ),
      floatingActionButton: GlassmorphicCard(
        borderRadius: 100,
        blur: 15,
        tint: Color(0xFFFF8C42),
        opacity: 0.3,
        child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFFFAA44), Color(0xFFFF8C42)],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFFF8C42).withOpacity(0.4),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: const SizedBox.shrink(),
      ),
      ),
    );
  }

  void _navigateToHealthTipDetail(int index) {
    Navigator.push(
      context,
      FadeSlideRoute(
        page: HealthTipDetailPage(
          tips: _healthTips,
          initialIndex: index,
        ),
      ),
    );
  }

  static const Map<String, Color> _themeBg = {
    'sleep': Color(0xFFF3EAF7),
    'nature': Color(0xFFE7EEDB),
    'meditation': Color(0xFFF7E4DA),
    'water': Color(0xFFEAF1F8),
    'calm': Color(0xFFEFE6D8),
    'space': Color(0xFFDDEAF5),
  };

  static const Map<String, Color> _themeOverlay = {
    'sleep': Color(0xFF7B1FA2),
    'nature': Color(0xFF00897B),
    'meditation': Color(0xFFE07050),
    'water': Color(0xFF1E88E5),
    'calm': Color(0xFF795548),
    'space': Color(0xFF3949AB),
  };

  Widget _buildMeditationCard(String title, String image, String theme, VoidCallback onTap) {
    final bgColor = _themeBg[theme] ?? const Color(0xFFF2F2F7);
    final overlayColor = _themeOverlay[theme] ?? const Color(0xFF1C1C1E);
    return ScaleTap(
      scale: 0.95,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              bgColor,
              bgColor,
              Color.lerp(bgColor, overlayColor, 0.18)!,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          border: Border.all(
            color: overlayColor.withOpacity(0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: overlayColor.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            const Spacer(flex: 2),
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundImage: AssetImage(image),
                ),
                Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToArticleDetail(Map<String, dynamic> article) {
    Navigator.push(
      context,
      FadeSlideRoute(
        page: ArticleListScreen(category: article['category'] ?? ''),
      ),
    );
  }
}

// Health Tip Detail Page - PageView with navigation
class HealthTipDetailPage extends StatefulWidget {
  final List<Map<String, dynamic>> tips;
  final int initialIndex;

  const HealthTipDetailPage({
    Key? key,
    required this.tips,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<HealthTipDetailPage> createState() => _HealthTipDetailPageState();
}

class _HealthTipDetailPageState extends State<HealthTipDetailPage> {
  late PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Mẹo Sức khỏe',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: widget.tips.length,
              itemBuilder: (context, index) {
                final tip = widget.tips[index];
                return Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: AssetImage(tip['image'] ?? ''),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          tip['content'] ?? '',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    if (_currentPage > 0) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _currentPage > 0
                          ? const Color(0xFF2DBB7A)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Quay lại',
                      style: TextStyle(
                        color: _currentPage > 0
                            ? Colors.white
                            : Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentPage + 1} / ${widget.tips.length}',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    if (_currentPage < widget.tips.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _currentPage < widget.tips.length - 1
                          ? const Color(0xFF2DBB7A)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Tiếp',
                      style: TextStyle(
                        color: _currentPage < widget.tips.length - 1
                            ? Colors.white
                            : Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Detail Page Widget
class DetailPage extends StatelessWidget {
  final String title;
  final String description;

  const DetailPage({
    Key? key,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Color(0xFF0F0F0F) : Color(0xFFFAFAFA);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Bài kiểm tra',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Illustration with background image
            Container(
              width: double.infinity,
              height: 320,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/ui/5037007.jpg'),
                  fit: BoxFit.cover,
                  opacity: 0.7,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF2DBB7A).withOpacity(0.2),
                      Color(0xFF4ECDC4).withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.health_and_safety,
                      size: 70,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Color(0xFF2DBB7A).withOpacity(0.15),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.help_outline,
                                size: 16, color: Color(0xFF2DBB7A)),
                            SizedBox(width: 6),
                            Text(
                              '6 Câu hỏi',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2DBB7A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Color(0xFF4ECDC4).withOpacity(0.15),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.schedule,
                                size: 16, color: Color(0xFF4ECDC4)),
                            SizedBox(width: 6),
                            Text(
                              '2 Min',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4ECDC4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Mô tả',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      height: 1.8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2DBB7A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Bắt đầu bài kiểm tra'),
                            backgroundColor: Color(0xFF2DBB7A),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Text(
                        'Bắt đầu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Quay lại',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}