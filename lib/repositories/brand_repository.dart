import 'package:elmazr3a/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:elmazr3a/data_model/brand_response.dart';
import 'package:elmazr3a/helpers/shared_value_helper.dart';

class BrandRepository {

  Future<BrandResponse> getFilterPageBrands() async {
    Uri url = Uri.parse("${AppConfig.BASE_URL}/filter/brands");
    final response =
    await http.get(url,headers: {
      "App-Language": app_language.$,
    });
    return brandResponseFromJson(response.body);
  }

  Future<BrandResponse> getBrands({name = "", page = 1}) async {
    Uri url = Uri.parse("${AppConfig.BASE_URL}/brands"+
        "?page=${page}&name=${name}");
    final response =
    await http.get(url,headers: {
      "App-Language": app_language.$,
    });
    return brandResponseFromJson(response.body);
  }



}
