/// Maps MangaDex tag UUIDs to their human-readable English names.
///
/// MangaDex returns tags as opaque UUID strings. This mapper provides a
/// look-up table for the most common genres and themes so the UI can display
/// friendly labels instead of raw identifiers.
class MangaDexTagMapper {
  static const Map<String, String> _tagNames = {
    // 🎭 Genres
    '391b0423-d847-456f-aff0-8b0cfc03066b': 'Action',
    '87cc87cd-a395-47af-b27a-93258283bbc6': 'Adventure',
    '4d32cc48-9f00-4cca-9b5a-a839f0764984': 'Comedy',
    'b9af3a63-f058-46de-a9a0-e0c13906197a': 'Drama',
    'cdc58593-87dd-415e-bbc0-2ec27bf404cc': 'Fantasy',
    '423e2eae-a7a2-4a8b-ac03-a8351462d71d': 'Romance',
    'e5301a23-ebd9-49dd-a0cb-2add944c7fe9': 'Slice of Life',
    'cdad7e68-1419-41dd-bdce-27753074a640': 'Horror',
    'ee968100-4191-4968-93d3-f82d72be7e46': 'Mystery',
    '3b60b75c-a2d7-4860-ab56-05f391bb889c': 'Psychological',

    // 🎨 Themes
    'caaa44eb-cd40-4177-b930-79d3ef2afe87': 'School Life',
    'f8f62932-27da-4fe4-8ee1-6779a8c5edba': 'Historical',
    'ace04997-f6bd-436e-b261-779182193d3d': 'Isekai',
    '292e862b-2d17-4062-90a2-0356caa4ae27': 'Time Travel',
  };

  /// Returns the human-readable tag name for the given MangaDex tag [id],
  /// or `null` if the UUID is not in the known mapping table.
  static String? nameFromId(String id) {
    return _tagNames[id];
  }
}
