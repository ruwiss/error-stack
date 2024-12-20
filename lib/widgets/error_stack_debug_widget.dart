import 'package:flutter/foundation.dart';
import '/error_stack.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'dart:ui';

/// ErrorStackDebugWidget

/// This widget is displayed when an error occurs in debug mode

/// It displays the error message, the class name, and the stack trace

/// It also allows the user to search for the error on Google

/// and restart the app

class ErrorStackDebugWidget extends StatefulWidget {
  final FlutterErrorDetails errorDetails;

  const ErrorStackDebugWidget({super.key, required this.errorDetails});

  @override
  createState() => _ErrorStackDebugWidget();
}

class _ErrorStackDebugWidget extends State<ErrorStackDebugWidget> {
  /// The theme mode

  String? _themeMode;

  @override
  initState() {
    super.initState();

    _init();
  }

  /// Initialize the widget

  _init() {
    _themeMode = ErrorStack.instance.themeMode == 'dark' ? 'dark' : 'light';

    setState(() {});
  }

  /// Try to match a regex in the stack trace

  String? _tryMatchRegexInStack(RegExp regExp, String stack, {int group = 0}) {
    Iterable<RegExpMatch> regMatches = regExp.allMatches(stack);

    if (regMatches.isEmpty) {
      return "";
    }

    return regMatches.first.group(group);
  }

  /// Get the class name

  String className() {
    String stack = widget.errorDetails.stack.toString();

    RegExp regExp = RegExp(r'(\(package:([A-z/.:0-9]+)\))');

    RegExp webRegExp = RegExp(r'packages/[A-z_]+(/([A-z/.:0-9]+)\s[0-9:]+)');

    String? className = _tryMatchRegexInStack(regExp, stack);

    if (className == null || className == "") {
      className = _tryMatchRegexInStack(webRegExp, stack, group: 1);
    }

    if (className == null || className == "") {
      return "File not found";
    }

    RegExp pattern = RegExp(r'^\(.*?/');

    String result = className
        .replaceAll(pattern, "/")
        .replaceAll("(", "")
        .replaceAll(")", "");

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeMode == "dark";
    final primaryColor = isDark ? Colors.red[400]! : Colors.red[600]!;

    return Scaffold(
      backgroundColor: isDark ? _hexColor("#151515") : Colors.grey[100],
      body: SafeArea(
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: CustomPaint(
                painter: GridPainter(
                  color: isDark
                      ? Colors.white.withOpacity(0.03)
                      : Colors.black.withOpacity(0.03),
                ),
              ),
            ),
            ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 40),
                // Error Icon with animated container
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Error Title
                Text(
                  'Error Occurred',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 32),
                // Glass Effect Error Card
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.2)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // File Location with copy button
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  className(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[700],
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.copy_rounded,
                                  size: 20,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
                                ),
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(
                                      text:
                                          "${widget.errorDetails.exceptionAsString()} flutter",
                                    ),
                                  );
                                  _showCopiedSnackBar();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Error Message
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.05),
                              ),
                            ),
                            child: Text(
                              widget.errorDetails.exceptionAsString(),
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: isDark
                                    ? _hexColor("#FFD700")
                                    : Colors.red[700],
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Action Buttons
                if (kIsWeb || kIsWasm)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                String exception =
                                    "${widget.errorDetails.exceptionAsString()}%20flutter";
                                String encodedQuery =
                                    Uri.encodeQueryComponent(exception);
                                launchUrl(Uri.parse(
                                    "https://www.google.com/search?q=$encodedQuery"));
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_rounded,
                                      size: 20,
                                      color: isDark
                                          ? Colors.blue[300]
                                          : Colors.blue[700],
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Search for Solutions',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.blue[300]
                                            : Colors.blue[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // Restart Button
                Center(
                  child: TextButton(
                    onPressed: () {
                      String initialRoute = ErrorStack.instance.initialRoute;
                      Navigator.pushNamedAndRemoveUntil(
                          context, initialRoute, (_) => false);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor:
                          isDark ? Colors.grey[400] : Colors.grey[700],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                    ),
                    child: const Text(
                      "Restart App",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Theme Toggle and Version
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDark ? Icons.dark_mode : Icons.light_mode,
                            size: 18,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isDark ? 'Dark Mode' : 'Light Mode',
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: isDark,
                            onChanged: (value) async {
                              _themeMode = value ? 'dark' : 'light';
                              await ErrorStack.instance.storage.write(
                                key: '${ErrorStack.storageKey}_theme_mode',
                                value: _themeMode!,
                              );
                              ErrorStack.instance.themeMode = _themeMode!;
                              setState(() {});
                            },
                            activeColor: Colors.blue[400],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Version Text
                Text(
                  "ErrorStack v1.10.0",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Display a snack bar when the text is copied

  _showCopiedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
      'Copied to your clipboard!',
      style: TextStyle(fontWeight: FontWeight.w600),
    )));
  }

  /// Get the color from a hex string

  /// [hexColor] the hex color string

  Color _hexColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");

    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }

    return Color(int.parse(hexColor, radix: 16));
  }
}

// Grid background painter
class GridPainter extends CustomPainter {
  final Color color;

  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const double spacing = 24.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => false;
}
