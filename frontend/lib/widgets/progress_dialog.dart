import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SendingProgressDialog extends StatefulWidget {
  final String url;
  final Map<String, String> headers;
  final String body;

  const SendingProgressDialog({
    super.key,
    required this.url,
    required this.headers,
    required this.body,
  });

  @override
  State<SendingProgressDialog> createState() => _SendingProgressDialogState();
}

class _SendingProgressDialogState extends State<SendingProgressDialog> {
  int sent = 0;
  int failed = 0;
  int total = 0;
  List<String> logs = [];
  bool isComplete = false;
  bool hasError = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _startSending();
  }

  Future<void> _startSending() async {
    try {
      final request = http.Request('POST', Uri.parse(widget.url));
      request.headers.addAll(widget.headers);
      request.body = widget.body;

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode != 200) {
        setState(() {
          hasError = true;
          errorMessage = 'Server error: ${streamedResponse.statusCode}';
        });
        return;
      }

      // Listen to the SSE stream
      streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.trim().isEmpty) return;

          try {
            final data = jsonDecode(line);
            final type = data['type'];

            if (type == 'progress') {
              setState(() {
                sent = data['sent'] ?? sent;
                failed = data['failed'] ?? failed;
                total = data['total'] ?? total;
                if (data['log'] != null) {
                  logs.insert(0, data['log']);
                  if (logs.length > 50) logs.removeLast();
                }
              });
            } else if (type == 'complete') {
              setState(() {
                isComplete = true;
                if (data['message'] != null) {
                  logs.insert(0, '✅ ${data['message']}');
                }
              });
            } else if (type == 'error') {
              setState(() {
                hasError = true;
                errorMessage = data['message'];
              });
            } else if (type == 'log') {
              setState(() {
                if (data['message'] != null) {
                  logs.insert(0, data['message']);
                }
              });
            }
          } catch (e) {
            print('Error parsing SSE data: $e');
          }
        },
        onError: (error) {
          setState(() {
            hasError = true;
            errorMessage = 'Connection error: $error';
          });
        },
        onDone: () {
          if (!isComplete && !hasError) {
            setState(() {
              isComplete = true;
            });
          }
        },
      );
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = 'Failed to connect: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = total - sent - failed;
    final progress = total > 0 ? (sent + failed) / total : 0.0;

    return AlertDialog(
      title: Row(
        children: [
          if (!isComplete && !hasError)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          if (isComplete)
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
          if (hasError)
            const Icon(Icons.error, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          Text(
            hasError
                ? 'Error'
                : isComplete
                    ? 'Complete'
                    : 'Sending Certificates',
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasError) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage ?? 'Unknown error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Progress bar
            if (total > 0) ...[
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  hasError ? Colors.red : Colors.blue,
                ),
                minHeight: 8,
              ),
              const SizedBox(height: 16),
            ],
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'Sent',
                  sent.toString(),
                  Colors.green,
                  Icons.check_circle_outline,
                ),
                _buildStatCard(
                  'Failed',
                  failed.toString(),
                  Colors.red,
                  Icons.error_outline,
                ),
                _buildStatCard(
                  'Remaining',
                  remaining.toString(),
                  Colors.orange,
                  Icons.pending_outlined,
                ),
                _buildStatCard(
                  'Total',
                  total.toString(),
                  Colors.blue,
                  Icons.email_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            // Logs header
            Row(
              children: [
                const Icon(Icons.terminal, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Live Logs',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '${logs.length} entries',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Logs list
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: logs.isEmpty
                    ? const Center(
                        child: Text(
                          'Waiting for updates...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          final isError = log.contains('Failed') ||
                              log.contains('error') ||
                              log.contains('Error');
                          final isSuccess = log.contains('Sent to') ||
                              log.contains('✅');

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  isError
                                      ? Icons.close
                                      : isSuccess
                                          ? Icons.check
                                          : Icons.info_outline,
                                  size: 16,
                                  color: isError
                                      ? Colors.red
                                      : isSuccess
                                          ? Colors.green
                                          : Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    log,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                      color: isError
                                          ? Colors.red.shade700
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (isComplete || hasError)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
