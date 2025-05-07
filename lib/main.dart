import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: 'Quick Connect',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MyHomePage(title: 'Quick Connect'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constrains) {
        if (constrains.maxWidth > 600) {
          return Center(
            child: SizedBox(
              width: constrains.maxWidth / 2.0,
              child: appState.isLogin ? SuccessForm() : LoginForm(),
            ),
          );
        } else {
          return Center(
            child: SizedBox(
              width: constrains.maxWidth / 1.1,
              child: appState.isLogin ? SuccessForm() : LoginForm(),
            ),
          );
        }
      }),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  String logs = "";

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        usernameController.text = prefs.getString("username")!;
        passwordController.text = prefs.getString("password")!;
      });
    });
  }

  void connect(AppState appState) async {
    setState(() {
      logs = "尝试连接中";
    });
    var url = Uri.parse("https://p.nju.edu.cn/api/portal/v1/login");
    var headers = {
      "Content-Type": "application/json",
    };
    var body = jsonEncode({
      "username": usernameController.text,
      "password": passwordController.text,
    });
    http.post(url, headers: headers, body: body).then((result) {
      var body = json.decode(result.body);
      if (body["reply_code"] == 0) {
        appState.setIsLogin(true);
        if (kDebugMode) {
          print("登录成功✌️");
        }
      } else if (body["reply_code"] == 500) {
        if (kDebugMode) {
          print("登录失败");
        }
      }
    }).catchError((error) {
      if (kDebugMode) {
        print(error);
      }
      setState(() {
        logs = "登录失败。未连接NJU-WLAN或服务器内部错误";
      });
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("username", usernameController.text);
    await prefs.setString("password", passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (KeyEvent event) {
        if (event.logicalKey == LogicalKeyboardKey.enter) {
          if (event is KeyDownEvent && !appState._pressedKeys.contains(event.logicalKey)) {
            connect(appState);
            appState.addPressedKeys(LogicalKeyboardKey.enter);
          } else if (event is KeyUpEvent) {
            appState.removePressedKeys(LogicalKeyboardKey.enter);
          }
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextField(
            controller: usernameController,
            decoration: InputDecoration(
                border: OutlineInputBorder(), labelText: "username"),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
          ),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
                border: OutlineInputBorder(), labelText: "password"),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
          ),
          ElevatedButton(
              onPressed: () async {
                connect(appState);
              },
              child: const Text("登录")),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
          ),
          Text(logs),
        ],
      ),
    );
  }
}

class SuccessForm extends StatefulWidget {
  const SuccessForm({super.key});

  @override
  State<SuccessForm> createState() => _SuccessFormState();
}

class _SuccessFormState extends State<SuccessForm> {
  String logs = "";

  void disconnect(AppState appState) async {
    setState(() {
      logs = "尝试登出中";
    });
    var url = Uri.parse("");
    var headers = {
      "Content-Type": "application/json",
    };
    var body = jsonEncode({});
    http.post(url, headers: headers, body: body).then((result) {
      var body = json.decode(result.body);
      if (body["reply_code"] == 0) {
        appState.setIsLogin(false);
        if (kDebugMode) {
          print("登出成功✌️");
        }
      } else if (body["reply_code"] == 500) {
        if (kDebugMode) {
          print("登出失败");
        }
      }
    }).catchError((error) {
      setState(() {
        if (kDebugMode) {
          print(error);
        }
        setState(() {
          logs = "登出失败。未连接NJU-WLAN或服务器内部错误";
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    return Center(
      child: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: (KeyEvent event) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            if (event is KeyDownEvent && !appState._pressedKeys.contains(event.logicalKey)) {
              disconnect(appState);
              appState.addPressedKeys(LogicalKeyboardKey.enter);
            } else if (event is KeyUpEvent) {
              appState.removePressedKeys(LogicalKeyboardKey.enter);
            }
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("登录成功✌️"),
            Padding(padding: EdgeInsets.symmetric(vertical: 4)),
            ElevatedButton(
              onPressed: () {
                disconnect(appState);
              },
              child: const Text("登出"),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
            ),
            Text(logs),
          ],
        ),
      ),
    );
  }
}

class AppState extends ChangeNotifier {
  var isLogin = false;
  void setIsLogin(bool isLogin) {
    this.isLogin = isLogin;
    notifyListeners();
  }

  final Set<LogicalKeyboardKey> _pressedKeys = {};
  void addPressedKeys(LogicalKeyboardKey key) {
    _pressedKeys.add(key);
    notifyListeners();
  }
  void removePressedKeys(LogicalKeyboardKey key) {
    _pressedKeys.remove(key);
    notifyListeners();
  }
}
