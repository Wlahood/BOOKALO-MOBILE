import '../models/event_detail.dart';
import '../services/api_client.dart';
import '../models/events_page.dart';

class EventsRepository {
  final ApiClient api;

  EventsRepository(this.api);

  Future<EventDetail> fetchEvent(int id) async {
    final json = await api.getJson('/events/$id');
    final response = EventDetailResponse.fromJson(json);
    return response.data;
  }

  Future<List<EventListItem>> fetchVenueUpcomingEvents({
    required int venueId,
    required String startDate, // YYYY-MM-DD
    required String endDate, // YYYY-MM-DD
    int perPage = 20,
  }) async {
    final json = await api.getJson(
      '/events',
      query: {
        'venue_id': venueId.toString(),
        'start_date': startDate,
        'end_date': endDate,
        'per_page': perPage.toString(),
      },
    );

    return EventsPageResponse.fromJson(json).data;
  }

  Future<List<EventListItem>> fetchBandUpcomingEvents({
    required int bandId,
    required String startDate, // YYYY-MM-DD
    required String endDate, // YYYY-MM-DD
    int perPage = 20,
  }) async {
    final json = await api.getJson(
      '/events',
      query: {
        'band_id': bandId.toString(),
        'start_date': startDate,
        'end_date': endDate,
        'per_page': perPage.toString(),
      },
    );

    return EventsPageResponse.fromJson(json).data;
  }
}
