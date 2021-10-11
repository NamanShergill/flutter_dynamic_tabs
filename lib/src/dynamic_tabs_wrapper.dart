import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dynamic_tabs/src/modified/modified_tab_bar.dart'
    show ModifiedTabBarView;

class DynamicTabsWrapper extends StatefulWidget {
  const DynamicTabsWrapper(
      {required this.controller,
      required this.tabs,
      required this.tabViews,
      required this.builder,
      this.onTabClose,
      this.tabBuilder,
      Key? key})
      : super(key: key);
  final DynamicTabsController controller;
  final Future<bool> Function(String idenitifier)? onTabClose;
  final List<DynamicTab> tabs;
  final Widget Function(BuildContext context, DynamicTab tab)? tabBuilder;
  final List<DynamicTabView> tabViews;
  final Widget Function(
      BuildContext context, PreferredSizeWidget tabBar, Widget tabView) builder;
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
        (identifier) async {
          return showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Close $identifier?'),
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
    return widget.builder(
        context,
        TabBar(
            isScrollable: true,
            controller: widget.controller._tabController,
            tabs: List.generate(widget.controller._setTabs(widget.tabs).length,
                (index) {
              final item = widget.controller._currentTabs[index];
              if (widget.tabBuilder != null) {
                return widget.tabBuilder!(context, item);
              } else {
                return Tab(
                  key: item._key,
                  child: Row(
                    children: [
                      Text(item.label),
                      if (item.isDismissible)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                widget.controller.closeTab(item.identifier,
                                    showDialog: true);
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
            })),
        ModifiedTabBarView(
            controller: widget.controller._controller,
            children: widget.controller._setTabViews(widget.tabViews)));
  }
}

class DynamicTabsController extends ChangeNotifier {
  late Future<bool?> Function(String identifier) _onClose;
  late TickerProvider _vsync;
  late TabController _controller;
  TabController get _tabController => _controller;
  int get activeIndex => _tabController.index;
  bool get indexIsChanging => _tabController.indexIsChanging;
  int get activeLength => _tabController.length;
  String get activeIdentifier => _activeStrings[activeIndex];
  late List<DynamicTabView> _children;
  late List<DynamicTab> _tabs;

  List<DynamicTab> get _currentTabs => _activeStrings.map(_getTab).toList();

  List<Widget> get _currentTabViews =>
      _activeStrings.map((e) => _getTabView(e).child).toList();

  final List<String> _activeStrings = [];

  void _setState(State<DynamicTabsWrapper> state) {
    _vsync = state as TickerProvider;
    _forEach<DynamicTab>(state.widget.tabs, (value) {
      if (value.isInitiallyActive || !value.isDismissible) {
        _activeStrings.add(value.identifier);
      }
    });
    _controller = TabController(length: _activeStrings.length, vsync: _vsync);
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
    _forEach<DynamicTab>(_tabs, (value) {
      value._key = GlobalKey();
    });
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
        _onClose(identifier).then((value) {
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
      if (_getTab(_activeStrings[index])._key.currentContext != null) {
        Scrollable.ensureVisible(
            _getTab(_activeStrings[index])._key.currentContext!);
      }
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
      this.isDismissible = true,
      this.isInitiallyActive = false})
      : identifier = identifier ?? label;
  final String label;
  final String identifier;
  late GlobalKey _key;
  final bool isDismissible;
  final bool isInitiallyActive;
}

class DynamicTabView {
  DynamicTabView({required this.identifier, required this.child});
  final Widget child;
  final String identifier;
}

void _forEach<T>(List<T> items, ValueChanged<T> onIterate) {
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    onIterate(item);
  }
}
