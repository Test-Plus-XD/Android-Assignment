import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final bool isTraditionalChinese;

  const LoginPage({
    required this.onLoginSuccess,
    required this.isTraditionalChinese,
    super.key,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool _isRegister = false;

  Future<void> _login() async {
    final String data = await rootBundle.loadString('assets/sample_users.json');
    final List<dynamic> users = json.decode(data);
    final user = users.firstWhere(
      (user) =>
          user['email'] == _emailController.text &&
          user['password'] == _passwordController.text,
      orElse: () => null,
    );

    if (user != null) {
      widget.onLoginSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isTraditionalChinese
              ? '無效的電郵或密碼'
              : 'Invalid email or password'),
        ),
      );
    }
  }

  Future<void> _register() async {
    final newUser = {
      'username': _usernameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
    };

    final String data = await rootBundle.loadString('assets/sample_users.json');
    final List<dynamic> users = json.decode(data);
    users.add(newUser);
    print('Updated user list (mock): ${json.encode(users)}');

    widget.onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTc = widget.isTraditionalChinese;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegister ? (isTc ? '註冊' : 'Register') : (isTc ? '登入' : 'Login')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (_isRegister)
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: isTc ? '用戶名' : 'Username',
                  border: const OutlineInputBorder(),
                ),
              ),
            if (_isRegister) const SizedBox(height: 16.0),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: isTc ? '電郵' : 'Email',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: isTc ? '密碼' : 'Password',
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _isRegister ? _register : _login,
              child: Text(_isRegister ? (isTc ? '註冊' : 'Register') : (isTc ? '登入' : 'Login')),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: () {
                widget.onLoginSuccess();
              },
              icon: Image.asset('assets/google_logo.png', height: 24.0),
              label: Text(isTc ? '使用 Google 登入' : 'Sign in with Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isRegister = !_isRegister;
                });
              },
              child: Text(_isRegister
                  ? (isTc ? '已經有帳戶？ 登入' : 'Have an account? Sign in')
                  : (isTc ? '建立新帳戶' : 'Create an account')),
            )
          ],
        ),
      ),
    );
  }
}
