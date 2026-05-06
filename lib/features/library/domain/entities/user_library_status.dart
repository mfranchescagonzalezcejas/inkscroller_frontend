/// Per-user library status used to organize saved manga locally.
enum UserLibraryStatus { reading, completed, paused }

extension UserLibraryStatusX on UserLibraryStatus {
  /// Stable persistence value for local storage.
  String get storageValue {
    switch (this) {
      case UserLibraryStatus.reading:
        return 'reading';
      case UserLibraryStatus.completed:
        return 'completed';
      case UserLibraryStatus.paused:
        return 'paused';
    }
  }

  static UserLibraryStatus fromStorageValue(String? value) {
    switch (value) {
      case 'completed':
        return UserLibraryStatus.completed;
      case 'paused':
        return UserLibraryStatus.paused;
      case 'reading':
      default:
        return UserLibraryStatus.reading;
    }
  }
}
