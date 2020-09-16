import 'package:flutter/material.dart';

circularProgress() {
  return Container(
    padding: const EdgeInsets.only(top: 10),
    alignment: Alignment.center,
    child: CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation(Colors.purple),
    ),
  );
}

linearProgress() {
  return Container(
    padding: const EdgeInsets.only(bottom: 10),
    child: LinearProgressIndicator(
      valueColor: AlwaysStoppedAnimation(Colors.purple),
    ),
  );
}
