import 'dart:io';
import 'dart:ui';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:common/constants.dart';
import 'package:common/model/device.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:localsend_app/config/terminal_themes.dart';
import 'package:localsend_app/config/theme.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/color_mode.dart';
import 'package:localsend_app/model/state/settings_state.dart';
import 'package:localsend_app/pages/about/about_page.dart';
import 'package:localsend_app/pages/changelog_page.dart';
import 'package:localsend_app/pages/donation/donation_page.dart';
import 'package:localsend_app/pages/language_page.dart';
import 'package:localsend_app/pages/settings/network_interfaces_page.dart';
import 'package:localsend_app/pages/tabs/settings_tab_controller.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/provider/terminal_access_provider.dart';
import 'package:localsend_app/provider/version_provider.dart';
import 'package:localsend_app/util/alias_generator.dart';
import 'package:localsend_app/util/device_type_ext.dart';
import 'package:localsend_app/util/native/macos_channel.dart';
import 'package:localsend_app/util/native/pick_directory_path.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/widget/custom_dropdown_button.dart';
import 'package:localsend_app/widget/dialogs/encryption_disabled_notice.dart';
import 'package:localsend_app/widget/dialogs/pin_dialog.dart';
import 'package:localsend_app/widget/dialogs/quick_save_from_favorites_notice.dart';
import 'package:localsend_app/widget/dialogs/quick_save_notice.dart';
import 'package:localsend_app/widget/dialogs/text_field_tv.dart';
import 'package:localsend_app/widget/dialogs/text_field_with_actions.dart';
import 'package:localsend_app/widget/labeled_checkbox.dart';
import 'package:localsend_app/widget/local_send_logo.dart';
import 'package:localsend_app/widget/responsive_list_view.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab();

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder(
      provider: (ref) => settingsTabControllerProvider,
      builder: (context, vm) {
        final ref = context.ref;
        return Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                right: MediaQuery.of(context).padding.right,
              ), // So camera or 3-button navigation doesn't interfere on the right, rest is handled
              child: ResponsiveListView(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 40),
                children: [
                  SizedBox(height: 30 + MediaQuery.of(context).padding.top),
                  _SettingsSection(
                    title: t.settingsTab.general.title,
                    children: [
                      _SettingsEntry(
                        label: t.settingsTab.general.brightness,
                        child: CustomDropdownButton<ThemeMode>(
                          value: vm.settings.theme,
                          items: vm.themeModes.map((theme) {
                            return DropdownMenuItem(
                              value: theme,
                              alignment: Alignment.center,
                              child: Text(theme.humanName),
                            );
                          }).toList(),
                          onChanged: (theme) => vm.onChangeTheme(context, theme),
                        ),
                      ),
                      _SettingsEntry(
                        label: t.settingsTab.general.color,
                        child: CustomDropdownButton<ColorMode>(
                          value: vm.settings.colorMode,
                          items: vm.colorModes.map((colorMode) {
                            return DropdownMenuItem(
                              value: colorMode,
                              alignment: Alignment.center,
                              child: Text(colorMode.humanName),
                            );
                          }).toList(),
                          onChanged: vm.onChangeColorMode,
                        ),
                      ),
                      _ButtonEntry(
                        label: t.settingsTab.general.language,
                        buttonLabel: vm.settings.locale?.humanName ?? t.settingsTab.general.languageOptions.system,
                        onTap: () => vm.onTapLanguage(context),
                      ),
                      if (checkPlatformIsDesktop()) ...[
                        /// Wayland does window position handling, so there's no need for it. See [https://github.com/localsend/localsend/issues/544]
                        if (vm.advanced && checkPlatformIsNotWaylandDesktop())
                          _BooleanEntry(
                            label: defaultTargetPlatform == TargetPlatform.windows
                                ? t.settingsTab.general.saveWindowPlacementWindows
                                : t.settingsTab.general.saveWindowPlacement,
                            value: vm.settings.saveWindowPlacement,
                            onChanged: (b) async {
                              await ref.notifier(settingsProvider).setSaveWindowPlacement(b);
                            },
                          ),
                        if (checkPlatformHasTray()) ...[
                          _BooleanEntry(
                            label: t.settingsTab.general.minimizeToTray,
                            value: vm.settings.minimizeToTray,
                            onChanged: (b) async {
                              await ref.notifier(settingsProvider).setMinimizeToTray(b);
                            },
                          ),
                        ],
                        if (checkPlatformIsDesktop()) ...[
                          _BooleanEntry(
                            label: t.settingsTab.general.launchAtStartup,
                            value: vm.autoStart,
                            onChanged: (_) => vm.onToggleAutoStart(context),
                          ),
                          Visibility(
                            visible: vm.autoStart,
                            maintainAnimation: true,
                            maintainState: true,
                            child: AnimatedOpacity(
                              opacity: vm.autoStart ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 500),
                              child: _BooleanEntry(
                                label: t.settingsTab.general.launchMinimized,
                                value: vm.autoStartLaunchHidden,
                                onChanged: (_) => vm.onToggleAutoStartLaunchHidden(context),
                              ),
                            ),
                          ),
                        ],
                        if (vm.advanced && checkPlatform([TargetPlatform.windows])) ...[
                          _BooleanEntry(
                            label: t.settingsTab.general.showInContextMenu,
                            value: vm.showInContextMenu,
                            onChanged: (_) => vm.onToggleShowInContextMenu(context),
                          ),
                        ],
                      ],
                      _BooleanEntry(
                        label: t.settingsTab.general.animations,
                        value: vm.settings.enableAnimations,
                        onChanged: (b) async {
                          await ref.notifier(settingsProvider).setEnableAnimations(b);
                        },
                      ),
                    ],
                  ),
                  _SettingsSection(
                    title: t.settingsTab.receive.title,
                    children: [
                      _BooleanEntry(
                        label: t.settingsTab.receive.quickSave,
                        value: vm.settings.quickSave,
                        onChanged: (b) async {
                          final old = vm.settings.quickSave;
                          await ref.notifier(settingsProvider).setQuickSave(b);
                          if (!old && b && context.mounted) {
                            await QuickSaveNotice.open(context);
                          }
                        },
                      ),
                      _BooleanEntry(
                        label: t.settingsTab.receive.quickSaveFromFavorites,
                        value: vm.settings.quickSaveFromFavorites,
                        onChanged: (b) async {
                          final old = vm.settings.quickSaveFromFavorites;
                          await ref.notifier(settingsProvider).setQuickSaveFromFavorites(b);
                          if (!old && b && context.mounted) {
                            await QuickSaveFromFavoritesNotice.open(context);
                          }
                        },
                      ),
                      _BooleanEntry(
                        label: t.settingsTab.receive.requirePin,
                        value: vm.settings.receivePin != null,
                        onChanged: (b) async {
                          final currentPIN = vm.settings.receivePin;
                          if (currentPIN != null) {
                            await ref.notifier(settingsProvider).setReceivePin(null);
                          } else {
                            final String? newPin = await showDialog<String>(
                              context: context,
                              builder: (_) => const PinDialog(
                                obscureText: false,
                                generateRandom: false,
                              ),
                            );

                            if (newPin != null && newPin.isNotEmpty) {
                              await ref.notifier(settingsProvider).setReceivePin(newPin);
                            }
                          }
                        },
                      ),
                      if (checkPlatformWithFileSystem())
                        _SettingsEntry(
                          label: t.settingsTab.receive.destination,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Theme.of(context).inputDecorationTheme.fillColor,
                              shape: RoundedRectangleBorder(borderRadius: Theme.of(context).inputDecorationTheme.borderRadius),
                              foregroundColor: Theme.of(context).colorScheme.onSurface,
                            ),
                            onPressed: () async {
                              if (vm.settings.destination != null) {
                                await ref.notifier(settingsProvider).setDestination(null);
                                if (defaultTargetPlatform == TargetPlatform.macOS) {
                                  await removeExistingDestinationAccess();
                                }
                                return;
                              }

                              final directory = await pickDirectoryPath();
                              if (directory != null) {
                                if (defaultTargetPlatform == TargetPlatform.macOS) {
                                  await persistDestinationFolderAccess(directory);
                                }
                                await ref.notifier(settingsProvider).setDestination(directory);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Text(vm.settings.destination ?? t.settingsTab.receive.downloads, style: Theme.of(context).textTheme.titleMedium),
                            ),
                          ),
                        ),
                      if (checkPlatformWithGallery())
                        _BooleanEntry(
                          label: t.settingsTab.receive.saveToGallery,
                          value: vm.settings.saveToGallery,
                          onChanged: (b) async {
                            await ref.notifier(settingsProvider).setSaveToGallery(b);
                          },
                        ),
                      _BooleanEntry(
                        label: t.settingsTab.receive.autoFinish,
                        value: vm.settings.autoFinish,
                        onChanged: (b) async {
                          await ref.notifier(settingsProvider).setAutoFinish(b);
                        },
                      ),
                      _BooleanEntry(
                        label: t.settingsTab.receive.saveToHistory,
                        value: vm.settings.saveToHistory,
                        onChanged: (b) async {
                          await ref.notifier(settingsProvider).setSaveToHistory(b);
                        },
                      ),
                    ],
                  ),
                  if (vm.advanced)
                    _SettingsSection(
                      title: t.settingsTab.send.title,
                      children: [
                        _BooleanEntry(
                          label: t.settingsTab.send.shareViaLinkAutoAccept,
                          value: vm.settings.shareViaLinkAutoAccept,
                          onChanged: (b) async {
                            await ref.notifier(settingsProvider).setShareViaLinkAutoAccept(b);
                          },
                        ),
                      ],
                    ),
                  _SettingsSection(
                    title: t.settingsTab.network.title,
                    children: [
                      AnimatedCrossFade(
                        crossFadeState:
                            vm.serverState != null &&
                                (vm.serverState!.alias != vm.settings.alias ||
                                    vm.serverState!.port != vm.settings.port ||
                                    vm.serverState!.https != vm.settings.https)
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 200),
                        alignment: Alignment.topLeft,
                        firstChild: Container(),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: Text(t.settingsTab.network.needRestart, style: TextStyle(color: Theme.of(context).colorScheme.warning)),
                        ),
                      ),
                      _SettingsEntry(
                        label: '${t.settingsTab.network.server}${vm.serverState == null ? ' (${t.general.offline})' : ''}',
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).inputDecorationTheme.fillColor,
                            borderRadius: Theme.of(context).inputDecorationTheme.borderRadius,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (vm.serverState == null)
                                Tooltip(
                                  message: t.general.start,
                                  child: TextButton(
                                    style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurface),
                                    onPressed: () => vm.onTapStartServer(context),
                                    child: const Icon(Icons.play_arrow),
                                  ),
                                )
                              else
                                Tooltip(
                                  message: t.general.restart,
                                  child: TextButton(
                                    style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurface),
                                    onPressed: () => vm.onTapRestartServer(context),
                                    child: const Icon(Icons.refresh),
                                  ),
                                ),
                              Tooltip(
                                message: t.general.stop,
                                child: TextButton(
                                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurface),
                                  onPressed: vm.serverState == null ? null : vm.onTapStopServer,
                                  child: const Icon(Icons.stop),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _SettingsEntry(
                        label: t.settingsTab.network.alias,
                        child: TextFieldWithActions(
                          name: t.settingsTab.network.alias,
                          controller: vm.aliasController,
                          onChanged: (s) async {
                            await ref.notifier(settingsProvider).setAlias(s);
                          },
                          actions: [
                            Tooltip(
                              message: t.settingsTab.network.generateRandomAlias,
                              child: IconButton(
                                onPressed: () async {
                                  // Generates random alias
                                  final newAlias = generateRandomAlias();

                                  // Update the TextField with the new alias
                                  vm.aliasController.text = newAlias;

                                  // Persist the new alias using the settingsProvider
                                  await ref.notifier(settingsProvider).setAlias(newAlias);
                                },
                                icon: const Icon(Icons.casino),
                              ),
                            ),
                            Tooltip(
                              message: t.settingsTab.network.useSystemName,
                              child: IconButton(
                                onPressed: () async {
                                  final String newAlias;
                                  if (Platform.isMacOS) {
                                    final result = await Process.run('scutil', ['--get', 'ComputerName']);
                                    newAlias = result.stdout.toString().trim();
                                  } else {
                                    newAlias = Platform.localHostname;
                                  }

                                  vm.aliasController.text = newAlias;
                                  await ref.notifier(settingsProvider).setAlias(newAlias);
                                },
                                icon: const Icon(Icons.desktop_windows_rounded),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (vm.advanced)
                        _SettingsEntry(
                          label: t.settingsTab.network.deviceType,
                          child: CustomDropdownButton<DeviceType>(
                            value: vm.deviceInfo.deviceType,
                            items: DeviceType.values.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                alignment: Alignment.center,
                                child: Icon(type.icon),
                              );
                            }).toList(),
                            onChanged: (type) async {
                              await ref.notifier(settingsProvider).setDeviceType(type);
                            },
                          ),
                        ),
                      if (vm.advanced)
                        _SettingsEntry(
                          label: t.settingsTab.network.deviceModel,
                          child: TextFieldTv(
                            name: t.settingsTab.network.deviceModel,
                            controller: vm.deviceModelController,
                            onChanged: (s) async {
                              await ref.notifier(settingsProvider).setDeviceModel(s);
                            },
                          ),
                        ),
                      if (vm.advanced)
                        _SettingsEntry(
                          label: t.settingsTab.network.port,
                          child: TextFieldTv(
                            name: t.settingsTab.network.port,
                            controller: vm.portController,
                            onChanged: (s) async {
                              final port = int.tryParse(s);
                              if (port != null) {
                                await ref.notifier(settingsProvider).setPort(port);
                              }
                            },
                          ),
                        ),
                      if (vm.advanced)
                        _ButtonEntry(
                          label: t.settingsTab.network.network,
                          buttonLabel: switch (vm.settings.networkWhitelist != null || vm.settings.networkBlacklist != null) {
                            true => t.settingsTab.network.networkOptions.filtered,
                            false => t.settingsTab.network.networkOptions.all,
                          },
                          onTap: () async {
                            await context.push(() => const NetworkInterfacesPage());
                          },
                        ),
                      if (vm.advanced)
                        _SettingsEntry(
                          label: t.settingsTab.network.discoveryTimeout,
                          child: TextFieldTv(
                            name: t.settingsTab.network.discoveryTimeout,
                            controller: vm.timeoutController,
                            onChanged: (s) async {
                              final timeout = int.tryParse(s);
                              if (timeout != null) {
                                await ref.notifier(settingsProvider).setDiscoveryTimeout(timeout);
                              }
                            },
                          ),
                        ),
                      if (vm.advanced)
                        _BooleanEntry(
                          label: t.settingsTab.network.encryption,
                          value: vm.settings.https,
                          onChanged: (b) async {
                            final old = vm.settings.https;
                            await ref.notifier(settingsProvider).setHttps(b);
                            if (old && !b && context.mounted) {
                              await EncryptionDisabledNotice.open(context);
                            }
                          },
                        ),
                      if (vm.advanced)
                        _SettingsEntry(
                          label: t.settingsTab.network.multicastGroup,
                          child: TextFieldTv(
                            name: t.settingsTab.network.multicastGroup,
                            controller: vm.multicastController,
                            onChanged: (s) async {
                              await ref.notifier(settingsProvider).setMulticastGroup(s);
                            },
                          ),
                        ),
                      AnimatedCrossFade(
                        crossFadeState: vm.settings.port != defaultPort ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 200),
                        alignment: Alignment.topLeft,
                        firstChild: Container(),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: Text(
                            t.settingsTab.network.portWarning(defaultPort: defaultPort),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      AnimatedCrossFade(
                        crossFadeState: vm.settings.multicastGroup != defaultMulticastGroup ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 200),
                        alignment: Alignment.topLeft,
                        firstChild: Container(),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: Text(
                            t.settingsTab.network.multicastGroupWarning(defaultMulticast: defaultMulticastGroup),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _SettingsSection(
                    title: 'Terminal',
                    children: [
                      if (checkPlatformIsDesktop())
                        _SettingsEntry(
                          label: 'Default Shell',
                          child: CustomDropdownButton<String>(
                            value: vm.settings.terminalDefaultShell ?? 'System Default',
                            items: [
                              'System Default',
                              if (checkPlatform([TargetPlatform.windows])) ...[
                                'powershell.exe',
                                'cmd.exe',
                              ] else ...[
                                '/bin/zsh',
                                '/bin/bash',
                              ],
                            ].map((shell) {
                              return DropdownMenuItem(
                                value: shell,
                                alignment: Alignment.center,
                                child: Text(shell),
                              );
                            }).toList(),
                            onChanged: (value) async {
                              await ref.notifier(settingsProvider).setTerminalDefaultShell(
                                value == 'System Default' ? null : value,
                              );
                            },
                          ),
                        ),
                      _SettingsEntry(
                        label: 'Font Size',
                        child: TextFieldTv(
                          name: 'Font Size',
                          controller: TextEditingController(text: vm.settings.terminalFontSize.toString()),
                          onChanged: (s) async {
                            final size = double.tryParse(s);
                            if (size != null) {
                              await ref.notifier(settingsProvider).setTerminalFontSize(size);
                            }
                          },
                        ),
                      ),
                      _SettingsEntry(
                        label: 'Font Family',
                        child: CustomDropdownButton<String>(
                          value: vm.settings.terminalFontFamily,
                          items: [
                            'JetBrains Mono',
                            'Fira Code',
                            'Source Code Pro',
                            'Menlo',
                            'Courier New',
                          ].map((font) {
                            return DropdownMenuItem(
                              value: font,
                              alignment: Alignment.center,
                              child: Text(font, style: TextStyle(fontFamily: font)),
                            );
                          }).toList(),
                          onChanged: (value) async {
                            await ref.notifier(settingsProvider).setTerminalFontFamily(value);
                          },
                        ),
                      ),
                      _SettingsEntry(
                        label: 'Theme',
                        child: CustomDropdownButton<String>(
                          value: vm.settings.terminalTheme,
                          items: ClouseauTerminalThemes.themeNames.map((themeName) {
                            final themeData = ClouseauTerminalThemes.getTheme(themeName);
                            return DropdownMenuItem(
                              value: themeName,
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: themeData.background,
                                      border: Border.all(color: themeData.foreground, width: 1.5),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: themeData.foreground,
                                          borderRadius: BorderRadius.circular(1),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(themeName),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) async {
                            await ref.notifier(settingsProvider).setTerminalTheme(value);
                          },
                        ),
                      ),
                      _SettingsEntry(
                        label: 'Scrollback Lines',
                        child: TextFieldTv(
                          name: 'Scrollback Lines',
                          controller: TextEditingController(text: vm.settings.terminalScrollbackLines.toString()),
                          onChanged: (s) async {
                            final lines = int.tryParse(s);
                            if (lines != null) {
                              await ref.notifier(settingsProvider).setTerminalScrollbackLines(lines);
                            }
                          },
                        ),
                      ),
                      _BooleanEntry(
                        label: 'Allow Remote Access',
                        value: vm.settings.terminalAllowRemoteAccess,
                        onChanged: (b) async {
                          await ref.notifier(settingsProvider).setTerminalAllowRemoteAccess(b);
                        },
                      ),
                      _BooleanEntry(
                        label: 'Require PIN',
                        value: vm.settings.terminalRequirePin,
                        onChanged: (b) async {
                          await ref.notifier(settingsProvider).setTerminalRequirePin(b);
                        },
                      ),
                    ],
                  ),
                  _TerminalSecuritySection(settings: vm.settings),
                  _SettingsSection(
                    title: t.settingsTab.other.title,
                    padding: const EdgeInsets.only(bottom: 0),
                    children: [
                      _ButtonEntry(
                        label: t.aboutPage.title,
                        buttonLabel: t.general.open,
                        onTap: () async {
                          await context.push(() => const AboutPage());
                        },
                      ),
                      _ButtonEntry(
                        label: t.settingsTab.other.support,
                        buttonLabel: t.settingsTab.other.donate,
                        onTap: () async {
                          await context.push(() => const DonationPage());
                        },
                      ),
                      _ButtonEntry(
                        label: t.settingsTab.other.privacyPolicy,
                        buttonLabel: t.general.open,
                        onTap: () async {
                          await launchUrl(
                            Uri.parse('https://localsend.org/privacy'),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                      if (checkPlatform([TargetPlatform.iOS, TargetPlatform.macOS]))
                        _ButtonEntry(
                          label: t.settingsTab.other.termsOfUse,
                          buttonLabel: t.general.open,
                          onTap: () async {
                            await launchUrl(
                              Uri.parse('https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                        ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      LabeledCheckbox(
                        label: t.settingsTab.advancedSettings,
                        value: vm.advanced,
                        labelFirst: true,
                        onChanged: (b) async {
                          vm.onTapAdvanced(b == true);
                          await ref.notifier(settingsProvider).setAdvancedSettingsEnabled(b == true);
                        },
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const LocalSendLogo(withText: true),
                  const SizedBox(height: 5),
                  ref
                      .watch(versionProvider)
                      .maybeWhen(
                        data: (version) => Text(
                          'Version: $version',
                          textAlign: TextAlign.center,
                        ),
                        orElse: () => Container(),
                      ),
                  Text(
                    '© ${DateTime.now().year} Tien Do Nam',
                    textAlign: TextAlign.center,
                  ),
                  Center(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: () async {
                        await context.push(() => const ChangelogPage());
                      },
                      icon: const Icon(Icons.history),
                      label: Text(t.changelogPage.title),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
            // a pseudo appbar that is draggable for the settings page
            SizedBox(
              height: 50 + MediaQuery.of(context).padding.top,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 20.0,
                    sigmaY: 20.0,
                  ),
                  child: MoveWindow(
                    child: SafeArea(
                      child: Container(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(t.settingsTab.title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsEntry extends StatelessWidget {
  final String label;
  final Widget child;

  const _SettingsEntry({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Expanded(
            child: Text(label),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 150,
            child: child,
          ),
        ],
      ),
    );
  }
}

/// A specialized version of [_SettingsEntry].
class _BooleanEntry extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _BooleanEntry({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SettingsEntry(
      label: label,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: theme.inputDecorationTheme.fillColor,
              borderRadius: theme.inputDecorationTheme.borderRadius,
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: theme.colorScheme.primary,
                activeThumbColor: theme.colorScheme.onPrimary,
                inactiveThumbColor: theme.colorScheme.outline,
                inactiveTrackColor: theme.colorScheme.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A specialized version of [_SettingsEntry].
class _ButtonEntry extends StatelessWidget {
  final String label;
  final String buttonLabel;
  final void Function() onTap;

  const _ButtonEntry({
    required this.label,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsEntry(
      label: label,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: Theme.of(context).inputDecorationTheme.fillColor,
          shape: RoundedRectangleBorder(borderRadius: Theme.of(context).inputDecorationTheme.borderRadius),
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
        onPressed: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Text(
            buttonLabel,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _TerminalSecuritySection extends StatefulWidget {
  final SettingsState settings;

  const _TerminalSecuritySection({required this.settings});

  @override
  State<_TerminalSecuritySection> createState() => _TerminalSecuritySectionState();
}

class _TerminalSecuritySectionState extends State<_TerminalSecuritySection> {
  late final TextEditingController _pinController;
  bool _pinVisible = false;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController(text: widget.settings.terminalPin ?? '');
  }

  @override
  void didUpdateWidget(_TerminalSecuritySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.terminalPin != widget.settings.terminalPin) {
      final newPin = widget.settings.terminalPin ?? '';
      if (_pinController.text != newPin) {
        _pinController.text = newPin;
      }
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = context.ref;
    final settings = widget.settings;
    final terminalAccess = ref.watch(terminalAccessProvider);
    final pairedDevices = terminalAccess.pairedDevices;
    final theme = Theme.of(context);

    return _SettingsSection(
      title: 'Terminal Security',
      children: [
        _BooleanEntry(
          label: 'Require device pairing',
          value: settings.terminalRequirePairing,
          onChanged: (b) async {
            await ref.notifier(settingsProvider).setTerminalRequirePairing(b);
          },
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Text(
            'Only paired devices can access your terminals',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
          ),
        ),
        _BooleanEntry(
          label: 'Require approval for each session',
          value: settings.terminalRequireApproval,
          onChanged: (b) async {
            await ref.notifier(settingsProvider).setTerminalRequireApproval(b);
          },
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Text(
            "You'll be asked before a device can view a terminal",
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Access PIN'),
                    const SizedBox(height: 2),
                    Text(
                      'Devices must enter this PIN to access terminals',
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 150,
                child: TextField(
                  controller: _pinController,
                  obscureText: !_pinVisible,
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z]')),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Leave empty for no PIN',
                    hintStyle: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                    counterText: '',
                    filled: true,
                    fillColor: theme.inputDecorationTheme.fillColor,
                    border: OutlineInputBorder(
                      borderRadius: theme.inputDecorationTheme.borderRadius,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _pinVisible ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _pinVisible = !_pinVisible;
                        });
                      },
                    ),
                  ),
                  onChanged: (value) async {
                    await ref.notifier(settingsProvider).setTerminalPin(value.isEmpty ? null : value);
                  },
                ),
              ),
            ],
          ),
        ),
        _SettingsEntry(
          label: 'Maximum viewers per session',
          child: CustomDropdownButton<int>(
            value: settings.terminalMaxViewers,
            items: [1, 2, 3, 5, 10].map((count) {
              return DropdownMenuItem(
                value: count,
                alignment: Alignment.center,
                child: Text('$count'),
              );
            }).toList(),
            onChanged: (value) async {
              await ref.notifier(settingsProvider).setTerminalMaxViewers(value);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Text(
                'Paired Devices',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(width: 8),
              Text(
                '(${pairedDevices.length} ${pairedDevices.length == 1 ? 'device' : 'devices'})',
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
              ),
            ],
          ),
        ),
        if (pairedDevices.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Text(
              'No paired devices',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontStyle: FontStyle.italic),
            ),
          )
        else
          ...pairedDevices.map((device) {
            final truncatedFingerprint = device.fingerprint.length > 12
                ? '${device.fingerprint.substring(0, 12)}...'
                : device.fingerprint;
            final formattedDate = DateFormat.yMMMd().format(device.pairedAt);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: theme.inputDecorationTheme.borderRadius,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(device.alias, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            truncatedFingerprint,
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5), fontFamily: 'monospace'),
                          ),
                          Text(
                            formattedDate,
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      onPressed: () {
                        ref.redux(terminalAccessProvider).dispatchAsync(UnpairDeviceAction(device.fingerprint));
                      },
                      child: const Text('Unpair'),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 7),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsets padding;

  const _SettingsSection({
    required this.title,
    required this.children,
    this.padding = const EdgeInsets.only(bottom: 15),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

extension on ThemeMode {
  String get humanName {
    switch (this) {
      case ThemeMode.system:
        return t.settingsTab.general.brightnessOptions.system;
      case ThemeMode.light:
        return t.settingsTab.general.brightnessOptions.light;
      case ThemeMode.dark:
        return t.settingsTab.general.brightnessOptions.dark;
    }
  }
}

extension on ColorMode {
  String get humanName {
    return switch (this) {
      ColorMode.system => t.settingsTab.general.colorOptions.system,
      ColorMode.localsend => t.appName,
      ColorMode.oled => t.settingsTab.general.colorOptions.oled,
      ColorMode.yaru => 'Yaru',
    };
  }
}
