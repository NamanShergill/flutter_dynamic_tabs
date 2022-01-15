import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dynamic_tabs/flutter_dynamic_tabs.dart';
import 'package:flutter_dynamic_tabs/src/models/dynamic_tab_settings.dart';
import 'package:flutter_dynamic_tabs/src/modified/modified_tab_bar.dart'
    show ModifiedTabBar, ModifiedTabBarView;

class DynamicTabData {
  DynamicTabData({required this.dynamicTab, required this.tabViewChild})
      : _dynamicTabView = DynamicTabView(
            child: tabViewChild, identifier: dynamicTab.identifier);
  final DynamicTab dynamicTab;
  final Widget tabViewChild;
  final DynamicTabView _dynamicTabView;
}

class DynamicTabsWrapper extends StatefulWidget {
  DynamicTabsWrapper({
    required this.controller,
    required List<DynamicTabData> tabsData,
    required this.builder,
    this.onTabClose,
    this.tabBuilder,
    this.tabBarSettings,
    Key? key,
    this.tabViewSettings,
  })  : tabs = tabsData.map((e) => e.dynamicTab).toList(),
        tabViews = tabsData.map((e) => e._dynamicTabView).toList(),
        super(key: key);
  const DynamicTabsWrapper.segregated({
    required this.controller,
    required this.tabs,
    required this.tabViews,
    required this.builder,
    this.onTabClose,
    this.tabBuilder,
    this.tabBarSettings,
    Key? key,
    this.tabViewSettings,
  }) : super(key: key);
  final DynamicTabsController controller;
  final Future<bool> Function(String idenitifier, String? label)? onTabClose;
  final List<DynamicTab> tabs;
  final Widget Function(BuildContext context, DynamicTab tab)? tabBuilder;
  final List<DynamicTabView> tabViews;
  final Widget Function(
      BuildContext context, PreferredSizeWidget tabBar, Widget tabView) builder;
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
    setupWidget();
    super.initState();
  }

  void setupWidget() {
    widget.controller._setState(this);
    widget.controller._onClose = widget.onTabClose ??
        (identifier, label) async {
          return showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
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
                )
              ],
            ),
          );
        };
  }

  @override
  Widget build(BuildContext context) {
    final tabBar = widget.tabBarSettings ?? DynamicTabSettings();
    final tabView = widget.tabViewSettings ?? DynamicTabViewSettings();
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
          tabs: List.generate(widget.controller._setTabs(widget.tabs).length,
              (index) {
            final item = widget.controller._currentTabs[index];
            if (widget.tabBuilder != null) {
              return widget.tabBuilder!(context, item);
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
                      child: item.child == null && item.label != null
                          ? Text(item.label!)
                          : item.child!,
                    ),
                    if (item.isDismissible)
                      Padding(
                        padding: item.closeButtonPadding ??
                            tabBar.closeButtonPadding,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              widget.controller
                                  .closeTab(item.identifier, showDialog: true);
                            },
                            onLongPress: () {
                              widget.controller.closeTab(item.identifier);
                            },
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10)),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.close,
                                size: 15,
                              ),
                            ),
                          ),
                        ),
                      )
                  ],
                ),
              );
            }
          }),
          onScrollControllerInit: (value) {
            widget.controller._updateScrollController(value);
          },
        ),
        ModifiedTabBarView(
            controller: widget.controller._controller,
            key: tabView.key,
            dragStartBehavior: tabView.dragStartBehavior,
            physics: tabView.physics,
            children: widget.controller._setTabViews(widget.tabViews)));
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
  late List<DynamicTabView> _children;
  late List<DynamicTab> _tabs;
  late ScrollController _scrollController;
  void _updateScrollController(ScrollController controller) {
    _scrollController = controller;
  }

  List<DynamicTab> get _currentTabs => _activeStrings.map(_getTab).toList();

  List<Widget> get _currentTabViews =>
      _activeStrings.map((e) => _getTabView(e).child).toList();

  final List<String> _activeStrings = [];

  void _setState(State<DynamicTabsWrapper> state) {
    _vsync = state as TickerProvider;
    var initIndex = 0;
    _forEach<DynamicTab>(state.widget.tabs, (value) {
      if (value.isInitiallyActive || !value.isDismissible) {
        _activeStrings.add(value.identifier);
        if (value.isFocusedOnInit) {
          initIndex = _activeStrings.length - 1;
        }
      }
    });
    _controller = TabController(
        length: _activeStrings.length, vsync: _vsync, initialIndex: initIndex);
  }

  void _checkIdentifiers() {
    final tabStrings = _tabs.map((e) => e.identifier).toList();
    final tabViewStrings = _children.map((e) => e.identifier).toList();
    _forEach<String>(List.from(tabStrings), (value) {
      if (tabViewStrings.contains(value)) {
        tabViewStrings.remove(value);
        tabStrings.remove(value);
      }
    });

    if (tabStrings.isNotEmpty) {
      throw Exception('TabView for identifiers $tabStrings missing.');
    }
    if (tabViewStrings.isNotEmpty) {
      throw Exception('Tab for identifiers $tabViewStrings missing.');
    }
  }

  List<Widget> _setTabViews(List<DynamicTabView> children) {
    if (_hasDuplicates(children.map((e) => e.identifier).toList())) {
      throw Exception('Duplicate identifiers provided.');
    }
    _children = children;
    _checkIdentifiers();
    return _currentTabViews;
  }

  List<DynamicTab> _setTabs(List<DynamicTab> tabs) {
    if (_hasDuplicates(tabs.map((e) => e.identifier).toList())) {
      throw Exception('Duplicate identifiers provided.');
    }
    _tabs = tabs;
    return _currentTabs;
  }

  void closeTabs(List<String> tabs, {String? switchToIdentifier}) {
    final toRemove = List<String>.from(tabs);
    final activeString = activeIdentifier;
    _forEach<String>(tabs, (value) {
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
        toRemove.contains(activeString) ? null : _getTabIndex(activeString));
  }

  void closeTab(String identifier,
      {bool showDialog = false, String? switchToIdentifier}) {
    if (_activeStrings.contains(identifier) &&
        _getTab(identifier).isDismissible) {
      if (showDialog) {
        _onClose(identifier, _getTab(identifier).label).then((value) {
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

  void _removeTab(String identifier, {String? switchToIdentifier}) async {
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
    _updateTabController(null);
  }

  void openTabs(List<String> identifiers, {bool switchToLastTab = true}) {
    for (var i = 0; i < identifiers.length; i++) {
      if (!_activeStrings.contains(identifiers[i])) {
        _activeStrings.add(identifiers[i]);
      }
    }
    _updateTabController(
        switchToLastTab ? _getTabIndex(identifiers.last) : activeIndex);
  }

  void openTab(String identifier, {bool switchToTab = true}) {
    if (!_activeStrings.contains(identifier)) {
      _activeStrings.add(identifier);
      _updateTabController(
          switchToTab ? _getTabIndex(identifier) : activeIndex);
    } else {
      _animateTo(_getTabIndex(identifier));
    }
  }

  void _updateTabController([int? index = 0]) async {
    final prevIndex =
        _controller.index < _currentTabs.length ? _controller.index : 0;
    await _waitForAnimation();
    _controller = TabController(
        length: _currentTabs.length, vsync: _vsync, initialIndex: prevIndex);
    notifyListeners();
    if (index != null) {
      _animateTo(index);
      await _waitForAnimation();
      _scrollController.animateTo(_scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100), curve: Curves.easeIn);
    }
  }

  Future _waitForAnimation() async {
    while (_tabController.indexIsChanging) {
      await Future.delayed(const Duration(milliseconds: 1));
    }
  }

  void _animateTo(int index) {
    if (index > -1) {
      _tabController.animateTo(index);
    }
  }

  int _getTabIndex(String identifier) {
    return _currentTabs
        .indexWhere((element) => element.identifier == identifier);
  }

  DynamicTab _getTab(String identifier) {
    try {
      return _tabs.firstWhere((element) => element.identifier == identifier);
    } catch (e) {
      final temp = List.from(_activeStrings);
      _forEach<DynamicTab>(_tabs, (value) {
        temp.remove(value.identifier);
      });
      throw Exception(
          '$e\n\nAn active tab\'s identifier might have been changed during runtime. A hot reload/restoring the previous identifier might fix the issue.\n\nMissing active identifiers: $temp\n');
    }
  }

  DynamicTabView _getTabView(String identifier) {
    return _children.firstWhere((element) => element.identifier == identifier);
  }

  bool _hasDuplicates(List<String> items) {
    return items.length != items.toSet().length;
  }
}

class DynamicTab {
  DynamicTab(
      {required this.label,
      String? identifier,
      this.child,
      this.isDismissible = true,
      this.key,
      this.height,
      this.closeButtonPadding,
      this.isFocusedOnInit = false,
      this.icon,
      this.childPadding,
      this.iconMargin = const EdgeInsets.only(bottom: 10.0),
      bool isInitiallyActive = false})
      : assert(label != null || identifier != null,
            'Label and identifier cannot be both null!'),
        assert(label != null || child != null || icon != null,
            'All three cannot be null.'),
        assert(label == null || child == null, 'Cannot provider both.'),
        isInitiallyActive =
            isFocusedOnInit ? isFocusedOnInit : isInitiallyActive,
        identifier = identifier ?? label!;
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
  final bool isFocusedOnInit;
  final String identifier;
  final bool isDismissible;
  final bool isInitiallyActive;
  final EdgeInsets? closeButtonPadding;
  final EdgeInsetsGeometry iconMargin;
}

class DynamicTabView {
  DynamicTabView({
    required this.child,
    required this.identifier,
  });
  final Widget child;
  final String identifier;
}

void _forEach<T>(List<T> items, ValueChanged<T> onIterate) {
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    onIterate(item);
  }
}
