import '../models/auth_user.dart';
import '../models/my_entity.dart';
import '../services/api_client.dart';

class MeSummary {
  MeSummary({required this.user, required this.bands, required this.venues});

  final AuthUser user;
  final List<MyEntity> bands;
  final List<MyEntity> venues;
}

class MeRepository {
  MeRepository(this.api);
  final ApiClient api;

  Future<MeSummary> summary() async {
    final json = await api.getJson('/me/summary');

    final userJson = json['user'] as Map<String, dynamic>;
    final bandsJson = (json['bands'] as List<dynamic>? ?? const []);
    final venuesJson = (json['venues'] as List<dynamic>? ?? const []);

    final bands = bandsJson
        .map((e) => MyEntity.fromJson(e as Map<String, dynamic>, type: 'band'))
        .toList();

    final venues = venuesJson
        .map((e) => MyEntity.fromJson(e as Map<String, dynamic>, type: 'venue'))
        .toList();

    return MeSummary(
      user: AuthUser.fromJson(userJson),
      bands: bands,
      venues: venues,
    );
  }
}
