import 'package:flutter/material.dart';
import 'package:flutter_dynamic_tabs/flutter_dynamic_tabs.dart';
import 'package:flutter_dynamic_tabs/src/models/dynamic_tab_settings.dart';
import 'package:flutter_dynamic_tabs/src/modified/modified_tab_bar.dart';

class DynamicTab {
  DynamicTab({
    required this.identifier,
    required this.tabViewBuilder,
    this.tab,
    this.isDismissible = true,
    this.isFocusedOnInit = false,
    final bool isInitiallyActive = false,
    this.keepViewAlive = false,
  }) : isInitiallyActive =
            isFocusedOnInit ? isFocusedOnInit : isInitiallyActive;
  final String identifier;
  final TabBarItem? tab;
  final WidgetBuilder tabViewBuilder;
  final bool isFocusedOnInit;
  final bool isDismissible;
  final bool isInitiallyActive;
  final bool keepViewAlive;
}

class DynamicTabsWrapper extends StatefulWidget {
  const DynamicTabsWrapper({
    required this.controller,
    required this.tabs,
    required this.builder,
    this.onTabClose,
    this.tabBuilder,
    this.tabBarSettings,
    final Key? key,
    this.tabViewSettings,
  }) : super(key: key);
  final DynamicTabsController controller;
  final Future<bool> Function(String idenitifier, String? label)? onTabClose;
  final List<DynamicTab> tabs;
  final Widget Function(BuildContext context, DynamicTab tab)? tabBuilder;
  final Widget Function(
    BuildContext context,
    PreferredSizeWidget tabBar,
    Widget tabView,
  ) builder;
  final DynamicTabSettings? tabBarSettings;
  final DynamicTabViewSettings? tabViewSettings;

  @override
  _DynamicTabsWrapperState createState() => _DynamicTabsWrapperState();
}

