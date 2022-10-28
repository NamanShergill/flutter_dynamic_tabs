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
          DynamicTab(
            identifier: 'identifier',
            isDismissible: false,
            tabViewBuilder: (context) => Test(dynamicTabsController, 'id'),
          ),
          DynamicTab(
            identifier: '1',
            isInitiallyActive: true,
            tabViewBuilder: (context) => InkWell(
              child: Test(dynamicTabsController, '1'),
            ),
          ),
          DynamicTab(
            identifier: '2',
            tabViewBuilder: (context) => Test(dynamicTabsController, '2'),
          ),
          DynamicTab(
            identifier: '3',
            tabViewBuilder: (context) => Test(dynamicTabsController, '3'),
          ),
          DynamicTab(
            identifier: '4',
            tabViewBuilder: (context) => Test(dynamicTabsController, '4'),
          ),
          DynamicTab(
            identifier: '5',
            tabViewBuilder: (context) => Test(dynamicTabsController, '5'),
          ),
          DynamicTab(
            identifier: '6',
            tabViewBuilder: (context) => Test(dynamicTabsController, '6'),
          ),
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
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('Tab ${widget.id}'),
        ),
        TextButton(
            onPressed: () {
              widget.controller.openTab('1');
            },
            child: const Text('Open tab 1')),
        TextButton(
            onPressed: () {
              widget.controller.openTab('2');
            },
            child: const Text('Open tab 2')),
        TextButton(
            onPressed: () {
              widget.controller.openTab('3');
            },
            child: const Text('Open tab 3')),
        TextButton(
            onPressed: () {
              widget.controller.openTab('4');
            },
            child: const Text('Open tab 4')),
        TextButton(
            onPressed: () {
              widget.controller.openTab('5');
            },
            child: const Text('Open tab 5')),
        TextButton(
            onPressed: () {
              widget.controller.openTab('6');
            },
            child: const Text('Open tab 6')),
        TextButton(
            onPressed: () {
              widget.controller.closeTabs(['6', '5', '4']);
            },
            child: const Text('Close tabs 4, 5, 6')),
        TextButton(
            onPressed: () {
              widget.controller.openTabs(['6', '5', '4']);
            },
            child: const Text('Open tabs 4, 5, 6')),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
