import 'package:flutter/material.dart';

class CustomTextField {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final int maxLength;
  final int maxLine;
  final TextInputType textInputType;

  CustomTextField(this.controller,
      {this.labelText,
      this.hintText,
      this.maxLength: 50,
      this.maxLine: 1,
      this.textInputType: TextInputType.text});

  Padding getSimpleTextField() {
    if (labelText != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: labelText,
          ),
          style: const TextStyle(fontSize: 18.0),
          maxLength: maxLength,
          minLines: null,
          maxLines: maxLine,
          keyboardType: textInputType,
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
          ),
          style: const TextStyle(fontSize: 18.0),
          maxLength: maxLength,
          minLines: null,
          maxLines: maxLine,
          keyboardType: textInputType,
        ),
      );
    }
  }

  Padding getSecretTextField() {
    if (labelText != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            labelText: labelText,
          ),
          style: const TextStyle(fontSize: 18.0),
          maxLength: maxLength,
          minLines: null,
          maxLines: maxLine,
          keyboardType: textInputType,
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            hintText: hintText,
          ),
          style: const TextStyle(fontSize: 18.0),
          maxLength: maxLength,
          minLines: null,
          maxLines: maxLine,
          keyboardType: textInputType,
        ),
      );
    }
  }

  TextField getDialogTextField() {
    if (labelText != null) {
      return TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
        ),
        style: const TextStyle(fontSize: 16.0),
        maxLength: maxLength,
        minLines: null,
        maxLines: maxLine,
        keyboardType: textInputType,
      );
    } else {
      return TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
        ),
        style: const TextStyle(fontSize: 16.0),
        maxLength: maxLength,
        minLines: null,
        maxLines: maxLine,
        keyboardType: textInputType,
      );
    }
  }
}

class SimpleRaisedButton {
  final String text;
  final double fontSize;
  final double width;
  final Function function;
  final Color backColor;
  final Color focusBackColor;
  final Color textColor;

  SimpleRaisedButton(this.text, this.function,
      {this.fontSize: 24.0,
      this.width: 70.0,
      this.backColor: const Color.fromARGB(255, 0, 102, 20),
      this.focusBackColor: const Color.fromARGB(255, 0, 179, 36),
      this.textColor: const Color.fromARGB(255, 255, 255, 255)});

  RaisedButton getRoundedRaisedButton() {
    return RaisedButton(
      padding: EdgeInsets.symmetric(horizontal: width, vertical: 15.0),
      shape: StadiumBorder(),
      color: backColor,
      highlightColor: focusBackColor,
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color: textColor,
        ),
      ),
      onPressed: function,
    );
  }

  RaisedButton getSquareRaisedButton() {
    return RaisedButton(
      padding: EdgeInsets.symmetric(horizontal: width, vertical: 15.0),
      color: backColor,
      highlightColor: focusBackColor,
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color: textColor,
        ),
      ),
      onPressed: function,
    );
  }
}
