// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get offlineBannerMessage =>
      'Sin conexión. Mostrando datos guardados si están disponibles.';

  @override
  String get searchMangaHint => 'Buscar mangas…';

  @override
  String get clearAction => 'Limpiar';

  @override
  String get noMangasAvailable => 'No hay mangas disponibles';

  @override
  String noSearchResults(Object query) {
    return 'Sin resultados para \"$query\"';
  }

  @override
  String get noMoreMangaToLoad => 'No hay más mangas para cargar';

  @override
  String get failedToLoadChapters => 'No se pudieron cargar los capítulos';

  @override
  String get retryAction => 'Reintentar';

  @override
  String get noChaptersAvailable => 'No hay capítulos disponibles';

  @override
  String get chaptersTitle => 'Capítulos';

  @override
  String get routeInvalidTitle => 'Ruta inválida';

  @override
  String get routeMissingMangaMessage =>
      'Faltan los datos del manga para abrir el detalle.';

  @override
  String get routeMissingChapterMessage =>
      'No se encontró el capítulo solicitado.';

  @override
  String get routeNotFoundTitle => 'Página no encontrada';

  @override
  String get routeNotFoundMessage => 'La ruta solicitada no existe.';

  @override
  String get backToHomeAction => 'Volver al inicio';

  @override
  String get settingsComingSoon => 'Próximamente 👀';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsAppSectionTitle => 'Aplicación';

  @override
  String get settingsAppNameLabel => 'Nombre de la app';

  @override
  String get settingsFlavorLabel => 'Flavor';

  @override
  String get settingsApiBaseUrlLabel => 'API base URL';

  @override
  String get settingsCacheSectionTitle => 'Caché';

  @override
  String get settingsMangaListCacheLabel => 'Caché de lista de mangas';

  @override
  String get settingsMangaDetailCacheLabel => 'Caché de detalle de manga';

  @override
  String get settingsMangaChaptersCacheLabel => 'Caché de capítulos';

  @override
  String settingsCacheMinutesValue(int minutes) {
    return '$minutes min';
  }

  @override
  String get settingsClearCacheAction => 'Limpiar datos guardados';

  @override
  String get settingsCacheClearedMessage => 'Datos guardados eliminados';

  @override
  String get settingsCacheClearFailedMessage =>
      'No se pudieron eliminar los datos guardados';

  @override
  String get loadingChapter => 'Cargando capítulo';

  @override
  String chapterPagesProgress(int loadedPages, int totalPages) {
    return '$loadedPages / $totalPages páginas';
  }

  @override
  String get readingChapter => 'Leyendo capítulo';

  @override
  String chapterLabel(Object number) {
    return 'Capítulo $number';
  }

  @override
  String get extraLabel => 'Extra';

  @override
  String get homeFeatured => '🔥 Destacados';

  @override
  String get homeLatest => '🆕 Nuevos';

  @override
  String get homePopular => '🔥 Populares';

  @override
  String get homeDemographic => '📚 Demografía';

  @override
  String get homeNoMangas => 'No hay mangas disponibles';

  @override
  String get demographicShounen => 'Shounen';

  @override
  String get demographicShoujo => 'Shoujo';

  @override
  String get demographicSeinen => 'Seinen';

  @override
  String get demographicJosei => 'Josei';

  @override
  String get readNow => 'Leer ahora';

  @override
  String get addToLibrary => 'Añadir a biblioteca';

  @override
  String get removeFromLibrary => 'Quitar de biblioteca';

  @override
  String libraryItemAdded(Object title) {
    return '$title se añadió a tu biblioteca';
  }

  @override
  String libraryItemRemoved(Object title) {
    return '$title se quitó de tu biblioteca';
  }

  @override
  String get genreAll => 'Todo';

  @override
  String get genrePopular => 'Popular';

  @override
  String get genreRomance => 'Romance';

  @override
  String get genreAction => 'Acción';

  @override
  String get libraryTitle => 'Mi Biblioteca';

  @override
  String libraryCollectionsCount(int count) {
    return '$count colecciones';
  }

  @override
  String get libraryTabAll => 'Todo';

  @override
  String get libraryTabReading => 'Leyendo';

  @override
  String get libraryTabCompleted => 'Completo';

  @override
  String get libraryTabOnHold => 'Pausado';

  @override
  String get libraryEmpty =>
      'Tu biblioteca está vacía. Añadí mangas desde Inicio o el detalle.';

  @override
  String get libraryEmptyTab => 'Todavía no hay mangas en esta pestaña.';

  @override
  String get libraryStatusReading => 'Marcar como Leyendo';

  @override
  String get libraryStatusCompleted => 'Marcar como Completo';

  @override
  String get libraryStatusPaused => 'Marcar como Pausado';

  @override
  String get libraryStatusUpdated => 'Estado de biblioteca actualizado';

  @override
  String get libraryUnknownMeta => 'Sin dato';

  @override
  String libraryProgressValue(int readCount, int totalCount) {
    return '$readCount / $totalCount leídos';
  }

  @override
  String get exploreTitle => 'Explorar';

  @override
  String get exploreSubtitle => 'Descubre tu próxima historia';

  @override
  String get externalChapterTitle => 'Capítulo externo';

  @override
  String get externalChapterMessage =>
      'Este capítulo solo está disponible en el sitio original. No se puede leer dentro de InkScroller.';

  @override
  String get externalChapterOpenAction => 'Abrir en el sitio original';

  @override
  String get externalChapterGoBackAction => 'Volver';

  @override
  String get readingProgressDialogTitle => 'Actualizar progreso de lectura';

  @override
  String readingProgressDialogMessage(int count, Object chapterLabel) {
    return 'Se van a marcar $count capítulos hasta $chapterLabel como leídos.';
  }

  @override
  String readingProgressDialogExternalMessage(int count, Object chapterLabel) {
    return 'Este capítulo se abre afuera de InkScroller. ¿Querés marcar $count capítulos hasta $chapterLabel antes de salir?';
  }

  @override
  String get readingProgressConfirmAction => 'Marcar';

  @override
  String get readingProgressOpenOnlyAction => 'Abrir sin marcar';

  @override
  String get readingProgressUndoAction => 'Deshacer';

  @override
  String get readingProgressUpdatedMessage => 'Progreso de lectura actualizado';

  @override
  String get navHome => 'Inicio';

  @override
  String get navExplore => 'Explorar';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get navProfile => 'Perfil';

  @override
  String get settingsCacheSizeLabel => 'Datos en caché';

  @override
  String settingsCacheSizeValue(Object size) {
    return '$size';
  }

  @override
  String get settingsCacheSizeLoading => 'Calculando…';

  @override
  String get refreshAction => 'Actualizar';

  @override
  String get profileReadingPreferencesSection => 'Preferencias de lectura';

  @override
  String get profileAppSettingsSection => 'Ajustes de la app';

  @override
  String get profileReadingModeTitle => 'Modo de lectura';

  @override
  String get profileReadingModeVertical => 'Vertical';

  @override
  String get profileReadingModePaged => 'Paginado';

  @override
  String get profilePreferredAppLanguageTitle => 'Idioma de la app';

  @override
  String get profilePreferredReadingLanguageTitle => 'Idioma para leer manga';

  @override
  String get profileCacheSettingsTitle => 'Caché y datos guardados';

  @override
  String get profileCacheSettingsSubtitle => 'Limpiar datos locales';

  @override
  String get profileAppInfoTitle => 'Información de la app';

  @override
  String get profileAppInfoSubtitle => 'Versión, licencias, créditos';

  @override
  String get profileGuestTitle => 'Estás usando la app como invitada.';

  @override
  String get profileGuestSubtitle =>
      'Iniciá sesión o creá una cuenta para ver tu perfil y gestionar tus preferencias.';

  @override
  String get profileGuestCta => 'Iniciar sesión o crear cuenta';

  @override
  String get profileSignOutAction => 'Cerrar sesión';

  @override
  String get profileSignOutSnackBar =>
      'Sesión cerrada. Seguís en modo invitada.';

  @override
  String get profileServerConnectionError =>
      'No se pudo conectar con el servidor.';

  @override
  String profileVersionLabel(Object version, Object buildNumber) {
    return 'Versión $version (Build $buildNumber)';
  }

  @override
  String get authSignInTitle => 'Iniciá sesión';

  @override
  String get authSignInSubtitle => 'Tu colección de manga te espera';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Contraseña';

  @override
  String get authSignInButton => 'Iniciar sesión';

  @override
  String get authNoAccount => '¿No tenés cuenta? Crear una';

  @override
  String get authContinueAsGuest => 'Continuar como invitada';

  @override
  String get authEmailRequired => 'Ingresá tu email.';

  @override
  String get authEmailInvalid => 'Ingresá un email válido.';

  @override
  String get authPasswordRequired => 'Ingresá tu contraseña.';

  @override
  String get authPasswordTooShort =>
      'La contraseña debe tener al menos 6 caracteres.';

  @override
  String get authCreateAccountTitle => 'Crear cuenta';

  @override
  String get authCreateAccountSubtitle => 'Unite a la colección';

  @override
  String get authCreateAccountButton => 'Crear cuenta';

  @override
  String get authHaveAccount => '¿Ya tenés cuenta? Iniciá sesión';

  @override
  String get readerSettingsDirection => 'Dirección de lectura';

  @override
  String get readerSettingsBrightness => 'Brillo';

  @override
  String get readerSettingsAmoled => 'Negro AMOLED';

  @override
  String get readerSettingsAmoledSubtitle => 'Ahorrá batería en pantallas OLED';

  @override
  String get readerSettingsImmersive => 'Modo inmersivo';

  @override
  String get readerSettingsImmersiveSubtitle =>
      'Ocultar barras de navegación del sistema';

  @override
  String get readerSettingsConfirm => 'Confirmar ajustes';

  @override
  String get readerDirectionLtr => 'LTR';

  @override
  String get readerDirectionRtl => 'RTL';

  @override
  String get readerDirectionVertical => 'Vertical';
}
