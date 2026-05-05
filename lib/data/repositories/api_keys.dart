// ⚠️ API KEYS - THÊM API KEY CỦA BẠN VÀO ĐÂY

class APIKeys {
  // 1. Spoonacular API (miễn phí 150 request/ngày)
  // Đăng ký tại: https://spoonacular.com/food-api
  static const String spoonacular = '726208451cb443aaaaf8985eb44d6713';

  // 2. USDA FoodData Central API (miễn phí 1000 request/giờ)
  // Đăng ký tại: https://fdc.nal.usda.gov/api-guide.html
  static const String usda = 'efNApVsozijlschEgqKdQ96y78HakhqTYpANUApx';

  // 3. Open Food Facts (miễn phí, không cần key)
  // Đã có sẵn trong off_api.dart
}

class APIConfig {
  static bool get hasKeys {
    return APIKeys.spoonacular != 'YOUR_SPOONACULAR_API_KEY' ||
           APIKeys.usda != 'YOUR_USDA_API_KEY';
  }
}