class _DynamicTabsWrapperState extends State<DynamicTabsWrapper>
    with TickerProviderStateMixin {
  @override
  void initState() {
    widget.controller.addListener(() {
      setState(() {});
    });
    widget.controller._setTabs(widget.tabs);
    setupWidget();
    super.initState();
  }

  void setupWidget() {
    widget.controller._setState(this);
    widget.controller._onClose = widget.onTabClose ??
        (final identifier, final label) async => showDialog<bool>(
              context: context,
              builder: (final context) => AlertDialog(
                title: Text('Close ${label ?? identifier}?'),
                actions: [
                  MaterialButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: const Text('Cancel'),
                  ),
                  MaterialButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            );
  }

  @override
  Widget build(final BuildContext context) {
    final tabBar = widget.tabBarSettings ?? DynamicTabSettings();
    final tabView = widget.tabViewSettings ?? DynamicTabViewSettings();
    print(tabBar.indicatorColor);
    return widget.builder(
      context,
      ModifiedTabBar(
        key: tabBar.key,
        isScrollable: true,
        indicator: tabBar.indicator,
        indicatorSize: tabBar.indicatorSize,
        labelColor: tabBar.labelColor,
        labelPadding: tabBar.labelPadding,
        labelStyle: tabBar.labelStyle,
        unselectedLabelColor: tabBar.unselectedLabelColor,
        unselectedLabelStyle: tabBar.unselectedLabelStyle,
        automaticIndicatorColorAdjustment:
            tabBar.automaticIndicatorColorAdjustment,
        dragStartBehavior: tabBar.dragStartBehavior,
        enableFeedback: tabBar.enableFeedback,
        indicatorColor: tabBar.indicatorColor,
        indicatorPadding: tabBar.indicatorPadding,
        indicatorWeight: tabBar.indicatorWeight,
        mouseCursor: tabBar.mouseCursor,
        onTap: tabBar.onTap,
        physics: tabBar.physics,
        overlayColor: tabBar.overlayColor,
        controller: widget.controller._tabController,
        tabs:
            List.generate(widget.controller._currentTabs.length, (final index) {
          final tabData = widget.controller._currentTabs[index];
          final item = tabData.tab ?? TabBarItem();
          if (widget.tabBuilder != null) {
            return widget.tabBuilder!(context, tabData);
          } else {
            return Tab(
              iconMargin: item.iconMargin,
              height: item.height,
              icon: item.icon,
              key: item.key,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: item.childPadding ?? tabBar.childPadding,
                    child: item.child == null
                        ? Text(item.label ?? tabData.identifier)
                        : item.child!,
                  ),
                  if (tabData.isDismissible)
                    Padding(
                      padding:
                          item.closeButtonPadding ?? tabBar.closeButtonPadding,
                      child: Material(
                        // color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            widget.controller
                                .closeTab(tabData.identifier, showDialog: true);
                          },
                          onLongPress: () {
                            widget.controller.closeTab(tabData.identifier);
                          },
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.close,
                              size: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }
        }),
        onScrollControllerInit: (final value) {
          widget.controller._updateScrollController(value);
        },
      ),
      TabBarView(
        controller: widget.controller._controller,
        key: tabView.key,
        dragStartBehavior: tabView.dragStartBehavior,
        physics: tabView.physics,
        children: widget.controller._currentTabs.map(
          (final e) {
            Widget getView() {
              final view = e.tabViewBuilder.call(context);
              if (e.keepViewAlive) {
                return _KeepAliveWrapper(child: view);
              }
              return view;
            }

            return Container(
              key: ValueKey('${e.identifier}TabView'),
              child: getView(),
            );
          },
        ).toList(),
      ),
    );
  }
}

class DynamicTabsController extends ChangeNotifier {
  late Future<bool?> Function(String identifier, String? label) _onClose;
  late TickerProvider _vsync;
  late TabController _controller;

  TabController get _tabController => _controller;

  int get activeIndex => _tabController.index;

  bool get indexIsChanging => _tabController.indexIsChanging;

  int get activeLength => _tabController.length;

  String get activeIdentifier => _activeStrings[activeIndex];
  late List<DynamicTab> _tabs;
  late ScrollController _scrollController;

  void _updateScrollController(final ScrollController controller) {
    _scrollController = controller;
  }

  List<DynamicTab> get _currentTabs => _activeStrings.map(_getTab).toList();

  final List<String> _activeStrings = [];

  void _setState(final State<DynamicTabsWrapper> state) {
    _vsync = state as TickerProvider;
    var initIndex = 0;
    _forEach<DynamicTab>(_tabs, (final value) {
      if (value.isInitiallyActive || !value.isDismissible) {
        _activeStrings.add(value.identifier);
        if (value.isFocusedOnInit) {
          initIndex = _activeStrings.length - 1;
        }
      }
    });
    _controller = TabController(
      length: _activeStrings.length,
      vsync: _vsync,
      initialIndex: initIndex,
    );
  }

  // void _checkIdentifiers() {
  //   final tabStrings = _tabs.map((e) => e.identifier).toList();
  //   final tabViewStrings = _children.map((e) => e.identifier).toList();
  //   _forEach<String>(List.from(tabStrings), (value) {
  //     if (tabViewStrings.contains(value)) {
  //       tabViewStrings.remove(value);
  //       tabStrings.remove(value);
  //     }
  //   });
  //
  //   if (tabStrings.isNotEmpty) {
  //     throw Exception('TabView for identifiers $tabStrings missing.');
  //   }
  //   if (tabViewStrings.isNotEmpty) {
  //     throw Exception('Tab for identifiers $tabViewStrings missing.');
  //   }
  // }

  void _setTabs(final List<DynamicTab> tabs) {
    if (_hasDuplicates(tabs.map((final e) => e.identifier).toList())) {
      throw Exception('Duplicate identifiers provided.');
    }
    _tabs = tabs;
  }

  void closeTabs(final List<String> tabs, {final String? switchToIdentifier}) {
    final toRemove = List<String>.from(tabs);
    final activeString = activeIdentifier;
    _forEach<String>(tabs, (final value) {
      if (!_activeStrings.contains(value)) {
        toRemove.remove(value);
      }
    });
    if (toRemove.contains(activeString)) {
      final index =
          switchToIdentifier != null && _getTabIndex(switchToIdentifier) > -1
              ? _getTabIndex(switchToIdentifier)
              : 0;
      _animateTo(index);
    }
    _forEach<String>(toRemove, _activeStrings.remove);
    _updateTabController(
      toRemove.contains(activeString) ? null : _getTabIndex(activeString),
    );
  }

  void closeTab(
    final String identifier, {
    final bool showDialog = false,
    final String? switchToIdentifier,
  }) {
    if (_activeStrings.contains(identifier) &&
        _getTab(identifier).isDismissible) {
      if (showDialog) {
        _onClose(identifier, _getTab(identifier).tab?.label)
            .then((final value) {
          if (value == true) {
            _removeTab(identifier, switchToIdentifier: switchToIdentifier);
          }
        });
      } else {
        _removeTab(identifier, switchToIdentifier: switchToIdentifier);
      }
    } else {
      if (!_activeStrings.contains(identifier)) {
        throw Exception('Tab $identifier is not open.');
      } else if (!_getTab(identifier).isDismissible) {
        throw Exception('Tab $identifier is not dismissible.');
      }
    }
  }

  Future<void> _removeTab(final String identifier,
      {final String? switchToIdentifier}) async {
    final currentActiveString = activeIdentifier;
    var prevIndex =
        _getTabIndex(identifier) > 0 ? _getTabIndex(identifier) - 1 : 0;
    if (prevIndex > _tabController.length - 1) {
      prevIndex = 0;
    }
    _activeStrings.remove(identifier);
    final index =
        switchToIdentifier != null && _getTabIndex(switchToIdentifier) > -1
            ? _getTabIndex(switchToIdentifier)
            : currentActiveString == identifier
                ? prevIndex
                : _getTabIndex(currentActiveString);
    _animateTo(index);
    await _updateTabController(null);
  }

  void openTabs(final List<String> identifiers,
      {final bool switchToLastTab = true}) {
    for (var i = 0; i < identifiers.length; i++) {
      if (!_activeStrings.contains(identifiers[i])) {
        _activeStrings.add(identifiers[i]);
      }
    }
    _updateTabController(
      switchToLastTab ? _getTabIndex(identifiers.last) : activeIndex,
    );
  }

  void openTab(final String identifier, {final bool switchToTab = true}) {
    if (!_activeStrings.contains(identifier)) {
      _activeStrings.add(identifier);
      _updateTabController(
        switchToTab ? _getTabIndex(identifier) : activeIndex,
      );
    } else {
      _animateTo(_getTabIndex(identifier));
    }
  }

  Future<void> _updateTabController([final int? index = 0]) async {
    final prevIndex =
        _controller.index < _currentTabs.length ? _controller.index : 0;
    await _waitForAnimation();
    _controller = TabController(
      length: _currentTabs.length,
      vsync: _vsync,
      initialIndex: prevIndex,
    );
    notifyListeners();
    if (index != null) {
      _animateTo(index);
      await _waitForAnimation();
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeIn,
      );
    }
  }

  Future _waitForAnimation() async {
    while (_tabController.indexIsChanging) {
      await Future.delayed(const Duration(milliseconds: 1));
    }
  }

  void _animateTo(final int index) {
    if (index > -1) {
      _tabController.animateTo(index);
    }
  }

  int _getTabIndex(final String identifier) => _currentTabs
      .indexWhere((final element) => element.identifier == identifier);

  DynamicTab _getTab(final String identifier) {
    try {
      return _tabs
          .firstWhere((final element) => element.identifier == identifier);
    } catch (e) {
      final temp = List.from(_activeStrings);
      _forEach<DynamicTab>(_tabs, (final value) {
        temp.remove(value.identifier);
      });
      throw Exception(
        "$e\n\nAn active tab's identifier might have been changed during runtime. A hot reload/restoring the previous identifier might fix the issue.\n\nMissing active identifiers: $temp\n",
      );
    }
  }

  bool _hasDuplicates(final List<String> items) =>
      items.length != items.toSet().length;
}

class TabBarItem {
  TabBarItem({
    this.label,
    this.child,
    this.key,
    this.height,
    this.closeButtonPadding,
    this.icon,
    this.childPadding,
    this.iconMargin = const EdgeInsets.only(bottom: 10),
  }) : assert(label == null || child == null, 'Cannot provide both.');

  final String? label;
  final Widget? child;
  final Icon? icon;
  final Key? key;

  /// The height of the [Tab].
  ///
  /// If null, the height will be calculated based on the content of the [Tab].  When `icon` is not
  /// null along with `child` or `text`, the default height is 72.0 pixels. Without an `icon`, the
  /// height is 46.0 pixels.
  final double? height;
  final EdgeInsets? childPadding;
  final EdgeInsets? closeButtonPadding;
  final EdgeInsetsGeometry iconMargin;
}

void _forEach<T>(final List<T> items, final ValueChanged<T> onIterate) {
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    onIterate(item);
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  const _KeepAliveWrapper({
    required this.child,
    final Key? key,
    this.keepAlive,
  }) : super(key: key);
  final Widget child;
  final bool Function()? keepAlive;

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(final BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => widget.keepAlive?.call() ?? true;
}
