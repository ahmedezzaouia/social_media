import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttershare/widgets/header.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  String _username = '';
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void submit() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      SnackBar _snackBar = SnackBar(content: Text('Welcome $_username!'));
      _scaffoldKey.currentState.showSnackBar(_snackBar);
      Timer(
        Duration(seconds: 2),
        () {
          Navigator.pop(context, _username);
        },
      );
    }
  }

  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: header(context,
          titleText: 'Set up your profile', removeBackIcon: true),
      body: ListView(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text('create a username',
                    style:
                        TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  child: Form(
                    key: _formKey,
                    child: TextFormField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'username',
                        labelStyle: TextStyle(fontSize: 15.0),
                        hintText: 'must be at least 3 charachters',
                      ),
                      autovalidate: true,
                      onSaved: (_input) {
                        _username = _input;
                      },
                      validator: (_input) {
                        if (_input.trim().isEmpty || _input.trim().length < 3) {
                          return 'username too short!';
                        } else if (_input.trim().length > 12) {
                          return 'username too long';
                        } else {
                          return null;
                        }
                      },
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: submit,
                child: Container(
                  width: 250,
                  height: 50,
                  color: Colors.blue,
                  alignment: Alignment.center,
                  child: Text(
                    'submit',
                    style: TextStyle(fontSize: 15.0),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
