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
  String get demographicUnspecified => 'Sin especificar';

  @override
  String get profileDemographicTitle => 'Demografía mostrada';

  @override
  String profileDemographicCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seleccionados',
      one: '1 seleccionado',
    );
    return '$_temp0';
  }

  @override
  String get profileDemographicSelectionRequired =>
      'Selecciona al menos una demografía';

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
      'Tu biblioteca está vacía. Añade mangas desde Inicio o el detalle.';

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
    return 'Este capítulo se abre fuera de InkScroller. ¿Quieres marcar $count capítulos hasta $chapterLabel antes de salir?';
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
      'Inicia sesión o crea una cuenta para ver tu perfil y gestionar tus preferencias.';

  @override
  String get profileGuestCta => 'Iniciar sesión o crear cuenta';

  @override
  String get profileSignOutAction => 'Cerrar sesión';

  @override
  String get profileSignOutSnackBar =>
      'Sesión cerrada. Sigues en modo invitada.';

  @override
  String get profileServerConnectionError =>
      'No se pudo conectar con el servidor.';

  @override
  String profileVersionLabel(Object version, Object buildNumber) {
    return 'Versión $version (Build $buildNumber)';
  }

  @override
  String get authSignInTitle => 'Inicia sesión';

  @override
  String get authSignInSubtitle => 'Tu colección de manga te espera';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Contraseña';

  @override
  String get authSignInButton => 'Iniciar sesión';

  @override
  String get authNoAccount => '¿No tienes cuenta? Crear una';

  @override
  String get authContinueAsGuest => 'Continuar como invitada';

  @override
  String get authEmailRequired => 'Ingresa tu email.';

  @override
  String get authEmailInvalid => 'Ingresa un email válido.';

  @override
  String get authPasswordRequired => 'Ingresa tu contraseña.';

  @override
  String get authPasswordTooShort =>
      'La contraseña debe tener al menos 6 caracteres.';

  @override
  String get authCreateAccountTitle => 'Crear cuenta';

  @override
  String get authCreateAccountSubtitle => 'Únete a la colección';

  @override
  String get authCreateAccountButton => 'Crear cuenta';

  @override
  String get authCompleteProfileTitle => 'Completa tu perfil';

  @override
  String get authCompleteProfileSubtitle =>
      'Tu cuenta fue creada. Agrega los datos obligatorios para continuar.';

  @override
  String get authCompleteProfileButton => 'Completar perfil';

  @override
  String get authHaveAccount => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get authUsernameLabel => 'Usuario';

  @override
  String get authUsernameRequired => 'Elige un nombre de usuario.';

  @override
  String get authUsernameInvalid =>
      'Usa 3–30 letras minúsculas, números, guiones bajos o guiones.';

  @override
  String get authConfirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get authConfirmPasswordRequired => 'Confirma tu contraseña.';

  @override
  String get authConfirmPasswordMismatch => 'Las contraseñas no coinciden.';

  @override
  String get authBirthDateLabel => 'Fecha de nacimiento';

  @override
  String get authBirthDateRequired => 'Elige tu fecha de nacimiento.';

  @override
  String get authBirthDateInvalid => 'Debes tener al menos 13 años.';

  @override
  String get authTermsAcknowledgement =>
      'Acepto los Términos y la Política de Privacidad.';

  @override
  String get authTermsRequired =>
      'Debes aceptar los Términos y la Política de Privacidad.';

  @override
  String get readerSettingsDirection => 'Dirección de lectura';

  @override
  String get readerSettingsBrightness => 'Brillo';

  @override
  String get readerSettingsAmoled => 'Negro AMOLED';

  @override
  String get readerSettingsAmoledSubtitle => 'Ahorra batería en pantallas OLED';

  @override
  String get readerSettingsImmersive => 'Modo inmersivo';

  @override
  String get readerSettingsImmersiveSubtitle =>
      'Ocultar barras de navegación del sistema';

  @override
  String get dialogConfirm => 'OK';

  @override
  String get dialogCancel => 'Cancelar';

  @override
  String get readerSettingsConfirm => 'Confirmar ajustes';

  @override
  String get readerDirectionLtr => 'LTR';

  @override
  String get readerDirectionRtl => 'RTL';

  @override
  String get readerDirectionVertical => 'Vertical';

  @override
  String get deleteAccountTitle => 'Eliminar cuenta';

  @override
  String get deleteAccountWarningBody =>
      'Esta acción es permanente e irreversible. Se eliminarán todos tus datos, incluyendo tu perfil, preferencias y progreso de lectura.';

  @override
  String get deleteAccountPrompt => 'Escribe DELETE para confirmar:';

  @override
  String get deleteAccountPasswordLabel =>
      'Ingresa tu contraseña para reintentar:';

  @override
  String get deleteAccountPasswordHint => 'Contraseña';

  @override
  String get deleteAccountCancelAction => 'Cancelar';

  @override
  String get deleteAccountFinalizeAction => 'Finalizar';

  @override
  String get deleteAccountDeleteAction => 'Eliminar';

  @override
  String get deleteAccountIncompleteRecoveryMessage =>
      'La eliminación está incompleta. Es necesario finalizar la limpieza de datos.';

  @override
  String get accountSectionLabel => 'CUENTA';

  @override
  String get settingsAccountDeletedWithWarnings =>
      'Cuenta eliminada con advertencias';

  @override
  String get settingsAccountDeletedSuccessfully =>
      'Cuenta eliminada correctamente';

  @override
  String get cleanupUnexpectedError => 'Error durante la limpieza';

  @override
  String readerPageLoading(int pageNumber) {
    return 'Página $pageNumber';
  }

  @override
  String readerPageLoadingVerbose(int pageNumber) {
    return 'Cargando página $pageNumber…';
  }

  @override
  String readerPageLoadError(int pageNumber) {
    return 'No se pudo cargar la página $pageNumber';
  }

  @override
  String get readerNoPages => 'Capítulo sin páginas';

  @override
  String get readerErrorGeneric => 'Algo salió mal al cargar el capítulo.';

  @override
  String get cleanupRequiresRecentLogin =>
      'Vuelve a iniciar sesión para completar la eliminación.';

  @override
  String get cleanupFirebaseDeleteFailed =>
      'No se pudo eliminar tu cuenta de Firebase. Intenta de nuevo.';

  @override
  String get cleanupReauthWrongPassword => 'Contraseña incorrecta.';

  @override
  String get cleanupReauthUserMismatch =>
      'El usuario no coincide con la sesión actual.';

  @override
  String get cleanupReauthInvalidCredential => 'Credencial inválida.';

  @override
  String get cleanupReauthTooManyRequests =>
      'Demasiados intentos. Espera un momento e intenta de nuevo.';

  @override
  String get cleanupReauthAuthError => 'Error de autenticación.';

  @override
  String get cleanupPrefsClearWarning =>
      'No se pudieron eliminar algunos datos locales.';

  @override
  String get cleanupSessionExpired =>
      'Tu sesión expiró. Inicia sesión nuevamente e intenta de nuevo.';

  @override
  String get deleteAccountGenericError =>
      'No se pudo eliminar la cuenta. Intenta de nuevo.';

  @override
  String get authSessionVerificationFailed =>
      'No se pudo verificar la sesión. Inicia sesión nuevamente.';

  @override
  String get authInvalidCredentials => 'Email o contraseña inválidos.';

  @override
  String get authEmailAlreadyInUse => 'Este email ya está registrado.';

  @override
  String get authWeakPassword =>
      'La contraseña es muy débil. Usa al menos 6 caracteres.';

  @override
  String get authTooManyRequests =>
      'Demasiados intentos. Espera e intenta de nuevo.';

  @override
  String get authNetworkError => 'Sin conexión a internet. Verifica tu red.';

  @override
  String get authUnknownError => 'Error de autenticación. Intenta de nuevo.';

  @override
  String get authEmailNotVerified =>
      'Verifica tu email antes de iniciar sesión. Revisa tu bandeja de entrada y haz clic en el link de verificación.';

  @override
  String get authVerifyEmailTitle => 'Verifica tu email';

  @override
  String authVerifyEmailBody(String email) {
    return 'Enviamos un link de verificación a $email. Haz clic en el link del email para activar tu cuenta.';
  }

  @override
  String get authVerifyEmailSent => '✅ Email de verificación enviado';

  @override
  String get authVerifyEmailContinue => 'Ya verifiqué — continuar';

  @override
  String get authVerifyEmailResend => 'Reenviar email de verificación';

  @override
  String get authVerifyEmailWait => 'Espera un momento antes de reenviar';

  @override
  String get authVerifyEmailDifferentEmail => 'Usar otro email';

  @override
  String get authVerifyEmailSuccess =>
      '¡Email verificado! Bienvenido/a a InkScroller.';

  @override
  String get authVerifyEmailNotYet =>
      'Tu email todavía no fue verificado. Revisa tu bandeja de entrada y haz clic en el link.';

  @override
  String get authVerifyEmailResent => 'Email de verificación reenviado.';

  @override
  String get authVerifyInProfile => 'Verificar email';

  @override
  String get authVerifyInProfileSubtitle => 'Cuenta sin verificar';

  @override
  String get libraryErrorNetworkNoConnection =>
      'No se pudo conectar con el servidor.';

  @override
  String get libraryErrorServerBadResponse =>
      'El servidor respondió con un error.';

  @override
  String get libraryErrorRequestCancelled => 'La solicitud fue cancelada.';

  @override
  String get libraryErrorInvalidCertificate => 'Certificado inválido.';

  @override
  String get libraryErrorNetworkUnknown =>
      'Ocurrió un error de red inesperado.';

  @override
  String get libraryErrorEmptyResponse =>
      'El servidor devolvió una respuesta vacía.';

  @override
  String get libraryErrorExternalChapter =>
      'Este capítulo solo está disponible en el sitio original.';

  @override
  String get aboutTitle => 'Sobre la app';

  @override
  String aboutVersion(String version, String build) {
    return 'Versión $version (Build $build)';
  }

  @override
  String get aboutAppDescription => 'Lector de manga personal — código abierto';

  @override
  String get aboutDisclaimerTitle => 'AVISO LEGAL';

  @override
  String get aboutDisclaimerMangadexTitle => 'Sin afiliación a MangaDex';

  @override
  String aboutDisclaimerMangadexBody(String appName) {
    return '$appName no está afiliado, asociado, autorizado ni respaldado por MangaDex. El nombre \"MangaDex\" y su logotipo son marcas de sus respectivos propietarios. El uso de la API pública de MangaDex se realiza bajo sus Términos de Uso.';
  }

  @override
  String get aboutDisclaimerMalTitle => 'Sin afiliación a MyAnimeList';

  @override
  String aboutDisclaimerMalBody(String appName) {
    return '$appName no está afiliado, asociado, autorizado ni respaldado por MyAnimeList (MAL). El nombre \"MyAnimeList\" y su logotipo son marcas de sus respectivos propietarios. Los metadatos adicionales se obtienen a través de la API pública de Jikan, una API no oficial de MAL, y se usan únicamente con fines informativos.';
  }

  @override
  String get aboutDisclaimerCopyrightTitle => 'Derechos de autor del contenido';

  @override
  String aboutDisclaimerCopyrightBody(String appName) {
    return 'Todo el contenido de manga (imágenes, capítulos, portadas) pertenece a sus respectivos autores y editores. $appName no almacena ni redistribuye contenido con derechos de autor. Esta app solo consume datos de APIs públicas de terceros.';
  }

  @override
  String get aboutCreditsTitle => 'CRÉDITOS Y APIs';

  @override
  String get aboutCreditMangadexDescription => 'Catálogo, capítulos y portadas';

  @override
  String get aboutCreditJikanDescription => 'Metadatos adicionales (MAL)';

  @override
  String get aboutCreditInfrastructureDescription =>
      'Infraestructura de backend';

  @override
  String get aboutCreditFirebaseDescription => 'Autenticación de usuarios';

  @override
  String get profileContentRatingTitle => 'Clasificación de contenido';

  @override
  String get profileContentRatingSafe => 'Seguro';

  @override
  String get profileContentRatingSuggestive => 'Seguro + Sugestivo';

  @override
  String get profileContentRatingAll => 'Todo';

  @override
  String get profileBirthDateRequired =>
      'Completa tu perfil con una fecha de nacimiento para cambiar tu nombre de usuario.';

  @override
  String get chaptersSortAsc => 'Número ↑';

  @override
  String get chaptersSortDesc => 'Número ↓';

  @override
  String get chaptersFilterAll => 'Todos los capítulos';

  @override
  String get chaptersFilterUnread => 'Solo no leídos';

  @override
  String get markAsRead => 'Marcar como leído';

  @override
  String get markAsUnread => 'Marcar como no leído';

  @override
  String get chaptersFilteredOut => 'Ningún capítulo coincide con el filtro';

  @override
  String get authForgotPasswordLink => '¿Olvidaste tu contraseña?';

  @override
  String get authForgotPasswordTitle => 'Restablecer contraseña';

  @override
  String get authForgotPasswordSend => 'Enviar email de recuperación';

  @override
  String get authResetPasswordSent =>
      'Email de recuperación enviado. Revisa tu bandeja de entrada.';

  @override
  String get authResetPasswordButton => 'Restablecer contraseña';

  @override
  String get authChangeUsernameOption => 'Cambiar nombre de usuario';

  @override
  String get authChangeUsernameTitle => 'Cambiar nombre de usuario';

  @override
  String get authChangeUsernameSave => 'Guardar';

  @override
  String get authChangeUsernameSuccess =>
      'Nombre de usuario actualizado con éxito';

  @override
  String get readingProgressTitle => 'Progreso de lectura';

  @override
  String get manualMarkIncrease => 'Marcar uno más como leído';

  @override
  String get manualMarkDecrease => 'Desmarcar un capítulo';

  @override
  String get batchSizeLabel => 'Tamaño de lote';

  @override
  String get jumpToChapter => 'Saltar al capítulo';

  @override
  String get jumpToChapterHint => 'Número de capítulo';

  @override
  String get jumpToChapterInvalid => 'Ingresa un número de capítulo válido';

  @override
  String get placeholderMarkRead => 'Marcar como leído';

  @override
  String get placeholderUnmark => 'Marcar como no leído';

  @override
  String get noJikanData => 'No hay datos externos disponibles';

  @override
  String get noChaptersNoTracking => 'No hay capítulos disponibles';

  @override
  String get extrasTitle => 'Extras';

  @override
  String get homeHeroEmpty => 'Todavía no hay mangas destacados.';

  @override
  String get homeHeroError => 'No se pudieron cargar los mangas destacados.';

  @override
  String get homeExploreCta => 'Explorar todo →';

  @override
  String get homeContinueReading => 'Continuar leyendo';

  @override
  String get homeDiscover => 'Descubre';

  @override
  String get homeRecommended => 'Recomendado para ti';

  @override
  String get homeTrendingLabel => 'TENDENCIA';

  @override
  String get homeViewAll => 'Ver todo';

  @override
  String get homeChapterError => 'No se pudieron cargar los capítulos.';
}
