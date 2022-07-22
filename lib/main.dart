import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var viewModel = ViewModel();

  void _incrementCounter() {
    viewModel.changeCount();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  viewModel.nothingChange();
                },
                child: Container(
                  width: 100,
                  height: 50,
                  color: Colors.red,
                  child: Text('无数据修改'),
                ),
              ),
              GestureDetector(
                onTap: () {
                  viewModel.changeCount();
                },
                child: Container(
                  width: 100,
                  height: 50,
                  color: Colors.blue,
                  child: Text('计数器增加'),
                ),
              ),
              Text(
                'You have pushed the button this many times:',
              ),
              Provider<ViewModel>(viewModel, CountView())
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _incrementCounter,
          tooltip: 'Increment',
          child: Icon(Icons.add),
        ));
  }
}

class CountView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Selector<ViewModel, int>(
          (context, value) => Text(
                value.toString(),
                style: Theme.of(context).textTheme.headline4,
              ),
          (context, data) => data?.count ?? 0)
    ]);
  }
}

class ViewModel extends ChangeNotifier {
  var count = 0;

  changeCount() {
    count += 1;
    notifyListeners();
  }

  nothingChange() {
    notifyListeners();
  }
}

// =============== Provider ============

class InheritedProvider<T> extends InheritedWidget {
  final T data;

  InheritedProvider(this.data, Widget child) : super(child: child);

  /// 当InheritedWidget rebuild时，会通知依赖data的子widget重建
  /// 调用dependOnInheritedWidgetOfExactType 依赖data，通知子widget 调用didChangeDependencies方法
  /// getElementForInheritedWidgetOfExactType 不会依赖data
  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }
}

class Provider<T extends ChangeNotifier> extends StatefulWidget {
  final T data;
  final Widget child;

  Provider(this.data, this.child);

  @override
  State<StatefulWidget> createState() => _ProviderState<T>();

  static T? of<T>(BuildContext context, {bool listen = true}) {
    final provider = listen
        ? context.dependOnInheritedWidgetOfExactType<InheritedProvider<T>>()
        : context
                .getElementForInheritedWidgetOfExactType<InheritedProvider<T>>()
            as InheritedProvider<T>;
    return provider?.data;
  }
}

class _ProviderState<T extends ChangeNotifier> extends State<Provider<T>> {
  @override
  void didUpdateWidget(covariant Provider<T> oldWidget) {
    if (oldWidget.data != widget.data) {
      oldWidget.data.removeListener(update);
      widget.data.addListener(update);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    widget.data.addListener(update);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InheritedProvider(widget.data, widget.child);
  }

  @override
  void dispose() {
    widget.data.removeListener(update());
    super.dispose();
  }

  update() {
    setState(() {});
  }
}

/// Selector
typedef SelectorFunction<A, S> = S Function(BuildContext context, A? data);
typedef SelectorBuilderFuntion<S> = Function(BuildContext context, S value);

class Selector<A extends ChangeNotifier, S> extends StatefulWidget {
  final SelectorBuilderFuntion<S> builder;
  final SelectorFunction<A, S> selector;

  Selector(this.builder, this.selector, {Key? key}) : super(key: key);

  @override
  _SelectorState<A, S> createState() => _SelectorState<A, S>();
}

class _SelectorState<A extends ChangeNotifier, S>
    extends State<Selector<A, S>> {
  S? value;

  /// 缓存上次创建的widget
  Widget? cache;

  /// 包含Selector的旧Widget
  Widget? oldWidget;

  @override
  Widget build(BuildContext context) {
    // 依赖Provider数据
    final selected = widget.selector(context, Provider.of<A>(context));

    // 检测widget是否需要更新
    final shouldInvalidateCache = oldWidget != widget || value != selected;
    if (shouldInvalidateCache) {
      value = selected;
      oldWidget = widget;
      cache = widget.builder(context, selected);
    }
    return cache!;
  }
}
