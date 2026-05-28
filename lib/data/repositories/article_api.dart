import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'package:health_tracker/data/models/article_model.dart';

class ArticleApiService {
  static final ArticleApiService _instance = ArticleApiService._();
  factory ArticleApiService() => _instance;
  ArticleApiService._();

  final String _gnewsKey = 'e0e855258b8af5ab3c8da534c6e15088';
  final String _newsApiKey = '3f278c425db9496fa1701cd678dca299';

  List<Article> _allArticles = [];

  List<Article> get allArticles => _allArticles;

  List<String> get categories => [
        'tim_mach',
        'giac_ngu',
        'dinh_duong',
        'nuoc',
        'calo',
        'tap_luyen',
        'cang_thang',
      ];

  String categoryDisplayName(String category) {
    const names = {
      'tim_mach': 'Tim mạch',
      'giac_ngu': 'Giấc ngủ',
      'dinh_duong': 'Dinh dưỡng',
      'nuoc': 'Nước',
      'calo': 'Calo',
      'tap_luyen': 'Tập luyện',
      'cang_thang': 'Căng thẳng',
    };
    return names[category] ?? category;
  }

  String _categoryQuery(String category) {
    const queries = {
      'tim_mach': 'heart health cardiovascular disease',
      'giac_ngu': 'sleep health insomnia better sleep',
      'dinh_duong': 'nutrition healthy diet food',
      'nuoc': 'hydration drinking water health',
      'calo': 'calories weight loss diet',
      'tap_luyen': 'exercise fitness workout health',
      'cang_thang': 'stress management mental health',
    };
    return queries[category] ?? 'health wellness';
  }

  Future<List<Article>> getArticlesByCategory(String category) async {
    _initArticles();
    final mockResults =
        _allArticles.where((a) => a.category == category).toList();

    try {
      final apiArticles = await _fetchFromApis(category);
      if (apiArticles.isNotEmpty) {
        final existingIds = mockResults.map((a) => a.id).toSet();
        for (final apiArticle in apiArticles) {
          if (!existingIds.contains(apiArticle.id)) {
            mockResults.add(apiArticle);
          }
        }
      }
    } catch (e) {
      dev.log('ArticleAPI: API fetch failed for $category: $e');
    }

    return mockResults;
  }

