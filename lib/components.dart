import 'package:flutter/material.dart';

class CustomTextField {
  final TextEditingController controller;
  final String hintText;
  bool isValid;

  CustomTextField(this.controller, this.hintText, {this.isValid: false});

  Padding getSimpleTextField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: hintText,
        ),
        style: const TextStyle(fontSize: 18.0),
      ),
    );
  }

  Padding getSecretTextField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: TextField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: hintText,
        ),
        style: const TextStyle(fontSize: 18.0),
      ),
    );
  }
}

class SimpleRaisedButton {
  final String text;
  final double fontSize;
  final double width;
  final Function function;

  SimpleRaisedButton(this.text, this.function,
      {this.fontSize: 24.0, this.width: 70.0});

  RaisedButton getSimpleRaisedButton() {
    return RaisedButton(
      padding: EdgeInsets.symmetric(horizontal: width, vertical: 15.0),
      shape: StadiumBorder(),
      color: const Color.fromARGB(255, 0, 102, 20),
      highlightColor: const Color.fromARGB(255, 0, 179, 36),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.white,
        ),
      ),
      onPressed: function,
    );
  }
}
