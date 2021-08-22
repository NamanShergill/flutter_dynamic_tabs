import 'package:flutter/material.dart';
import 'package:flutter_dynamic_tabs/flutter_dynamic_tabs.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final DynamicTabsController dynamicTabsController = DynamicTabsController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DynamicTabsWrapper(
        controller: dynamicTabsController,
        tabs: [
          DynamicTab(label: 'identifier', isInitiallyActive: true),
          DynamicTab(label: '1'),
          DynamicTab(label: '2'),
          DynamicTab(label: '3'),
          DynamicTab(label: '4'),
          DynamicTab(label: '5'),
          DynamicTab(label: '6'),
        ],
        tabViews: [
          DynamicTabView(
              identifier: 'identifier',
              child: Test(dynamicTabsController, 'id')),
          DynamicTabView(
              identifier: '1',
              child: InkWell(child: Test(dynamicTabsController, '1'))),
          DynamicTabView(
              identifier: '2', child: Test(dynamicTabsController, '2')),
          DynamicTabView(
              identifier: '3', child: Test(dynamicTabsController, '3')),
          DynamicTabView(
              identifier: '4', child: Test(dynamicTabsController, '4')),
          DynamicTabView(
              identifier: '5', child: Test(dynamicTabsController, '5')),
          DynamicTabView(
              identifier: '6', child: Test(dynamicTabsController, '6')),
        ],
        builder: (context, tabBar, tabView) {
          return Scaffold(
              appBar: AppBar(
                title: const Text('Dynamic Tabs Example'),
                bottom: tabBar,
              ),
              body: tabView);
        },
      ),
    );
  }
}

class Test extends StatefulWidget {
  const Test(this.controller, this.id, {Key? key}) : super(key: key);
  final DynamicTabsController controller;
  final String id;
  @override
  _TestState createState() => _TestState();
}

class _TestState extends State<Test> with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    print('init');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(widget.id),
        TextButton(
            onPressed: () {
              widget.controller.openTab('1');
            },
            child: Text('1')),
        TextButton(
            onPressed: () {
              widget.controller.openTab('2');
            },
            child: Text('2')),
        TextButton(
            onPressed: () {
              widget.controller.openTab('3');
            },
            child: Text('3')),
        TextButton(
            onPressed: () {
              widget.controller.openTab('4');
            },
            child: Text('4')),
        TextButton(
            onPressed: () {
              widget.controller.openTab('5');
            },
            child: Text('5')),
        TextButton(
            onPressed: () {
              widget.controller.openTab('6');
            },
            child: Text('6')),
        TextButton(
            onPressed: () {
              widget.controller.closeTabs(['6', '5', '4']);
            },
            child: Text('Close')),
        TextButton(
            onPressed: () {
              widget.controller.openTabs(['6', '5', '4']);
            },
            child: Text('Open')),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