  Future<Article?> getArticleById(String id) async {
    _initArticles();
    try {
      return _allArticles.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Article>> getAllArticles() async {
    _initArticles();
    return List.from(_allArticles);
  }

  void _initArticles() {
    if (_allArticles.isNotEmpty) return;
    _allArticles = _buildMockArticles();
  }

  Future<List<Article>> _fetchFromApis(String category) async {
    final query = _categoryQuery(category);
    final List<Article> results = [];

    final gnewsUri = Uri.https('gnews.io', '/api/v4/search', {
      'q': query,
      'lang': 'en',
      'country': 'us',
      'max': '5',
      'apikey': _gnewsKey,
    });

    final newsApiUri = Uri.https('newsapi.org', '/v2/everything', {
      'q': query,
      'language': 'en',
      'pageSize': '5',
      'apiKey': _newsApiKey,
    });

    try {
      final gnewsResponse = await http
          .get(gnewsUri)
          .timeout(const Duration(seconds: 10));
      if (gnewsResponse.statusCode == 200) {
        final body = json.decode(gnewsResponse.body);
        final articles = body['articles'] as List?;
        if (articles != null) {
          for (final art in articles) {
            final title = art['title'] as String? ?? '';
            if (title == '[Removed]' || title.isEmpty) continue;
            results.add(Article(
              id: 'gnews_${art['url'] ?? DateTime.now().millisecondsSinceEpoch}',
              title: title,
              content: art['description'] as String? ?? art['content'] as String? ?? '',
              imageUrl: art['image'] as String? ?? 'assets/images/ui/hh.png',
              category: category,
              author: art['source']?['name'] as String? ?? 'GNews',
              publishedAt: _safeDate(art['publishedAt'] as String?),
              tags: [category],
            ));
          }
        }
      } else {
        dev.log('ArticleAPI: GNews error ${gnewsResponse.statusCode}');
      }
    } catch (e) {
      dev.log('ArticleAPI: GNews failed: $e');
    }

    try {
      final newsApiResponse = await http
          .get(newsApiUri)
          .timeout(const Duration(seconds: 10));
      if (newsApiResponse.statusCode == 200) {
        final body = json.decode(newsApiResponse.body);
        final articles = body['articles'] as List?;
        if (articles != null) {
          for (final art in articles) {
            final title = art['title'] as String? ?? '';
            if (title == '[Removed]' || title.isEmpty) continue;
            results.add(Article(
              id: 'newsapi_${art['url'] ?? DateTime.now().millisecondsSinceEpoch}',
              title: title,
              content: art['description'] as String? ?? art['content'] as String? ?? '',
              imageUrl: art['urlToImage'] as String? ?? 'assets/images/ui/hh.png',
              category: category,
              author: art['author'] as String? ?? art['source']?['name'] as String? ?? 'NewsAPI',
              publishedAt: _safeDate(art['publishedAt'] as String?),
              tags: [category],
            ));
          }
        }
      } else {
        dev.log('ArticleAPI: NewsAPI error ${newsApiResponse.statusCode}');
      }
    } catch (e) {
      dev.log('ArticleAPI: NewsAPI failed: $e');
    }

    return results;
  }

  String _safeDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  List<Article> _buildMockArticles() {
    return [
      Article(
        id: 'tm1',
        title: 'Bí quyết bảo vệ tim mạch ở người trung niên',
        content:
            'Bệnh tim mạch là nguyên nhân gây tử vong hàng đầu trên thế giới. Tuy nhiên, bạn hoàn toàn có thể giảm nguy cơ mắc bệnh bằng những thay đổi đơn giản trong lối sống.\n\n'
            'Chế độ ăn uống lành mạnh: Hạn chế muối, đường và chất béo bão hòa. Tăng cường rau xanh, trái cây tươi, ngũ cốc nguyên hạt và các loại cá giàu omega-3 như cá hồi, cá thu.\n\n'
            'Tập thể dục đều đặn: Chỉ cần 30 phút vận động mỗi ngày, 5 ngày mỗi tuần đã đủ để cải thiện sức khỏe tim mạch. Đi bộ nhanh, bơi lội hoặc đạp xe là những lựa chọn tuyệt vời.\n\n'
            'Kiểm tra sức khỏe định kỳ: Đo huyết áp, đường huyết và mỡ máu thường xuyên để phát hiện sớm các dấu hiệu bất thường. Đừng chờ đến khi có triệu chứng mới đi khám.\n\n'
            'Quản lý căng thẳng: Stress kéo dài làm tăng huyết áp và nhịp tim. Thực hành thiền, yoga hoặc đơn giản là dành thời gian cho sở thích cá nhân mỗi ngày.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'tim_mach',
        author: 'BS. Nguyễn Văn An',
        publishedAt: '15/03/2026',
        tags: ['tim mạch', 'huyết áp', 'sức khỏe'],
      ),
      Article(
        id: 'tm2',
        title: 'Chế độ ăn DASH - Giải pháp cho tim khỏe',
        content:
            'Chế độ ăn DASH (Dietary Approaches to Stop Hypertension) được các chuyên gia tim mạch đánh giá cao nhờ khả năng kiểm soát huyết áp hiệu quả.\n\n'
            'Nguyên tắc cốt lõi: Ăn nhiều rau củ, trái cây, sữa ít béo. Hạn chế thịt đỏ, đường và chất béo bão hòa. Mỗi ngày nên tiêu thụ 4-5 phần rau và 4-5 phần trái cây.\n\n'
            'Lợi ích đã được chứng minh: Nghiên cứu cho thấy chế độ ăn DASH có thể giảm huyết áp tâm thu từ 8-14 mmHg chỉ sau 2 tuần thực hiện. Điều này tương đương với hiệu quả của một số loại thuốc huyết áp nhẹ.\n\n'
            'Thực đơn mẫu: Bữa sáng với yến mạch và quả mọng, bữa trưa salad rau với ức gà nướng, bữa tối cá hồi áp chảo cùng rau củ hấp. Bữa phụ có thể dùng sữa chua không đường hoặc các loại hạt.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'tim_mach',
        author: 'ThS. Phạm Thị Lan',
        publishedAt: '10/03/2026',
        tags: ['dinh dưỡng', 'tim mạch', 'DASH'],
      ),
      Article(
        id: 'tm3',
        title: 'Tập luyện thể thao và sức khỏe tim mạch',
        content:
            'Vận động thể chất là một trong những yếu tố quan trọng nhất để duy trì trái tim khỏe mạnh. Các bài tập tim mạch (cardio) giúp tăng cường khả năng bơm máu và cải thiện tuần hoàn.\n\n'
            'Bài tập phù hợp: Đi bộ nhanh là bài tập an toàn nhất cho mọi lứa tuổi. Chạy bộ nhẹ nhàng 3-4 buổi/tuần giúp đốt cháy calo và tăng sức bền. Bơi lội tác động đến toàn bộ cơ thể mà không gây áp lực lên khớp.\n\n'
            'Nguyên tắc an toàn: Khởi động kỹ trước khi tập, tăng cường độ từ từ. Người có bệnh tim nền cần tham khảo ý kiến bác sĩ trước khi bắt đầu bất kỳ chương trình tập luyện nào.\n\n'
            'Dấu hiệu cần dừng tập: Đau ngực, khó thở bất thường, chóng mặt hoặc buồn nôn. Nếu gặp các triệu chứng này, hãy ngừng tập ngay và đến cơ sở y tế gần nhất.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'tim_mach',
        author: 'HLV. Trần Minh Đức',
        publishedAt: '05/03/2026',
        tags: ['tập luyện', 'tim mạch', 'cardio'],
      ),
      Article(
        id: 'tm4',
        title: 'Dấu hiệu cảnh báo sớm bệnh tim bạn không nên bỏ qua',
        content:
            'Bệnh tim thường tiến triển âm thầm và nhiều người chỉ phát hiện khi đã ở giai đoạn muộn. Nhận biết sớm các dấu hiệu cảnh báo có thể cứu sống bạn.\n\n'
            'Đau tức ngực: Cảm giác nặng ngực, đau thắt hoặc khó chịu ở vùng ngực, đặc biệt khi gắng sức. Cơn đau có thể lan lên vai trái, cánh tay trái hoặc hàm dưới.\n\n'
            'Khó thở: Nếu bạn thấy hụt hơi khi làm việc nhẹ hoặc khi nằm xuống, đó có thể là dấu hiệu tim đang suy yếu. Khó thở kèm theo phù chân là triệu chứng điển hình của suy tim.\n\n'
            'Tim đập nhanh bất thường: Đánh trống ngực, tim đập nhanh không rõ nguyên nhân hoặc cảm giác tim đập lỡ nhịp. Nếu kéo dài hoặc kèm chóng mặt, bạn cần đi khám ngay.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'tim_mach',
        author: 'BS. Lê Thị Hương',
        publishedAt: '28/02/2026',
        tags: ['tim mạch', 'cảnh báo', 'triệu chứng'],
      ),
      Article(
        id: 'gn1',
        title: 'Cách cải thiện chất lượng giấc ngủ tự nhiên',
        content:
            'Giấc ngủ đóng vai trò quan trọng trong việc phục hồi năng lượng và tăng cường hệ miễn dịch. Một giấc ngủ ngon không chỉ là ngủ đủ 7-8 tiếng mà còn là ngủ sâu và không bị gián đoạn.\n\n'
            'Thiết lập thói quen: Đi ngủ và thức dậy vào cùng một giờ mỗi ngày, kể cả cuối tuần. Cơ thể sẽ quen dần với nhịp sinh học ổn định, giúp bạn dễ đi vào giấc ngủ hơn.\n\n'
            'Tạo không gian ngủ lý tưởng: Phòng tối, yên tĩnh, nhiệt độ mát mẻ (khoảng 20-22°C). Sử dụng rèm chắn sáng và máy tạo tiếng ồn trắng nếu cần thiết. Nệm và gối phải thoải mái.\n\n'
            'Tránh ánh sáng xanh: Không dùng điện thoại, máy tính bảng ít nhất 1 giờ trước khi ngủ. Ánh sáng xanh từ màn hình ức chế sản xuất melatonin - hormone điều hòa giấc ngủ.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'giac_ngu',
        author: 'ThS. Nguyễn Thị Mai',
        publishedAt: '20/03/2026',
        tags: ['giấc ngủ', 'melatonin', 'sức khỏe'],
      ),
      Article(
        id: 'gn2',
        title: 'Nhịp sinh học - Chìa khóa của giấc ngủ ngon',
        content:
            'Nhịp sinh học (circadian rhythm) là đồng hồ sinh học 24 giờ của cơ thể, điều khiển chu kỳ ngủ-thức, nhiệt độ cơ thể và hormone. Khi nhịp sinh học bị rối loạn, sức khỏe tổng thể sẽ bị ảnh hưởng.\n\n'
            'Ánh sáng mặt trời buổi sáng: Tiếp xúc với ánh sáng tự nhiên trong 15-30 phút sau khi thức dậy giúp đặt lại đồng hồ sinh học. Điều này báo hiệu cho não biết đã đến lúc tỉnh táo và hoạt động.\n\n'
            'Tránh ăn đêm: Ăn quá no hoặc uống caffeine sau 8 giờ tối làm xáo trộn nhịp sinh học. Cơ thể cần thời gian tiêu hóa, khiến bạn khó đi vào giấc ngủ sâu.\n\n'
            'Tập thể dục đúng giờ: Vận động vào buổi sáng hoặc chiều sớm giúp đồng bộ nhịp sinh học. Tập thể dục quá gần giờ ngủ có thể làm tăng cortisol, khiến bạn tỉnh táo hơn.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'giac_ngu',
        author: 'PGS.TS. Hoàng Văn Bình',
        publishedAt: '18/02/2026',
        tags: ['nhịp sinh học', 'giấc ngủ', 'đồng hồ sinh học'],
      ),
      Article(
        id: 'gn3',
        title: 'Tác hại của thiếu ngủ đối với sức khỏe',
        content:
            'Thiếu ngủ kinh niên không chỉ khiến bạn mệt mỏi mà còn gây ra hàng loạt vấn đề sức khỏe nghiêm trọng. Ngủ ít hơn 6 tiếng mỗi đêm kéo dài làm tăng nguy cơ mắc bệnh mãn tính.\n\n'
            'Ảnh hưởng đến não bộ: Thiếu ngủ làm suy giảm trí nhớ, khả năng tập trung và ra quyết định. Phản xạ chậm hơn tương đương với nồng độ cồn 0.05% trong máu.\n\n'
            'Tăng cân mất kiểm soát: Thiếu ngủ làm giảm leptin (hormone no) và tăng ghrelin (hormone đói). Bạn sẽ thèm ăn nhiều hơn, đặc biệt là đồ ngọt và tinh bột.\n\n'
            'Suy giảm miễn dịch: Khi ngủ, cơ thể sản xuất cytokine - protein chống viêm và nhiễm trùng. Thiếu ngủ làm giảm sản xuất này, khiến bạn dễ ốm hơn.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'giac_ngu',
        author: 'BS. Đặng Quốc Tuấn',
        publishedAt: '10/02/2026',
        tags: ['thiếu ngủ', 'mất ngủ', 'sức khỏe'],
      ),
      Article(
        id: 'gn4',
        title: 'Các phương pháp thư giãn giúp ngủ ngon hơn',
        content:
            'Trước khi đi ngủ, việc thư giãn tâm trí và cơ thể là bước quan trọng để có giấc ngủ chất lượng. Dưới đây là 4 phương pháp đã được khoa học chứng minh.\n\n'
            'Thiền chánh niệm: Ngồi hoặc nằm thoải mái, tập trung vào hơi thở. Khi tâm trí lang thang, nhẹ nhàng đưa nó trở lại. 10 phút thiền trước ngủ giúp giảm cortisol và làm dịu hệ thần kinh.\n\n'
            'Kỹ thuật thở 4-7-8: Hít vào trong 4 giây, giữ hơi trong 7 giây và thở ra trong 8 giây. Kỹ thuật này kích hoạt hệ thần kinh phó giao cảm, làm chậm nhịp tim và thư giãn cơ bắp.\n\n'
            'Tắm nước ấm: Nhiệt độ nước 37-38°C trong 20 phút trước ngủ. Sau khi tắm, thân nhiệt giảm nhẹ, tạo tín hiệu cho não biết đã đến giờ ngủ. Thêm vài giọt tinh dầu oải hương để tăng hiệu quả.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'giac_ngu',
        author: 'Chuyên gia Nguyễn Hải Yến',
        publishedAt: '05/02/2026',
        tags: ['thư giãn', 'thiền', 'giấc ngủ'],
      ),
      Article(
        id: 'dn1',
        title: 'Nguyên tắc vàng trong dinh dưỡng hàng ngày',
        content:
            'Dinh dưỡng hợp lý là nền tảng của sức khỏe tốt. Không cần ăn kiêng khắt khe, bạn chỉ cần tuân thủ những nguyên tắc cơ bản sau đây để có một chế độ ăn cân bằng.\n\n'
            'Đa dạng thực phẩm: Không có một loại thực phẩm nào cung cấp đầy đủ dưỡng chất. Hãy ăn nhiều loại rau củ quả với nhiều màu sắc khác nhau - mỗi màu sắc đại diện cho một nhóm chất dinh dưỡng riêng.\n\n'
            'Kiểm soát khẩu phần: Ăn đúng lượng là yếu tố then chốt. Sử dụng đĩa nhỏ hơn, ăn chậm nhai kỹ. Một bữa ăn lý tưởng nên có 1/2 rau, 1/4 protein và 1/4 tinh bột.\n\n'
            'Uống đủ nước: Nước chiếm 60% cơ thể. Uống 2 lít nước mỗi ngày giúp duy trì chuyển hóa, đào thải độc tố và giữ làn da khỏe đẹp. Hạn chế nước ngọt có ga và đồ uống có đường.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'dinh_duong',
        author: 'PGS.TS. Nguyễn Thị Lâm',
        publishedAt: '25/03/2026',
        tags: ['dinh dưỡng', 'ăn uống', 'sức khỏe'],
      ),
      Article(
        id: 'dn2',
        title: 'Thực phẩm giàu dinh dưỡng nên ăn mỗi ngày',
        content:
            'Một số thực phẩm có mật độ dinh dưỡng cao, mang lại nhiều lợi ích cho sức khỏe chỉ với một lượng nhỏ. Dưới đây là những thực phẩm vàng bạn nên bổ sung hàng ngày.\n\n'
            'Rau lá xanh đậm: Cải bó xôi, cải kale, rau ngót chứa nhiều vitamin K, A, C và folate. Chất chống oxy hóa trong rau xanh giúp bảo vệ tế bào khỏi tổn thương.\n\n'
            'Các loại hạt và quả hạch: Hạnh nhân, óc chó, hạt chia là nguồn cung cấp omega-3, chất xơ và protein thực vật. Một nắm nhỏ các loại hạt mỗi ngày giúp giảm cholesterol và tốt cho tim.\n\n'
            'Trái cây tươi: Quả mọng có hàm lượng chất chống oxy hóa cao. Chuối giàu kali giúp điều hòa huyết áp. Cam, bưởi cung cấp vitamin C tăng cường miễn dịch.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'dinh_duong',
        author: 'ThS. Bùi Thị Hạnh',
        publishedAt: '20/03/2026',
        tags: ['thực phẩm', 'siêu thực phẩm', 'dinh dưỡng'],
      ),
      Article(
        id: 'dn3',
        title: 'Vitamin và khoáng chất - Những người hùng thầm lặng',
        content:
            'Vitamin và khoáng chất tuy chỉ cần với lượng nhỏ nhưng đóng vai trò quan trọng trong mọi hoạt động sống của cơ thể. Thiếu hụt các vi chất này có thể gây ra nhiều vấn đề sức khỏe.\n\n'
            'Vitamin D: Được tổng hợp từ ánh nắng mặt trời. Giúp hấp thụ canxi, tăng cường miễn dịch. Thiếu vitamin D liên quan đến loãng xương, trầm cảm và bệnh tim. Nguồn thực phẩm: cá béo, lòng đỏ trứng.\n\n'
            'Sắt: Thành phần chính của hemoglobin, vận chuyển oxy trong máu. Thiếu sắt gây mệt mỏi, da xanh xao. Nguồn thực phẩm: thịt đỏ, gan, các loại đậu. Vitamin C giúp tăng hấp thu sắt.\n\n'
            'Kali và Magie: Kali điều hòa nhịp tim và huyết áp. Magie giúp thư giãn cơ và cải thiện giấc ngủ. Nguồn thực phẩm: chuối, bơ, khoai lang, rau lá xanh.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'dinh_duong',
        author: 'DS. Trần Quốc Bảo',
        publishedAt: '15/03/2026',
        tags: ['vitamin', 'khoáng chất', 'vi chất'],
      ),
      Article(
        id: 'dn4',
        title: 'Xây dựng thực đơn cân bằng cho cả gia đình',
        content:
            'Bữa ăn gia đình không chỉ là dịp sum họp mà còn là cơ hội để chăm sóc sức khỏe cho mọi thành viên. Một thực đơn cân bằng cần đáp ứng nhu cầu dinh dưỡng của cả trẻ em và người lớn.\n\n'
            'Nguyên tắc xây dựng thực đơn: Đảm bảo 4 nhóm chất: tinh bột (cơm, bún, phở), đạm (thịt, cá, trứng, đậu), chất béo tốt (dầu oliu, mỡ cá) và vitamin-khoáng chất (rau củ quả).\n\n'
            'Gợi ý thực đơn một ngày: Sáng - bánh mì nguyên cám với trứng và sữa. Trưa - cơm gạo lứt, cá kho, canh rau. Tối - ức gà xào nấm, salad rau trộn. Bữa phụ - sữa chua và trái cây tươi.\n\n'
            'Mẹo tiết kiệm thời gian: Chuẩn bị nguyên liệu vào cuối tuần. Nấu lượng lớn và chia nhỏ bảo quản đông lạnh. Sử dụng nồi chiên không dầu và nồi áp suất để rút ngắn thời gian nấu.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'dinh_duong',
        author: 'Chuyên gia ẩm thực Lê Minh Hằng',
        publishedAt: '08/03/2026',
        tags: ['thực đơn', 'bữa ăn', 'gia đình'],
      ),
      Article(
        id: 'nc1',
        title: 'Uống nước đúng cách - Bí quyết đơn giản cho sức khỏe',
        content:
            'Nước chiếm khoảng 60% trọng lượng cơ thể và tham gia vào mọi quá trình sinh hóa. Uống nước đúng cách không chỉ giúp giải khát mà còn là chìa khóa cho sức khỏe tối ưu.\n\n'
            'Uống đủ lượng: Công thức phổ biến là 35ml nước cho mỗi kg cân nặng. Ví dụ, người 60kg cần khoảng 2.1 lít mỗi ngày. Nhu cầu tăng thêm khi vận động nhiều hoặc thời tiết nóng.\n\n'
            'Cách uống khoa học: Uống từ từ, nhấp từng ngụm nhỏ thay vì uống một hơi hết ly lớn. Uống nước 30 phút trước bữa ăn, đợi 1 giờ sau ăn mới uống nhiều để không làm loãng dịch vị.\n\n'
            'Thời điểm uống nước quan trọng: Một ly nước ngay khi thức dậy giúp kích hoạt hệ tiêu hóa. Một ly trước khi tắm giúp hạ huyết áp. Một ly nhỏ trước ngủ giúp ngăn chuột rút về đêm.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'nuoc',
        author: 'ThS. Phạm Văn Dũng',
        publishedAt: '22/03/2026',
        tags: ['nước', 'hydrat hóa', 'sức khỏe'],
      ),
      Article(
        id: 'nc2',
        title: 'Lợi ích tuyệt vời của nước với cơ thể',
        content:
            'Nước không chỉ đơn thuần là thức uống giải khát. Nó đóng vai trò thiết yếu trong hầu hết các chức năng của cơ thể, từ tiêu hóa đến điều hòa thân nhiệt.\n\n'
            'Hỗ trợ tiêu hóa: Nước giúp hòa tan chất dinh dưỡng và vận chuyển chúng đến tế bào. Nước cũng giúp ngăn ngừa táo bón bằng cách làm mềm phân và kích thích nhu động ruột.\n\n'
            'Đẹp da tự nhiên: Uống đủ nước giúp da duy trì độ ẩm, tăng độ đàn hồi và giảm nếp nhăn. Nước còn giúp đào thải độc tố qua mồ hôi và nước tiểu, giảm mụn và viêm da.\n\n'
            'Tăng năng lượng: Mất nước chỉ 1-2% trọng lượng cơ thể đã làm giảm đáng kể năng lượng và khả năng tập trung. Uống đủ nước giúp duy trì hiệu suất làm việc và học tập ở mức cao nhất.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'nuoc',
        author: 'BS. Hoàng Thị Thu',
        publishedAt: '15/03/2026',
        tags: ['nước', 'hydrat hóa', 'lợi ích'],
      ),
      Article(
        id: 'nc3',
        title: 'Dấu hiệu nhận biết cơ thể đang thiếu nước',
        content:
            'Nhiều người không nhận ra mình đang bị mất nước nhẹ cho đến khi các triệu chứng rõ ràng xuất hiện. Nhận biết sớm các dấu hiệu này giúp bạn kịp thời bổ sung nước.\n\n'
            'Khát nước: Đây là tín hiệu muộn của mất nước. Khi bạn cảm thấy khát, cơ thể đã mất khoảng 1-2% lượng nước. Tốt nhất nên uống nước đều đặn cả ngày, không chờ đến khi khát.\n\n'
            'Nước tiểu sẫm màu: Màu nước tiểu là chỉ báo tuyệt vời về tình trạng hydrat hóa. Nước tiểu trong hoặc vàng nhạt cho thấy đủ nước. Màu vàng đậm hoặc nâu là dấu hiệu thiếu nước nghiêm trọng.\n\n'
            'Mệt mỏi và đau đầu: Thiếu nước làm giảm lưu lượng máu lên não, gây đau đầu và mệt mỏi. Da khô, môi nứt nẻ và táo bón cũng là những dấu hiệu điển hình của thiếu nước kéo dài.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'nuoc',
        author: 'ThS. Trần Thị Ái',
        publishedAt: '10/03/2026',
        tags: ['thiếu nước', 'mất nước', 'hydrat hóa'],
      ),
      Article(
        id: 'nc4',
        title: 'Nước detox - Xu hướng thanh lọc cơ thể',
        content:
            'Nước detox (nước giải độc) là nước được ngâm với trái cây, rau củ và thảo mộc để tăng hương vị và bổ sung vitamin. Đây là cách tuyệt vời để tăng lượng nước uống hàng ngày.\n\n'
            'Công thức nước detox cơ bản: Bình 2 lít nước lọc + 1 quả dưa chuột thái lát + 1 quả chanh + 10 lá bạc hà + vài lát gừng tươi. Để tủ lạnh qua đêm cho các hương vị hòa quyện.\n\n'
            'Tác dụng thực sự: Nước detox không phải là thuốc giải độc kỳ diệu như một người quảng cáo. Thận và gan của bạn đã làm nhiệm vụ giải độc rất tốt. Nhưng nước detox giúp bạn uống nhiều nước hơn và bổ sung vitamin C.\n\n'
            'Lưu ý: Chỉ nên ngâm trái cây trong 12-24 giờ và bảo quản tủ lạnh. Vệ sinh sạch nguyên liệu trước khi ngâm. Không thêm đường hoặc mật ong nếu bạn đang kiểm soát cân nặng.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'nuoc',
        author: 'Chuyên gia dinh dưỡng Lê Thúy Quỳnh',
        publishedAt: '05/03/2026',
        tags: ['detox', 'nước', 'thanh lọc'],
      ),
      Article(
        id: 'cl1',
        title: 'Calo là gì? Vai trò của calo với cơ thể',
        content:
            'Calo là đơn vị đo năng lượng. Trong dinh dưỡng, calo dùng để đo lượng năng lượng mà thực phẩm cung cấp cho cơ thể. Hiểu đúng về calo là bước đầu tiên để kiểm soát cân nặng hiệu quả.\n\n'
            'Năng lượng cho mọi hoạt động: Từ thở, tim đập đến chạy bộ, tất cả đều cần năng lượng. Người trưởng thành cần khoảng 2000-2500 calo mỗi ngày, tùy thuộc vào giới tính, tuổi và mức độ vận động.\n\n'
            'Nguyên lý cơ bản của cân nặng: Nếu nạp nhiều calo hơn tiêu thụ, bạn sẽ tăng cân. Ngược lại, nạp ít hơn tiêu thụ, bạn sẽ giảm cân. Để giảm 1kg mỡ, bạn cần thâm hụt khoảng 7700 calo.\n\n'
            'Calo rỗng: Không phải calo nào cũng giống nhau. Đồ ngọt, nước ngọt, thức ăn nhanh cung cấp nhiều calo nhưng ít dinh dưỡng. Hãy ưu tiên thực phẩm giàu vi chất như rau củ, trái cây và protein nạc.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'calo',
        author: 'ThS. Nguyễn Đình Khang',
        publishedAt: '28/03/2026',
        tags: ['calo', 'năng lượng', 'cân nặng'],
      ),
      Article(
        id: 'cl2',
        title: 'Cách tính nhu cầu calo hàng ngày chính xác',
        content:
            'Biết được nhu cầu calo hàng ngày giúp bạn lên kế hoạch ăn uống phù hợp với mục tiêu sức khỏe. Công thức Mifflin-St Jeor là phương pháp được các chuyên gia khuyên dùng.\n\n'
            'Công thức tính: Nam: BMR = 10 x cân nặng(kg) + 6.25 x chiều cao(cm) - 5 x tuổi + 5. Nữ: BMR = 10 x cân nặng + 6.25 x chiều cao - 5 x tuổi - 161. BMR là lượng calo tối thiểu để duy trì sự sống.\n\n'
            'Nhân với hệ số vận động: Ít vận động (BMR × 1.2), nhẹ (1.375), trung bình (1.55), nặng (1.725), rất nặng (1.9). Kết quả là tổng calo cần thiết để duy trì cân nặng hiện tại.\n\n'
            'Ví dụ: Nữ 30 tuổi, 60kg, 165cm, vận động nhẹ: BMR = 1324, TDEE = 1324 × 1.375 ≈ 1820 calo/ngày. Để giảm cân, trừ đi 300-500 calo. Để tăng cân, thêm 300-500 calo.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'calo',
        author: 'Chuyên gia dinh dưỡng Phạm Hoàng Nam',
        publishedAt: '22/03/2026',
        tags: ['calo', 'tính calo', 'BMR'],
      ),
      Article(
        id: 'cl3',
        title: 'Thực phẩm ít calo nhưng giàu dinh dưỡng',
        content:
            'Nếu bạn đang muốn kiểm soát cân nặng mà vẫn đảm bảo dinh dưỡng, hãy chọn những thực phẩm có mật độ năng lượng thấp nhưng giàu vi chất. Dưới đây là những gợi ý tuyệt vời.\n\n'
            'Rau củ không tinh bột: Dưa chuột, cà chua, bông cải xanh, rau bina, nấm. Một bát rau củ chỉ chứa 25-50 calo nhưng cung cấp chất xơ và vitamin giúp bạn no lâu.\n\n'
            'Trái cây ít đường: Dâu tây, việt quất, bưởi, dưa hấu. Chúng giàu chất chống oxy hóa và nước, giúp thanh lọc cơ thể. Một cốc dâu tây chỉ có khoảng 50 calo.\n\n'
            'Protein nạc: Ức gà không da, lòng trắng trứng, đậu phụ, cá trắng. Protein giúp xây dựng cơ bắp và tạo cảm giác no lâu. 100g ức gà cung cấp 165 calo và 31g protein.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'calo',
        author: 'ThS. Vũ Thị Thanh',
        publishedAt: '18/03/2026',
        tags: ['calo thấp', 'giảm cân', 'dinh dưỡng'],
      ),
      Article(
        id: 'cl4',
        title: 'Calo ẩn - Kẻ thù của người giảm cân',
        content:
            'Nhiều người thất bại trong việc giảm cân vì không nhận ra lượng calo ẩn trong các thực phẩm tưởng chừng vô hại. Dưới đây là những bẫy calo phổ biến nhất.\n\n'
            'Đồ uống có đường: Một lon nước ngọt 330ml chứa 140 calo và 35g đường. Cà phê sữa đá có thể chứa 200-400 calo tùy lượng sữa và đường. Trà sữa trân châu có thể lên đến 500 calo mỗi ly.\n\n'
            'Nước sốt và gia vị: Sốt mayonnaise (90 calo/muỗng), sốt tahini (90 calo/muỗng), dầu mè (120 calo/muỗng). Nhiều món salad tưởng healthy nhưng nước sốt đã đóng góp 300-500 calo.\n\n'
            'Đồ ăn vặt "healthy": Granola (120 calo/30g), các loại hạt (170 calo/30g), trái cây sấy (80 calo/30g). Tưởng lành mạnh nhưng ăn quá nhiều dễ dàng vượt quá nhu cầu calo.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'calo',
        author: 'BS. Đỗ Thị Phương',
        publishedAt: '12/03/2026',
        tags: ['calo ẩn', 'giảm cân', 'đồ uống'],
      ),
      Article(
        id: 'tl1',
        title: 'Lợi ích của tập luyện thể dục đều đặn',
        content:
            'Tập thể dục không chỉ giúp bạn có thân hình đẹp mà còn mang lại vô vàn lợi ích cho sức khỏe thể chất và tinh thần. Chỉ cần 30 phút vận động mỗi ngày, bạn sẽ thấy sự khác biệt.\n\n'
            'Sức khỏe tim mạch: Tập luyện làm tăng nhịp tim, cải thiện tuần hoàn máu, giảm huyết áp và cholesterol xấu. Nguy cơ đau tim và đột quỵ giảm đáng kể ở người tập thể dục thường xuyên.\n\n'
            'Sức khỏe tinh thần: Vận động giải phóng endorphin - hormone hạnh phúc, giúp giảm stress, lo âu và trầm cảm. Tập luyện cũng cải thiện chất lượng giấc ngủ và tăng tự tin.\n\n'
            'Xương và cơ bắp chắc khỏe: Các bài tập chịu trọng lượng như đi bộ, chạy, nhảy dây giúp tăng mật độ xương, ngăn ngừa loãng xương. Tập tạ giúp xây dựng và duy trì khối lượng cơ khi về già.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'tap_luyen',
        author: 'HLV. Nguyễn Thành Công',
        publishedAt: '26/03/2026',
        tags: ['tập luyện', 'sức khỏe', 'vận động'],
      ),
      Article(
        id: 'tl2',
        title: 'Hướng dẫn xây dựng lịch tập luyện khoa học',
        content:
            'Một lịch tập luyện khoa học là chìa khóa để đạt được mục tiêu thể hình mà không gặp chấn thương. Dù bạn là người mới hay đã tập lâu, nguyên tắc sau đây sẽ giúp bạn tối ưu hóa kết quả.\n\n'
            'Nguyên tắc 80/20: 80% kết quả đến từ 20% nỗ lực. Tập trung vào các bài tập compound tác động nhiều nhóm cơ: squat, deadlift, bench press, pull-up. Đây là những bài tập hiệu quả nhất.\n\n'
            'Lịch tập cho người mới: Tập 3 buổi/tuần, xen kẽ các ngày. Mỗi buổi 45-60 phút. Khởi động 5-10 phút, tập chính 30-40 phút, thư giãn 5-10 phút. Nghỉ 48 giờ trước khi tập cùng nhóm cơ.\n\n'
            'Tăng tiến dần dần: Nguyên tắc quá tải tiến bộ - tăng dần trọng lượng hoặc số lần lặp. Tăng không quá 10% mỗi tuần. Lắng nghe cơ thể, nếu đau nhức bất thường, hãy giảm cường độ hoặc nghỉ ngơi.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'tap_luyen',
        author: 'HLV. Trần Hoàng Long',
        publishedAt: '20/03/2026',
        tags: ['tập luyện', 'lịch tập', 'thể hình'],
      ),
      Article(
        id: 'tl3',
        title: 'Các bài tập giãn cơ giảm đau lưng hiệu quả',
        content:
            'Đau lưng là vấn đề phổ biến ảnh hưởng đến 80% người trưởng thành. Nguyên nhân thường do ngồi nhiều, sai tư thế và cơ lưng yếu. Các bài tập giãn cơ sau đây có thể giúp ích.\n\n'
            'Tư thế mèo - bò: Quỳ trên thảm, hai tay chống. Hít vào, cong lưng xuống (tư thế bò). Thở ra, uốn lưng lên (tư thế mèo). Lặp lại 10-15 lần. Giúp tăng tính linh hoạt của cột sống.\n\n'
            'Kéo giãn cơ mông: Nằm ngửa, co một gối lên ngực, giữ 30 giây. Sau đó bắt chéo chân để kéo sâu hơn. Lặp lại với chân kia. Bài tập này giúp giảm đau thần kinh tọa.\n\n'
            'Plank: Nằm sấp, chống khuỷu tay và mũi chân. Giữ cơ thể thành đường thẳng. Bắt đầu với 20-30 giây, tăng dần lên 1-2 phút. Plank tăng cường cơ core, hỗ trợ cột sống.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'tap_luyen',
        author: 'Kỹ thuật viên Vật lý trị liệu Hoàng Minh',
        publishedAt: '15/03/2026',
        tags: ['giãn cơ', 'đau lưng', 'tập luyện'],
      ),
      Article(
        id: 'tl4',
        title: 'Yoga cho người mới bắt đầu',
        content:
            'Yoga là bộ môn kết hợp giữa các tư thế (asana), kỹ thuật thở (pranayama) và thiền định. Yoga phù hợp với mọi lứa tuổi và thể trạng, mang lại lợi ích toàn diện cho sức khỏe.\n\n'
            'Tư thế núi (Tadasana): Đứng thẳng, hai chân rộng bằng hông. Cột sống kéo dài, tay thả dọc thân. Hít thở sâu 5 nhịp. Tư thế này giúp cải thiện tư thế và tăng sự tập trung.\n\n'
            'Tư thế chó úp mặt (Adho Mukha Svanasana): Bốn chân chống, đẩy hông lên cao tạo hình chữ V ngược. Giữ 5-7 nhịp thở. Duỗi cơ lưng, vai và chân, tăng tuần hoàn máu lên não.\n\n'
            'Tư thế em bé (Balasana): Quỳ gối, ngồi lên gót chân, gập người về trước, trán chạm sàn. Tay duỗi về trước. Giữ 10 nhịp thở. Đây là tư thế nghỉ ngơi giúp thư giãn sâu.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'tap_luyen',
        author: 'HLV Yoga Trần Thị Diễm',
        publishedAt: '10/03/2026',
        tags: ['yoga', 'thư giãn', 'dẻo dai'],
      ),
      Article(
        id: 'ct1',
        title: 'Căng thẳng - Kẻ thù thầm lặng của sức khỏe',
        content:
            'Căng thẳng kéo dài (stress mạn tính) là một trong những nguyên nhân hàng đầu gây ra các bệnh về tim mạch, tiêu hóa và tâm thần. Nhận diện và kiểm soát stress là kỹ năng sống còn.\n\n'
            'Dấu hiệu của stress: Đau đầu thường xuyên, căng cơ bắp, mệt mỏi. Thay đổi giấc ngủ (mất ngủ hoặc ngủ quá nhiều). Thay đổi khẩu vị (ăn quá nhiều hoặc chán ăn). Cáu gắt, lo âu, khó tập trung.\n\n'
            'Ảnh hưởng đến cơ thể: Stress làm tăng cortisol và adrenaline, gây tăng huyết áp, nhịp tim nhanh. Về lâu dài, stress gây suy giảm hệ miễn dịch, tăng nguy cơ đau tim và đột quỵ.\n\n'
            'Giải pháp dài hạn: Thiết lập ranh giới rõ ràng trong công việc. Dành thời gian cho sở thích cá nhân. Duy trì kết nối xã hội. Học cách nói "không" với những việc không cần thiết.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'cang_thang',
        author: 'ThS Tâm lý Nguyễn Thị Hồng',
        publishedAt: '30/03/2026',
        tags: ['stress', 'căng thẳng', 'sức khỏe tinh thần'],
      ),
      Article(
        id: 'ct2',
        title: 'Kỹ thuật thở sâu - Giảm stress tức thì',
        content:
            'Thở sâu là một trong những công cụ mạnh mẽ nhất để bình tĩnh hệ thần kinh, giúp bạn đối phó với căng thẳng ngay lập tức. Kỹ thuật này đơn giản, không cần dụng cụ và có thể thực hành bất cứ lúc nào.\n\n'
            'Thở cơ hoành: Đặt một tay lên ngực, tay kia lên bụng. Hít vào chậm bằng mũi, cảm nhận bụng phồng lên. Thở ra chậm qua miệng, bụng xẹp xuống. Lặp lại 5-10 lần. Giúp giảm nhịp tim và huyết áp.\n\n'
            'Thở vuông (Box breathing): Hít vào 4 giây, giữ 4 giây, thở ra 4 giây, giữ 4 giây. Lặp lại 3-5 phút. Kỹ thuật này được lực lượng đặc nhiệm Hải quân Mỹ sử dụng để giữ bình tĩnh.\n\n'
            'Thở luân phiên (Nadi Shodhana): Ngón tay cái bịt lỗ mũi phải, hít qua trái. Sau đó bịt trái, thở qua phải. Đổi bên. Thực hiện 5-10 chu kỳ. Giúp cân bằng hai bán cầu não và làm dịu tâm trí.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'cang_thang',
        author: 'Chuyên gia thiền Đỗ Văn Minh',
        publishedAt: '25/03/2026',
        tags: ['thở sâu', 'giảm stress', 'thiền'],
      ),
      Article(
        id: 'ct3',
        title: 'Thiền chánh niệm cho người mới bắt đầu',
        content:
            'Thiền chánh niệm là phương pháp thực hành đưa sự chú ý vào hiện tại một cách không phán xét. Khoa học đã chứng minh thiền làm thay đổi cấu trúc não bộ, tăng khả năng chịu đựng stress.\n\n'
            'Bắt đầu với 5 phút: Ngồi thoải mái, lưng thẳng. Đặt hẹn giờ 5 phút. Nhắm mắt, tập trung vào hơi thở. Khi tâm trí lang thang (điều này rất bình thường), nhẹ nhàng đưa nó trở lại mà không phán xét.\n\n'
            'Quét cơ thể (Body scan): Bắt đầu từ đỉnh đầu, di chuyển sự chú ý xuống dần đến ngón chân. Chú ý cảm giác ở mỗi bộ phận. Nhận biết căng cứng ở đâu và thư giãn nó. Làm trong 10-15 phút.\n\n'
            'Thiền trong sinh hoạt: Ăn trong chánh niệm - ăn chậm, cảm nhận mùi vị và kết cấu. Đi trong chánh niệm - cảm nhận từng bước chân. Rửa bát trong chánh niệm - cảm nhận nước và bọt xà phòng.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'cang_thang',
        author: 'Giảng viên thiền Lý Anh Tú',
        publishedAt: '20/03/2026',
        tags: ['thiền', 'chánh niệm', 'giảm stress'],
      ),
      Article(
        id: 'ct4',
        title: 'Quản lý thời gian để giảm căng thẳng',
        content:
            'Áp lực công việc, deadline dồn dập là nguyên nhân hàng đầu gây stress. Quản lý thời gian hiệu quả không chỉ giúp bạn hoàn thành công việc mà còn giảm đáng kể mức độ căng thẳng.\n\n'
            'Phương pháp Pomodoro: Làm việc tập trung 25 phút, nghỉ 5 phút. Sau 4 pomodoro, nghỉ dài 15-30 phút. Phương pháp này giúp duy trì sự tập trung cao độ mà không kiệt sức.\n\n'
            'Ma trận Eisenhower: Phân loại việc theo 4 nhóm: Quan trọng - Khẩn cấp (làm ngay), Quan trọng - Không khẩn cấp (lên lịch), Không quan trọng - Khẩn cấp (ủy thác), Không quan trọng - Không khẩn cấp (xóa bỏ).\n\n'
            'Nguyên tắc 2 phút: Nếu một việc mất ít hơn 2 phút, hãy làm nó ngay lập tức. Điều này ngăn chặn sự tích tụ của những việc nhỏ, giúp giảm tải tinh thần và tăng năng suất.',
        imageUrl: 'assets/images/ui/hh.png',
        category: 'cang_thang',
        author: 'Vũ Tuấn Anh',
        publishedAt: '15/03/2026',
        tags: ['quản lý thời gian', 'stress', 'năng suất'],
      ),
    ];
  }
}
