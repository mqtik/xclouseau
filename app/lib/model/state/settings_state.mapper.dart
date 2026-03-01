// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'settings_state.dart';

class SettingsStateMapper extends ClassMapperBase<SettingsState> {
  SettingsStateMapper._();

  static SettingsStateMapper? _instance;
  static SettingsStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SettingsStateMapper._());
      DeviceTypeMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SettingsState';

  static String _$showToken(SettingsState v) => v.showToken;
  static const Field<SettingsState, String> _f$showToken = Field(
    'showToken',
    _$showToken,
  );
  static String _$alias(SettingsState v) => v.alias;
  static const Field<SettingsState, String> _f$alias = Field('alias', _$alias);
  static ThemeMode _$theme(SettingsState v) => v.theme;
  static const Field<SettingsState, ThemeMode> _f$theme = Field(
    'theme',
    _$theme,
  );
  static ColorMode _$colorMode(SettingsState v) => v.colorMode;
  static const Field<SettingsState, ColorMode> _f$colorMode = Field(
    'colorMode',
    _$colorMode,
  );
  static AppLocale? _$locale(SettingsState v) => v.locale;
  static const Field<SettingsState, AppLocale> _f$locale = Field(
    'locale',
    _$locale,
  );
  static int _$port(SettingsState v) => v.port;
  static const Field<SettingsState, int> _f$port = Field('port', _$port);
  static List<String>? _$networkWhitelist(SettingsState v) =>
      v.networkWhitelist;
  static const Field<SettingsState, List<String>> _f$networkWhitelist = Field(
    'networkWhitelist',
    _$networkWhitelist,
  );
  static List<String>? _$networkBlacklist(SettingsState v) =>
      v.networkBlacklist;
  static const Field<SettingsState, List<String>> _f$networkBlacklist = Field(
    'networkBlacklist',
    _$networkBlacklist,
  );
  static String _$multicastGroup(SettingsState v) => v.multicastGroup;
  static const Field<SettingsState, String> _f$multicastGroup = Field(
    'multicastGroup',
    _$multicastGroup,
  );
  static String? _$destination(SettingsState v) => v.destination;
  static const Field<SettingsState, String> _f$destination = Field(
    'destination',
    _$destination,
  );
  static bool _$saveToGallery(SettingsState v) => v.saveToGallery;
  static const Field<SettingsState, bool> _f$saveToGallery = Field(
    'saveToGallery',
    _$saveToGallery,
  );
  static bool _$saveToHistory(SettingsState v) => v.saveToHistory;
  static const Field<SettingsState, bool> _f$saveToHistory = Field(
    'saveToHistory',
    _$saveToHistory,
  );
  static bool _$quickSave(SettingsState v) => v.quickSave;
  static const Field<SettingsState, bool> _f$quickSave = Field(
    'quickSave',
    _$quickSave,
  );
  static bool _$quickSaveFromFavorites(SettingsState v) =>
      v.quickSaveFromFavorites;
  static const Field<SettingsState, bool> _f$quickSaveFromFavorites = Field(
    'quickSaveFromFavorites',
    _$quickSaveFromFavorites,
  );
  static String? _$receivePin(SettingsState v) => v.receivePin;
  static const Field<SettingsState, String> _f$receivePin = Field(
    'receivePin',
    _$receivePin,
  );
  static bool _$autoFinish(SettingsState v) => v.autoFinish;
  static const Field<SettingsState, bool> _f$autoFinish = Field(
    'autoFinish',
    _$autoFinish,
  );
  static bool _$minimizeToTray(SettingsState v) => v.minimizeToTray;
  static const Field<SettingsState, bool> _f$minimizeToTray = Field(
    'minimizeToTray',
    _$minimizeToTray,
  );
  static bool _$https(SettingsState v) => v.https;
  static const Field<SettingsState, bool> _f$https = Field('https', _$https);
  static SendMode _$sendMode(SettingsState v) => v.sendMode;
  static const Field<SettingsState, SendMode> _f$sendMode = Field(
    'sendMode',
    _$sendMode,
  );
  static bool _$saveWindowPlacement(SettingsState v) => v.saveWindowPlacement;
  static const Field<SettingsState, bool> _f$saveWindowPlacement = Field(
    'saveWindowPlacement',
    _$saveWindowPlacement,
  );
  static bool _$enableAnimations(SettingsState v) => v.enableAnimations;
  static const Field<SettingsState, bool> _f$enableAnimations = Field(
    'enableAnimations',
    _$enableAnimations,
  );
  static DeviceType? _$deviceType(SettingsState v) => v.deviceType;
  static const Field<SettingsState, DeviceType> _f$deviceType = Field(
    'deviceType',
    _$deviceType,
  );
  static String? _$deviceModel(SettingsState v) => v.deviceModel;
  static const Field<SettingsState, String> _f$deviceModel = Field(
    'deviceModel',
    _$deviceModel,
  );
  static bool _$shareViaLinkAutoAccept(SettingsState v) =>
      v.shareViaLinkAutoAccept;
  static const Field<SettingsState, bool> _f$shareViaLinkAutoAccept = Field(
    'shareViaLinkAutoAccept',
    _$shareViaLinkAutoAccept,
  );
  static int _$discoveryTimeout(SettingsState v) => v.discoveryTimeout;
  static const Field<SettingsState, int> _f$discoveryTimeout = Field(
    'discoveryTimeout',
    _$discoveryTimeout,
  );
  static bool _$advancedSettings(SettingsState v) => v.advancedSettings;
  static const Field<SettingsState, bool> _f$advancedSettings = Field(
    'advancedSettings',
    _$advancedSettings,
  );
  static String? _$terminalDefaultShell(SettingsState v) =>
      v.terminalDefaultShell;
  static const Field<SettingsState, String> _f$terminalDefaultShell = Field(
    'terminalDefaultShell',
    _$terminalDefaultShell,
    opt: true,
  );
  static double _$terminalFontSize(SettingsState v) => v.terminalFontSize;
  static const Field<SettingsState, double> _f$terminalFontSize = Field(
    'terminalFontSize',
    _$terminalFontSize,
    opt: true,
    def: 14.0,
  );
  static String _$terminalFontFamily(SettingsState v) => v.terminalFontFamily;
  static const Field<SettingsState, String> _f$terminalFontFamily = Field(
    'terminalFontFamily',
    _$terminalFontFamily,
    opt: true,
    def: 'JetBrains Mono',
  );
  static String _$terminalTheme(SettingsState v) => v.terminalTheme;
  static const Field<SettingsState, String> _f$terminalTheme = Field(
    'terminalTheme',
    _$terminalTheme,
    opt: true,
    def: 'dark',
  );
  static int _$terminalScrollbackLines(SettingsState v) =>
      v.terminalScrollbackLines;
  static const Field<SettingsState, int> _f$terminalScrollbackLines = Field(
    'terminalScrollbackLines',
    _$terminalScrollbackLines,
    opt: true,
    def: 10000,
  );
  static bool _$terminalAllowRemoteAccess(SettingsState v) =>
      v.terminalAllowRemoteAccess;
  static const Field<SettingsState, bool> _f$terminalAllowRemoteAccess = Field(
    'terminalAllowRemoteAccess',
    _$terminalAllowRemoteAccess,
    opt: true,
    def: true,
  );
  static bool _$terminalRequirePin(SettingsState v) => v.terminalRequirePin;
  static const Field<SettingsState, bool> _f$terminalRequirePin = Field(
    'terminalRequirePin',
    _$terminalRequirePin,
    opt: true,
    def: false,
  );
  static bool _$terminalAllowWebPreview(SettingsState v) =>
      v.terminalAllowWebPreview;
  static const Field<SettingsState, bool> _f$terminalAllowWebPreview = Field(
    'terminalAllowWebPreview',
    _$terminalAllowWebPreview,
    opt: true,
    def: true,
  );
  static bool _$terminalRequireApproval(SettingsState v) =>
      v.terminalRequireApproval;
  static const Field<SettingsState, bool> _f$terminalRequireApproval = Field(
    'terminalRequireApproval',
    _$terminalRequireApproval,
    opt: true,
    def: true,
  );
  static String? _$terminalPin(SettingsState v) => v.terminalPin;
  static const Field<SettingsState, String> _f$terminalPin = Field(
    'terminalPin',
    _$terminalPin,
    opt: true,
  );
  static int _$terminalMaxViewers(SettingsState v) => v.terminalMaxViewers;
  static const Field<SettingsState, int> _f$terminalMaxViewers = Field(
    'terminalMaxViewers',
    _$terminalMaxViewers,
    opt: true,
    def: 5,
  );
  static bool _$terminalRequirePairing(SettingsState v) =>
      v.terminalRequirePairing;
  static const Field<SettingsState, bool> _f$terminalRequirePairing = Field(
    'terminalRequirePairing',
    _$terminalRequirePairing,
    opt: true,
    def: true,
  );

  @override
  final MappableFields<SettingsState> fields = const {
    #showToken: _f$showToken,
    #alias: _f$alias,
    #theme: _f$theme,
    #colorMode: _f$colorMode,
    #locale: _f$locale,
    #port: _f$port,
    #networkWhitelist: _f$networkWhitelist,
    #networkBlacklist: _f$networkBlacklist,
    #multicastGroup: _f$multicastGroup,
    #destination: _f$destination,
    #saveToGallery: _f$saveToGallery,
    #saveToHistory: _f$saveToHistory,
    #quickSave: _f$quickSave,
    #quickSaveFromFavorites: _f$quickSaveFromFavorites,
    #receivePin: _f$receivePin,
    #autoFinish: _f$autoFinish,
    #minimizeToTray: _f$minimizeToTray,
    #https: _f$https,
    #sendMode: _f$sendMode,
    #saveWindowPlacement: _f$saveWindowPlacement,
    #enableAnimations: _f$enableAnimations,
    #deviceType: _f$deviceType,
    #deviceModel: _f$deviceModel,
    #shareViaLinkAutoAccept: _f$shareViaLinkAutoAccept,
    #discoveryTimeout: _f$discoveryTimeout,
    #advancedSettings: _f$advancedSettings,
    #terminalDefaultShell: _f$terminalDefaultShell,
    #terminalFontSize: _f$terminalFontSize,
    #terminalFontFamily: _f$terminalFontFamily,
    #terminalTheme: _f$terminalTheme,
    #terminalScrollbackLines: _f$terminalScrollbackLines,
    #terminalAllowRemoteAccess: _f$terminalAllowRemoteAccess,
    #terminalRequirePin: _f$terminalRequirePin,
    #terminalAllowWebPreview: _f$terminalAllowWebPreview,
    #terminalRequireApproval: _f$terminalRequireApproval,
    #terminalPin: _f$terminalPin,
    #terminalMaxViewers: _f$terminalMaxViewers,
    #terminalRequirePairing: _f$terminalRequirePairing,
  };

  static SettingsState _instantiate(DecodingData data) {
    return SettingsState(
      showToken: data.dec(_f$showToken),
      alias: data.dec(_f$alias),
      theme: data.dec(_f$theme),
      colorMode: data.dec(_f$colorMode),
      locale: data.dec(_f$locale),
      port: data.dec(_f$port),
      networkWhitelist: data.dec(_f$networkWhitelist),
      networkBlacklist: data.dec(_f$networkBlacklist),
      multicastGroup: data.dec(_f$multicastGroup),
      destination: data.dec(_f$destination),
      saveToGallery: data.dec(_f$saveToGallery),
      saveToHistory: data.dec(_f$saveToHistory),
      quickSave: data.dec(_f$quickSave),
      quickSaveFromFavorites: data.dec(_f$quickSaveFromFavorites),
      receivePin: data.dec(_f$receivePin),
      autoFinish: data.dec(_f$autoFinish),
      minimizeToTray: data.dec(_f$minimizeToTray),
      https: data.dec(_f$https),
      sendMode: data.dec(_f$sendMode),
      saveWindowPlacement: data.dec(_f$saveWindowPlacement),
      enableAnimations: data.dec(_f$enableAnimations),
      deviceType: data.dec(_f$deviceType),
      deviceModel: data.dec(_f$deviceModel),
      shareViaLinkAutoAccept: data.dec(_f$shareViaLinkAutoAccept),
      discoveryTimeout: data.dec(_f$discoveryTimeout),
      advancedSettings: data.dec(_f$advancedSettings),
      terminalDefaultShell: data.dec(_f$terminalDefaultShell),
      terminalFontSize: data.dec(_f$terminalFontSize),
      terminalFontFamily: data.dec(_f$terminalFontFamily),
      terminalTheme: data.dec(_f$terminalTheme),
      terminalScrollbackLines: data.dec(_f$terminalScrollbackLines),
      terminalAllowRemoteAccess: data.dec(_f$terminalAllowRemoteAccess),
      terminalRequirePin: data.dec(_f$terminalRequirePin),
      terminalAllowWebPreview: data.dec(_f$terminalAllowWebPreview),
      terminalRequireApproval: data.dec(_f$terminalRequireApproval),
      terminalPin: data.dec(_f$terminalPin),
      terminalMaxViewers: data.dec(_f$terminalMaxViewers),
      terminalRequirePairing: data.dec(_f$terminalRequirePairing),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SettingsState fromJson(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SettingsState>(map);
  }

  static SettingsState deserialize(String json) {
    return ensureInitialized().decodeJson<SettingsState>(json);
  }
}

mixin SettingsStateMappable {
  String serialize() {
    return SettingsStateMapper.ensureInitialized().encodeJson<SettingsState>(
      this as SettingsState,
    );
  }

  Map<String, dynamic> toJson() {
    return SettingsStateMapper.ensureInitialized().encodeMap<SettingsState>(
      this as SettingsState,
    );
  }

  SettingsStateCopyWith<SettingsState, SettingsState, SettingsState>
  get copyWith => _SettingsStateCopyWithImpl<SettingsState, SettingsState>(
    this as SettingsState,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return SettingsStateMapper.ensureInitialized().stringifyValue(
      this as SettingsState,
    );
  }

  @override
  bool operator ==(Object other) {
    return SettingsStateMapper.ensureInitialized().equalsValue(
      this as SettingsState,
      other,
    );
  }

  @override
  int get hashCode {
    return SettingsStateMapper.ensureInitialized().hashValue(
      this as SettingsState,
    );
  }
}

extension SettingsStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SettingsState, $Out> {
  SettingsStateCopyWith<$R, SettingsState, $Out> get $asSettingsState =>
      $base.as((v, t, t2) => _SettingsStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SettingsStateCopyWith<$R, $In extends SettingsState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
  get networkWhitelist;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
  get networkBlacklist;
  $R call({
    String? showToken,
    String? alias,
    ThemeMode? theme,
    ColorMode? colorMode,
    AppLocale? locale,
    int? port,
    List<String>? networkWhitelist,
    List<String>? networkBlacklist,
    String? multicastGroup,
    String? destination,
    bool? saveToGallery,
    bool? saveToHistory,
    bool? quickSave,
    bool? quickSaveFromFavorites,
    String? receivePin,
    bool? autoFinish,
    bool? minimizeToTray,
    bool? https,
    SendMode? sendMode,
    bool? saveWindowPlacement,
    bool? enableAnimations,
    DeviceType? deviceType,
    String? deviceModel,
    bool? shareViaLinkAutoAccept,
    int? discoveryTimeout,
    bool? advancedSettings,
    String? terminalDefaultShell,
    double? terminalFontSize,
    String? terminalFontFamily,
    String? terminalTheme,
    int? terminalScrollbackLines,
    bool? terminalAllowRemoteAccess,
    bool? terminalRequirePin,
    bool? terminalAllowWebPreview,
    bool? terminalRequireApproval,
    String? terminalPin,
    int? terminalMaxViewers,
    bool? terminalRequirePairing,
  });
  SettingsStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SettingsStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SettingsState, $Out>
    implements SettingsStateCopyWith<$R, SettingsState, $Out> {
  _SettingsStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SettingsState> $mapper =
      SettingsStateMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
  get networkWhitelist => $value.networkWhitelist != null
      ? ListCopyWith(
          $value.networkWhitelist!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(networkWhitelist: v),
        )
      : null;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
  get networkBlacklist => $value.networkBlacklist != null
      ? ListCopyWith(
          $value.networkBlacklist!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(networkBlacklist: v),
        )
      : null;
  @override
  $R call({
    String? showToken,
    String? alias,
    ThemeMode? theme,
    ColorMode? colorMode,
    Object? locale = $none,
    int? port,
    Object? networkWhitelist = $none,
    Object? networkBlacklist = $none,
    String? multicastGroup,
    Object? destination = $none,
    bool? saveToGallery,
    bool? saveToHistory,
    bool? quickSave,
    bool? quickSaveFromFavorites,
    Object? receivePin = $none,
    bool? autoFinish,
    bool? minimizeToTray,
    bool? https,
    SendMode? sendMode,
    bool? saveWindowPlacement,
    bool? enableAnimations,
    Object? deviceType = $none,
    Object? deviceModel = $none,
    bool? shareViaLinkAutoAccept,
    int? discoveryTimeout,
    bool? advancedSettings,
    Object? terminalDefaultShell = $none,
    double? terminalFontSize,
    String? terminalFontFamily,
    String? terminalTheme,
    int? terminalScrollbackLines,
    bool? terminalAllowRemoteAccess,
    bool? terminalRequirePin,
    bool? terminalAllowWebPreview,
    bool? terminalRequireApproval,
    Object? terminalPin = $none,
    int? terminalMaxViewers,
    bool? terminalRequirePairing,
  }) => $apply(
    FieldCopyWithData({
      if (showToken != null) #showToken: showToken,
      if (alias != null) #alias: alias,
      if (theme != null) #theme: theme,
      if (colorMode != null) #colorMode: colorMode,
      if (locale != $none) #locale: locale,
      if (port != null) #port: port,
      if (networkWhitelist != $none) #networkWhitelist: networkWhitelist,
      if (networkBlacklist != $none) #networkBlacklist: networkBlacklist,
      if (multicastGroup != null) #multicastGroup: multicastGroup,
      if (destination != $none) #destination: destination,
      if (saveToGallery != null) #saveToGallery: saveToGallery,
      if (saveToHistory != null) #saveToHistory: saveToHistory,
      if (quickSave != null) #quickSave: quickSave,
      if (quickSaveFromFavorites != null)
        #quickSaveFromFavorites: quickSaveFromFavorites,
      if (receivePin != $none) #receivePin: receivePin,
      if (autoFinish != null) #autoFinish: autoFinish,
      if (minimizeToTray != null) #minimizeToTray: minimizeToTray,
      if (https != null) #https: https,
      if (sendMode != null) #sendMode: sendMode,
      if (saveWindowPlacement != null)
        #saveWindowPlacement: saveWindowPlacement,
      if (enableAnimations != null) #enableAnimations: enableAnimations,
      if (deviceType != $none) #deviceType: deviceType,
      if (deviceModel != $none) #deviceModel: deviceModel,
      if (shareViaLinkAutoAccept != null)
        #shareViaLinkAutoAccept: shareViaLinkAutoAccept,
      if (discoveryTimeout != null) #discoveryTimeout: discoveryTimeout,
      if (advancedSettings != null) #advancedSettings: advancedSettings,
      if (terminalDefaultShell != $none)
        #terminalDefaultShell: terminalDefaultShell,
      if (terminalFontSize != null) #terminalFontSize: terminalFontSize,
      if (terminalFontFamily != null) #terminalFontFamily: terminalFontFamily,
      if (terminalTheme != null) #terminalTheme: terminalTheme,
      if (terminalScrollbackLines != null)
        #terminalScrollbackLines: terminalScrollbackLines,
      if (terminalAllowRemoteAccess != null)
        #terminalAllowRemoteAccess: terminalAllowRemoteAccess,
      if (terminalRequirePin != null) #terminalRequirePin: terminalRequirePin,
      if (terminalAllowWebPreview != null)
        #terminalAllowWebPreview: terminalAllowWebPreview,
      if (terminalRequireApproval != null)
        #terminalRequireApproval: terminalRequireApproval,
      if (terminalPin != $none) #terminalPin: terminalPin,
      if (terminalMaxViewers != null) #terminalMaxViewers: terminalMaxViewers,
      if (terminalRequirePairing != null)
        #terminalRequirePairing: terminalRequirePairing,
    }),
  );
  @override
  SettingsState $make(CopyWithData data) => SettingsState(
    showToken: data.get(#showToken, or: $value.showToken),
    alias: data.get(#alias, or: $value.alias),
    theme: data.get(#theme, or: $value.theme),
    colorMode: data.get(#colorMode, or: $value.colorMode),
    locale: data.get(#locale, or: $value.locale),
    port: data.get(#port, or: $value.port),
    networkWhitelist: data.get(#networkWhitelist, or: $value.networkWhitelist),
    networkBlacklist: data.get(#networkBlacklist, or: $value.networkBlacklist),
    multicastGroup: data.get(#multicastGroup, or: $value.multicastGroup),
    destination: data.get(#destination, or: $value.destination),
    saveToGallery: data.get(#saveToGallery, or: $value.saveToGallery),
    saveToHistory: data.get(#saveToHistory, or: $value.saveToHistory),
    quickSave: data.get(#quickSave, or: $value.quickSave),
    quickSaveFromFavorites: data.get(
      #quickSaveFromFavorites,
      or: $value.quickSaveFromFavorites,
    ),
    receivePin: data.get(#receivePin, or: $value.receivePin),
    autoFinish: data.get(#autoFinish, or: $value.autoFinish),
    minimizeToTray: data.get(#minimizeToTray, or: $value.minimizeToTray),
    https: data.get(#https, or: $value.https),
    sendMode: data.get(#sendMode, or: $value.sendMode),
    saveWindowPlacement: data.get(
      #saveWindowPlacement,
      or: $value.saveWindowPlacement,
    ),
    enableAnimations: data.get(#enableAnimations, or: $value.enableAnimations),
    deviceType: data.get(#deviceType, or: $value.deviceType),
    deviceModel: data.get(#deviceModel, or: $value.deviceModel),
    shareViaLinkAutoAccept: data.get(
      #shareViaLinkAutoAccept,
      or: $value.shareViaLinkAutoAccept,
    ),
    discoveryTimeout: data.get(#discoveryTimeout, or: $value.discoveryTimeout),
    advancedSettings: data.get(#advancedSettings, or: $value.advancedSettings),
    terminalDefaultShell: data.get(
      #terminalDefaultShell,
      or: $value.terminalDefaultShell,
    ),
    terminalFontSize: data.get(#terminalFontSize, or: $value.terminalFontSize),
    terminalFontFamily: data.get(
      #terminalFontFamily,
      or: $value.terminalFontFamily,
    ),
    terminalTheme: data.get(#terminalTheme, or: $value.terminalTheme),
    terminalScrollbackLines: data.get(
      #terminalScrollbackLines,
      or: $value.terminalScrollbackLines,
    ),
    terminalAllowRemoteAccess: data.get(
      #terminalAllowRemoteAccess,
      or: $value.terminalAllowRemoteAccess,
    ),
    terminalRequirePin: data.get(
      #terminalRequirePin,
      or: $value.terminalRequirePin,
    ),
    terminalAllowWebPreview: data.get(
      #terminalAllowWebPreview,
      or: $value.terminalAllowWebPreview,
    ),
    terminalRequireApproval: data.get(
      #terminalRequireApproval,
      or: $value.terminalRequireApproval,
    ),
    terminalPin: data.get(#terminalPin, or: $value.terminalPin),
    terminalMaxViewers: data.get(
      #terminalMaxViewers,
      or: $value.terminalMaxViewers,
    ),
    terminalRequirePairing: data.get(
      #terminalRequirePairing,
      or: $value.terminalRequirePairing,
    ),
  );

  @override
  SettingsStateCopyWith<$R2, SettingsState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SettingsStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

