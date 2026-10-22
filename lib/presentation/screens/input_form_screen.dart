import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/payload_serializer.dart';
import '../../data/models/qr_item.dart';
import '../../data/models/qr_style_config.dart';
import '../../data/models/qr_type.dart';

class InputFormScreen extends StatefulWidget {
  final QrType type;

  const InputFormScreen({super.key, required this.type});

  @override
  State<InputFormScreen> createState() => _InputFormScreenState();
}

class _InputFormScreenState extends State<InputFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final Map<String, TextEditingController> _controllers = {};
  String _wifiEncryption = 'WPA';
  bool _wifiHidden = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    switch (widget.type) {
      case QrType.url:
        _controllers['url'] = TextEditingController();
        break;
      case QrType.multiUrl:
        _controllers['title'] = TextEditingController(
          text: 'My Important Links',
        );
        _controllers['links'] = TextEditingController();
        break;
      case QrType.vCard:
        _controllers['firstName'] = TextEditingController();
        _controllers['lastName'] = TextEditingController();
        _controllers['organization'] = TextEditingController();
        _controllers['jobTitle'] = TextEditingController();
        _controllers['phone'] = TextEditingController();
        _controllers['email'] = TextEditingController();
        _controllers['website'] = TextEditingController();
        _controllers['address'] = TextEditingController();
        _controllers['note'] = TextEditingController();
        break;
      case QrType.email:
        _controllers['email'] = TextEditingController();
        _controllers['subject'] = TextEditingController();
        _controllers['body'] = TextEditingController();
        break;
      case QrType.phone:
        _controllers['phone'] = TextEditingController();
        break;
      case QrType.sms:
        _controllers['phone'] = TextEditingController();
        _controllers['message'] = TextEditingController();
        break;
      case QrType.whatsapp:
        _controllers['phone'] = TextEditingController();
        _controllers['message'] = TextEditingController();
        break;
      case QrType.telegram:
        _controllers['username'] = TextEditingController();
        break;
      case QrType.instagram:
        _controllers['username'] = TextEditingController();
        break;
      case QrType.facebook:
        _controllers['profile'] = TextEditingController();
        break;
      case QrType.twitter:
        _controllers['username'] = TextEditingController();
        break;
      case QrType.youtube:
        _controllers['url'] = TextEditingController();
        break;
      case QrType.linkedin:
        _controllers['profile'] = TextEditingController();
        break;
      case QrType.tiktok:
        _controllers['username'] = TextEditingController();
        break;
      case QrType.spotify:
        _controllers['url'] = TextEditingController();
        break;
      case QrType.wifi:
        _controllers['ssid'] = TextEditingController();
        _controllers['password'] = TextEditingController();
        break;
      case QrType.map:
        _controllers['latitude'] = TextEditingController();
        _controllers['longitude'] = TextEditingController();
        _controllers['label'] = TextEditingController();
        break;
      case QrType.text:
        _controllers['text'] = TextEditingController();
        break;
      case QrType.upi:
        _controllers['vpa'] = TextEditingController();
        _controllers['name'] = TextEditingController();
        _controllers['amount'] = TextEditingController();
        break;
      case QrType.calendar:
        _controllers['title'] = TextEditingController();
        _controllers['location'] = TextEditingController();
        _controllers['description'] = TextEditingController();
        _controllers['startDate'] = TextEditingController();
        _controllers['endDate'] = TextEditingController();
        break;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _proceedToCustomizer() {
    if (!_formKey.currentState!.validate()) return;

    final fields = <String, String>{};
    for (var entry in _controllers.entries) {
      fields[entry.key] = entry.value.text;
    }

    if (widget.type == QrType.wifi) {
      fields['encryption'] = _wifiEncryption;
      fields['hidden'] = _wifiHidden ? 'true' : 'false';
    }

    final payload = PayloadSerializer.serialize(widget.type, fields);
    final title = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : widget.type.title;

    final item = QrItem(
      id: const Uuid().v4(),
      title: title,
      type: widget.type,
      rawData: fields.values.join(' | '),
      formattedPayload: payload,
      styleConfig: const QrStyleConfig(),
      createdAt: DateTime.now(),
    );

    context.push('/customize', extra: item);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.type.title), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Header Card
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.type.brandColor.withValues(alpha: 0.12),
                      colorScheme.surfaceContainerLow,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.type.brandColor.withValues(alpha: 0.25),
                  ),
                ),
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.type.brandColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: widget.type.brandColor.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.type.icon,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.type.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.type.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Dynamic Fields
              ..._buildTypeFields(),
              const SizedBox(height: 16),

              // Optional Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Custom Label / Name (Optional)',
                  hintText: 'e.g. My Portfolio, Home Wi-Fi',
                  prefixIcon: Icon(Icons.bookmark_outline),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _proceedToCustomizer,
              icon: const Icon(Icons.palette_outlined),
              label: const Text(
                'Next: Customize Design',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTypeFields() {
    switch (widget.type) {
      case QrType.url:
        return [
          TextFormField(
            controller: _controllers['url'],
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: 'Website Address (URL) *',
              hintText: 'https://example.com',
              prefixIcon: const Icon(Icons.link),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Please enter a URL' : null,
          ),
        ];

      case QrType.multiUrl:
        return [
          TextFormField(
            controller: _controllers['title'],
            decoration: InputDecoration(labelText: 'Hub Title *'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _controllers['links'],
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Links (one per line) *',
              hintText: "Portfolio: https://...\nTwitter: https://...",
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Please enter at least one link'
                : null,
          ),
        ];

      case QrType.vCard:
        return [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _controllers['firstName'],
                  decoration: InputDecoration(labelText: 'First Name *'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _controllers['lastName'],
                  decoration: InputDecoration(labelText: 'Last Name'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controllers['phone'],
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number *',
              prefixIcon: const Icon(Icons.phone),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Phone is required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controllers['email'],
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: const Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controllers['organization'],
            decoration: InputDecoration(
              labelText: 'Company / Organization',
              prefixIcon: const Icon(Icons.business),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controllers['jobTitle'],
            decoration: InputDecoration(
              labelText: 'Job Title',
              prefixIcon: const Icon(Icons.badge),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controllers['website'],
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: 'Website',
              prefixIcon: const Icon(Icons.language),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controllers['address'],
            decoration: InputDecoration(
              labelText: 'Full Address',
              prefixIcon: const Icon(Icons.location_on),
            ),
          ),
        ];

      case QrType.wifi:
        return [
          TextFormField(
            controller: _controllers['ssid'],
            decoration: InputDecoration(
              labelText: 'Network Name (SSID) *',
              prefixIcon: const Icon(Icons.wifi),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'SSID is required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controllers['password'],
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _wifiEncryption,
            decoration: InputDecoration(labelText: 'Security Encryption'),
            items: const [
              DropdownMenuItem(value: 'WPA', child: Text('WPA / WPA2 / WPA3')),
              DropdownMenuItem(value: 'WEP', child: Text('WEP')),
              DropdownMenuItem(
                value: 'nopass',
                child: Text('None (Open Network)'),
              ),
            ],
            onChanged: (v) => setState(() => _wifiEncryption = v ?? 'WPA'),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Hidden Network'),
            value: _wifiHidden,
            onChanged: (v) => setState(() => _wifiHidden = v),
          ),
        ];

      case QrType.email:
        return [
          TextFormField(
            controller: _controllers['email'],
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Recipient Email Address *',
              prefixIcon: const Icon(Icons.email),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Email is required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controllers['subject'],
            decoration: InputDecoration(labelText: 'Subject'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controllers['body'],
            maxLines: 3,
            decoration: InputDecoration(labelText: 'Message Body'),
          ),
        ];

      case QrType.phone:
        return [
          TextFormField(
            controller: _controllers['phone'],
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number (with country code) *',
              hintText: '+1234567890',
              prefixIcon: const Icon(Icons.phone),
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Phone number is required'
                : null,
          ),
        ];

      case QrType.sms:
        return [
          TextFormField(
            controller: _controllers['phone'],
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Recipient Phone Number *',
              prefixIcon: const Icon(Icons.phone),
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Phone number is required'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controllers['message'],
            maxLines: 3,
            decoration: InputDecoration(labelText: 'Pre-filled Text Message'),
          ),
        ];

      case QrType.whatsapp:
        return [
          TextFormField(
            controller: _controllers['phone'],
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'WhatsApp Phone (with Country Code) *',
              hintText: 'e.g. 14155552671',
              prefixIcon: const Icon(Icons.chat),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Phone is required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controllers['message'],
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Pre-filled Message (Optional)',
            ),
          ),
        ];

      case QrType.telegram:
      case QrType.instagram:
      case QrType.twitter:
      case QrType.tiktok:
        return [
          TextFormField(
            controller: _controllers['username'],
            decoration: InputDecoration(
              labelText: 'Username / Handle *',
              hintText: '@username',
              prefixIcon: const Icon(Icons.alternate_email),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Handle is required' : null,
          ),
        ];

      case QrType.facebook:
      case QrType.youtube:
      case QrType.linkedin:
      case QrType.spotify:
        return [
          TextFormField(
            controller:
                _controllers[widget.type == QrType.youtube ? 'url' : 'profile'],
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: 'Link / Profile URL *',
              prefixIcon: const Icon(Icons.link),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Link is required' : null,
          ),
        ];

      case QrType.map:
        return [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _controllers['latitude'],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Latitude *',
                    hintText: '37.7749',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _controllers['longitude'],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Longitude *',
                    hintText: '-122.4194',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
        ];

      case QrType.text:
        return [
          TextFormField(
            controller: _controllers['text'],
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Plain Text Content *',
              hintText: 'Enter text, notes, code snippet, etc.',
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Please enter some text' : null,
          ),
        ];

      case QrType.upi:
        return [
          TextFormField(
            controller: _controllers['vpa'],
            decoration: InputDecoration(
              labelText: 'UPI ID / VPA *',
              hintText: 'merchant@upi',
              prefixIcon: const Icon(Icons.payment),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'UPI ID is required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controllers['name'],
            decoration: InputDecoration(labelText: 'Payee Name *'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controllers['amount'],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Amount in INR (Optional)'),
          ),
        ];

      case QrType.calendar:
        return [
          TextFormField(
            controller: _controllers['title'],
            decoration: InputDecoration(labelText: 'Event Title *'),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Event title is required'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controllers['location'],
            decoration: InputDecoration(labelText: 'Event Location'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controllers['description'],
            maxLines: 2,
            decoration: InputDecoration(labelText: 'Description'),
          ),
        ];
    }
  }
}
