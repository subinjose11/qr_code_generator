import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/qr_item.dart';
import '../../data/models/qr_style_config.dart';
import '../providers/qr_history_provider.dart';
import '../widgets/export_dialog.dart';
import '../widgets/qr_frame_wrapper.dart';

class CustomizerScreen extends ConsumerStatefulWidget {
  final QrItem initialItem;

  const CustomizerScreen({super.key, required this.initialItem});

  @override
  ConsumerState<CustomizerScreen> createState() => _CustomizerScreenState();
}

class _CustomizerScreenState extends ConsumerState<CustomizerScreen>
    with SingleTickerProviderStateMixin {
  late QrItem _item;
  late TabController _tabController;
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _frameTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _item = widget.initialItem;
    _frameTextController.text = _item.styleConfig.frameText;
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _frameTextController.dispose();
    super.dispose();
  }

  void _updateConfig(QrStyleConfig Function(QrStyleConfig) update) {
    setState(() {
      _item = _item.copyWith(styleConfig: update(_item.styleConfig));
    });
  }

  Future<void> _pickCustomLogo() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
    );
    if (image != null) {
      _updateConfig(
        (c) => c.copyWith(
          logoType: QrLogoType.customFile,
          customLogoPath: image.path,
        ),
      );
    }
  }

  void _showColorPicker({
    required String title,
    required Color currentColor,
    required ValueChanged<Color> onColorChanged,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: onColorChanged,
            enableAlpha: false,
            displayThumbColor: true,
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveToHistory() async {
    await ref.read(qrHistoryProvider.notifier).saveItem(_item);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved to "My QR Codes" database!'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_item.title)),
      body: Column(
        children: [
          // 1. Live Interactive Preview Area
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Center(
                child: SingleChildScrollView(
                  child: _buildPreviewCard(qrSize: 220),
                ),
              ),
            ),
          ),

          // 2. Editor Tab Bar
          _buildEditorTabBar(),

          // 3. Tab Views
          Expanded(
            flex: 4,
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: _buildTabBarView(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
          child: _buildActionButtons(),
        ),
      ),
    );
  }

  Widget _buildPreviewCard({double qrSize = 220}) {
    return Card(
      elevation: 1,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: QrFrameWrapper(
          data: _item.formattedPayload,
          config: _item.styleConfig,
          qrSize: qrSize,
        ),
      ),
    );
  }

  Widget _buildEditorTabBar() {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final colorScheme = Theme.of(context).colorScheme;

        return Container(
          color: colorScheme.surfaceContainer,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: isDark ? Colors.white : colorScheme.primary,
            unselectedLabelColor: isDark
                ? const Color(0xFF94A3B8)
                : colorScheme.onSurfaceVariant,
            indicatorColor: isDark ? Colors.white : colorScheme.primary,
            indicatorWeight: 3.0,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            tabs: const [
              Tab(icon: Icon(Icons.grain, size: 20), text: 'Patterns'),
              Tab(icon: Icon(Icons.visibility, size: 20), text: 'Eyes'),
              Tab(icon: Icon(Icons.palette_outlined, size: 20), text: 'Colors'),
              Tab(icon: Icon(Icons.image_outlined, size: 20), text: 'Logo'),
              Tab(icon: Icon(Icons.crop_free, size: 20), text: 'Frames'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildPatternsTab(),
        _buildEyesTab(),
        _buildColorsTab(),
        _buildLogoTab(),
        _buildFramesTab(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: FilledButton.tonalIcon(
              onPressed: _saveToHistory,
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('Save Code'),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: () => ExportDialog.show(context, _item),
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('Export & Share'),
            ),
          ),
        ),
      ],
    );
  }

  // --- TAB 1: PATTERNS ---
  Widget _buildPatternsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Body Module Shapes',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: QrBodyPattern.values.map((pattern) {
            final isSelected = _item.styleConfig.bodyPattern == pattern;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final colorScheme = Theme.of(context).colorScheme;

            final activeIconColor = isDark
                ? const Color(0xFF60A5FA)
                : colorScheme.primary;
            final inactiveIconColor = isDark
                ? const Color(0xFF94A3B8)
                : colorScheme.onSurfaceVariant;
            final bgSelected = isDark
                ? const Color(0xFF162A4A)
                : colorScheme.primaryContainer;
            final bgUnselected = isDark
                ? const Color(0xFF1E2333)
                : colorScheme.surfaceContainerHigh;
            final borderSelected = isDark
                ? const Color(0xFF3B82F6)
                : colorScheme.primary;
            final borderUnselected = isDark
                ? const Color(0xFF334155)
                : colorScheme.outlineVariant.withValues(alpha: 0.5);
            final textSelected = isDark
                ? Colors.white
                : colorScheme.onPrimaryContainer;
            final textUnselected = isDark
                ? const Color(0xFFE2E8F0)
                : colorScheme.onSurface;

            return ChoiceChip(
              avatar: Icon(
                _getBodyPatternIcon(pattern),
                size: 18,
                color: isSelected ? activeIconColor : inactiveIconColor,
              ),
              label: Text(_getBodyPatternLabel(pattern)),
              selected: isSelected,
              onSelected: (_) =>
                  _updateConfig((c) => c.copyWith(bodyPattern: pattern)),
              showCheckmark: false,
              selectedColor: bgSelected,
              backgroundColor: bgUnselected,
              side: BorderSide(
                color: isSelected ? borderSelected : borderUnselected,
                width: isSelected ? 1.5 : 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              labelPadding: const EdgeInsets.only(right: 6),
              labelStyle: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? textSelected : textUnselected,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Text(
          'Design Presets',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPresetCard(
                'Classic Mono',
                const Color(0xFF000000),
                const Color(0xFFFFFFFF),
                QrBodyPattern.square,
                QrEyeShape.square,
              ),
              _buildPresetCard(
                'Modern Sapphire',
                const Color(0xFF1E40AF),
                const Color(0xFF3B82F6),
                QrBodyPattern.rounded,
                QrEyeShape.rounded,
                useGradient: true,
              ),
              _buildPresetCard(
                'Sunset Glow',
                const Color(0xFFDC2626),
                const Color(0xFFF59E0B),
                QrBodyPattern.dots,
                QrEyeShape.circle,
                useGradient: true,
              ),
              _buildPresetCard(
                'Neon Emerald',
                const Color(0xFF059669),
                const Color(0xFF10B981),
                QrBodyPattern.diamond,
                QrEyeShape.leaf,
                useGradient: true,
              ),
              _buildPresetCard(
                'Cyber Violet',
                const Color(0xFF6D28D9),
                const Color(0xFFEC4899),
                QrBodyPattern.bars,
                QrEyeShape.rounded,
                useGradient: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetCard(
    String name,
    Color color1,
    Color color2,
    QrBodyPattern pattern,
    QrEyeShape eye, {
    bool useGradient = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        _updateConfig(
          (c) => c.copyWith(
            foregroundColor: color1.toARGB32(),
            useGradient: useGradient,
            gradientColor2: color2.toARGB32(),
            bodyPattern: pattern,
            eyeShape: eye,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: useGradient
                    ? LinearGradient(colors: [color1, color2])
                    : null,
                color: useGradient ? null : color1,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: color1.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: EYES ---
  Widget _buildEyesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Corner Eye Outer Frame',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: QrEyeShape.values.map((shape) {
            final isSelected = _item.styleConfig.eyeShape == shape;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final colorScheme = Theme.of(context).colorScheme;

            final activeIconColor = isDark
                ? const Color(0xFF60A5FA)
                : colorScheme.primary;
            final inactiveIconColor = isDark
                ? const Color(0xFF94A3B8)
                : colorScheme.onSurfaceVariant;
            final bgSelected = isDark
                ? const Color(0xFF162A4A)
                : colorScheme.primaryContainer;
            final bgUnselected = isDark
                ? const Color(0xFF1E2333)
                : colorScheme.surfaceContainerHigh;
            final borderSelected = isDark
                ? const Color(0xFF3B82F6)
                : colorScheme.primary;
            final borderUnselected = isDark
                ? const Color(0xFF334155)
                : colorScheme.outlineVariant.withValues(alpha: 0.5);
            final textSelected = isDark
                ? Colors.white
                : colorScheme.onPrimaryContainer;
            final textUnselected = isDark
                ? const Color(0xFFE2E8F0)
                : colorScheme.onSurface;

            return ChoiceChip(
              avatar: Icon(
                _getEyeShapeIcon(shape),
                size: 18,
                color: isSelected ? activeIconColor : inactiveIconColor,
              ),
              label: Text(_getEyeShapeLabel(shape)),
              selected: isSelected,
              onSelected: (_) =>
                  _updateConfig((c) => c.copyWith(eyeShape: shape)),
              showCheckmark: false,
              selectedColor: bgSelected,
              backgroundColor: bgUnselected,
              side: BorderSide(
                color: isSelected ? borderSelected : borderUnselected,
                width: isSelected ? 1.5 : 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              labelPadding: const EdgeInsets.only(right: 6),
              labelStyle: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? textSelected : textUnselected,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text(
          'Corner Eye Inner Eyeball',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: QrEyeballShape.values.map((eyeball) {
            final isSelected = _item.styleConfig.eyeballShape == eyeball;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final colorScheme = Theme.of(context).colorScheme;

            final activeIconColor = isDark
                ? const Color(0xFF60A5FA)
                : colorScheme.primary;
            final inactiveIconColor = isDark
                ? const Color(0xFF94A3B8)
                : colorScheme.onSurfaceVariant;
            final bgSelected = isDark
                ? const Color(0xFF162A4A)
                : colorScheme.primaryContainer;
            final bgUnselected = isDark
                ? const Color(0xFF1E2333)
                : colorScheme.surfaceContainerHigh;
            final borderSelected = isDark
                ? const Color(0xFF3B82F6)
                : colorScheme.primary;
            final borderUnselected = isDark
                ? const Color(0xFF334155)
                : colorScheme.outlineVariant.withValues(alpha: 0.5);
            final textSelected = isDark
                ? Colors.white
                : colorScheme.onPrimaryContainer;
            final textUnselected = isDark
                ? const Color(0xFFE2E8F0)
                : colorScheme.onSurface;

            return ChoiceChip(
              avatar: Icon(
                _getEyeballShapeIcon(eyeball),
                size: 18,
                color: isSelected ? activeIconColor : inactiveIconColor,
              ),
              label: Text(_getEyeballShapeLabel(eyeball)),
              selected: isSelected,
              onSelected: (_) =>
                  _updateConfig((c) => c.copyWith(eyeballShape: eyeball)),
              showCheckmark: false,
              selectedColor: bgSelected,
              backgroundColor: bgUnselected,
              side: BorderSide(
                color: isSelected ? borderSelected : borderUnselected,
                width: isSelected ? 1.5 : 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              labelPadding: const EdgeInsets.only(right: 6),
              labelStyle: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? textSelected : textUnselected,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text(
            'Custom Eye Colors',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          value: _item.styleConfig.customEyeColor,
          onChanged: (v) => _updateConfig((c) => c.copyWith(customEyeColor: v)),
        ),
        if (_item.styleConfig.customEyeColor) ...[
          ListTile(
            title: const Text('Outer Frame Color'),
            trailing: CircleAvatar(backgroundColor: _item.styleConfig.eyeFrame),
            onTap: () => _showColorPicker(
              title: 'Eye Outer Frame Color',
              currentColor: _item.styleConfig.eyeFrame,
              onColorChanged: (col) => _updateConfig(
                (c) => c.copyWith(eyeFrameColor: col.toARGB32()),
              ),
            ),
          ),
          ListTile(
            title: const Text('Inner Eyeball Color'),
            trailing: CircleAvatar(backgroundColor: _item.styleConfig.eyeball),
            onTap: () => _showColorPicker(
              title: 'Inner Eyeball Color',
              currentColor: _item.styleConfig.eyeball,
              onColorChanged: (col) => _updateConfig(
                (c) => c.copyWith(eyeballColor: col.toARGB32()),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // --- TAB 3: COLORS & GRADIENTS ---
  Widget _buildColorsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          title: const Text('Foreground Color'),
          trailing: CircleAvatar(backgroundColor: _item.styleConfig.foreground),
          onTap: () => _showColorPicker(
            title: 'QR Code Color',
            currentColor: _item.styleConfig.foreground,
            onColorChanged: (col) => _updateConfig(
              (c) => c.copyWith(foregroundColor: col.toARGB32()),
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('Use Color Gradient'),
          subtitle: const Text('Blend two vibrant colors across the matrix'),
          value: _item.styleConfig.useGradient,
          onChanged: (v) => _updateConfig((c) => c.copyWith(useGradient: v)),
        ),
        if (_item.styleConfig.useGradient) ...[
          ListTile(
            title: const Text('Secondary Gradient Color'),
            trailing: CircleAvatar(
              backgroundColor: _item.styleConfig.gradient2,
            ),
            onTap: () => _showColorPicker(
              title: 'Gradient Second Color',
              currentColor: _item.styleConfig.gradient2,
              onColorChanged: (col) => _updateConfig(
                (c) => c.copyWith(gradientColor2: col.toARGB32()),
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Radial Gradient (Circular Glow)'),
            value: _item.styleConfig.isRadialGradient,
            onChanged: (v) =>
                _updateConfig((c) => c.copyWith(isRadialGradient: v)),
          ),
        ],
        const Divider(),
        SwitchListTile(
          title: const Text('Transparent Background'),
          subtitle: const Text(
            'Perfect for graphic design overlays & stickers',
          ),
          value: _item.styleConfig.isTransparentBackground,
          onChanged: (v) =>
              _updateConfig((c) => c.copyWith(isTransparentBackground: v)),
        ),
        if (!_item.styleConfig.isTransparentBackground)
          ListTile(
            title: const Text('Background Color'),
            trailing: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _item.styleConfig.background,
                border: Border.all(color: Colors.grey.shade400),
              ),
            ),
            onTap: () => _showColorPicker(
              title: 'Background Color',
              currentColor: _item.styleConfig.background,
              onColorChanged: (col) => _updateConfig(
                (c) => c.copyWith(backgroundColor: col.toARGB32()),
              ),
            ),
          ),
      ],
    );
  }

  // --- TAB 4: LOGO EMBEDDING ---
  Widget _buildLogoTab() {
    final presets = [
      'none',
      'whatsapp',
      'instagram',
      'wifi',
      'phone',
      'mail',
      'link',
      'star',
      'location',
      'cart',
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Preset Brand & Utility Icons',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: presets.map((p) {
            final isNone = p == 'none';
            final isSelected = isNone
                ? _item.styleConfig.logoType == QrLogoType.none
                : (_item.styleConfig.logoType == QrLogoType.preset &&
                      _item.styleConfig.logoPreset == p);
            return GestureDetector(
              onTap: () {
                if (isNone) {
                  _updateConfig(
                    (c) =>
                        c.copyWith(logoType: QrLogoType.none, logoPreset: null),
                  );
                } else {
                  _updateConfig(
                    (c) =>
                        c.copyWith(logoType: QrLogoType.preset, logoPreset: p),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  p.toUpperCase(),
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 10),
        const Text(
          'Custom Logo Image',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _pickCustomLogo,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Choose Logo From Gallery'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  // --- TAB 5: FRAMES & BADGES ---
  Widget _buildFramesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Frame Templates',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: QrFrameType.values.map((frame) {
            final isSelected = _item.styleConfig.frameType == frame;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final colorScheme = Theme.of(context).colorScheme;

            final bgSelected = isDark
                ? const Color(0xFF162A4A)
                : colorScheme.primaryContainer;
            final bgUnselected = isDark
                ? const Color(0xFF1E2333)
                : colorScheme.surfaceContainerHigh;
            final borderSelected = isDark
                ? const Color(0xFF3B82F6)
                : colorScheme.primary;
            final borderUnselected = isDark
                ? const Color(0xFF334155)
                : colorScheme.outlineVariant.withValues(alpha: 0.5);
            final textSelected = isDark
                ? Colors.white
                : colorScheme.onPrimaryContainer;
            final textUnselected = isDark
                ? const Color(0xFFE2E8F0)
                : colorScheme.onSurface;

            return ChoiceChip(
              label: Text(_getFrameTypeLabel(frame)),
              selected: isSelected,
              onSelected: (_) =>
                  _updateConfig((c) => c.copyWith(frameType: frame)),
              showCheckmark: isSelected,
              checkmarkColor: isDark
                  ? const Color(0xFF60A5FA)
                  : colorScheme.primary,
              selectedColor: bgSelected,
              backgroundColor: bgUnselected,
              side: BorderSide(
                color: isSelected ? borderSelected : borderUnselected,
                width: isSelected ? 1.5 : 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              labelStyle: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? textSelected : textUnselected,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            );
          }).toList(),
        ),
        if (_item.styleConfig.frameType != QrFrameType.none) ...[
          const SizedBox(height: 20),
          TextFormField(
            controller: _frameTextController,
            decoration: InputDecoration(
              labelText: 'Call-To-Action (CTA) Text',
              hintText: 'e.g. SCAN ME, FOLLOW US, CONNECT',
            ),
            onChanged: (text) =>
                _updateConfig((c) => c.copyWith(frameText: text)),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Frame Color'),
            trailing: CircleAvatar(backgroundColor: _item.styleConfig.frameBg),
            onTap: () => _showColorPicker(
              title: 'Frame Background Color',
              currentColor: _item.styleConfig.frameBg,
              onColorChanged: (col) =>
                  _updateConfig((c) => c.copyWith(frameColor: col.toARGB32())),
            ),
          ),
          ListTile(
            title: const Text('Frame Text Color'),
            trailing: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _item.styleConfig.frameTextCol,
                border: Border.all(color: Colors.grey.shade400),
              ),
            ),
            onTap: () => _showColorPicker(
              title: 'Frame Text Color',
              currentColor: _item.styleConfig.frameTextCol,
              onColorChanged: (col) => _updateConfig(
                (c) => c.copyWith(frameTextColor: col.toARGB32()),
              ),
            ),
          ),
        ],
      ],
    );
  }

  IconData _getBodyPatternIcon(QrBodyPattern pattern) {
    switch (pattern) {
      case QrBodyPattern.square:
        return Icons.crop_square_rounded;
      case QrBodyPattern.rounded:
        return Icons.rounded_corner_rounded;
      case QrBodyPattern.dots:
        return Icons.circle_rounded;
      case QrBodyPattern.diamond:
        return Icons.diamond_outlined;
      case QrBodyPattern.bars:
        return Icons.table_rows_rounded;
    }
  }

  String _getBodyPatternLabel(QrBodyPattern pattern) {
    switch (pattern) {
      case QrBodyPattern.square:
        return 'Square';
      case QrBodyPattern.rounded:
        return 'Rounded';
      case QrBodyPattern.dots:
        return 'Dots';
      case QrBodyPattern.diamond:
        return 'Diamond';
      case QrBodyPattern.bars:
        return 'Bars';
    }
  }

  IconData _getEyeShapeIcon(QrEyeShape shape) {
    switch (shape) {
      case QrEyeShape.square:
        return Icons.crop_square_rounded;
      case QrEyeShape.rounded:
        return Icons.rounded_corner_rounded;
      case QrEyeShape.circle:
        return Icons.radio_button_unchecked_rounded;
      case QrEyeShape.leaf:
        return Icons.eco_outlined;
    }
  }

  String _getEyeShapeLabel(QrEyeShape shape) {
    switch (shape) {
      case QrEyeShape.square:
        return 'Square';
      case QrEyeShape.rounded:
        return 'Rounded';
      case QrEyeShape.circle:
        return 'Circle';
      case QrEyeShape.leaf:
        return 'Leaf';
    }
  }

  IconData _getEyeballShapeIcon(QrEyeballShape eyeball) {
    switch (eyeball) {
      case QrEyeballShape.square:
        return Icons.square_rounded;
      case QrEyeballShape.circle:
        return Icons.circle_rounded;
      case QrEyeballShape.diamond:
        return Icons.diamond_outlined;
      case QrEyeballShape.dot:
        return Icons.fiber_manual_record_rounded;
    }
  }

  String _getEyeballShapeLabel(QrEyeballShape eyeball) {
    switch (eyeball) {
      case QrEyeballShape.square:
        return 'Square';
      case QrEyeballShape.circle:
        return 'Circle';
      case QrEyeballShape.diamond:
        return 'Diamond';
      case QrEyeballShape.dot:
        return 'Dot';
    }
  }

  String _getFrameTypeLabel(QrFrameType frame) {
    switch (frame) {
      case QrFrameType.none:
        return 'None';
      case QrFrameType.bottomBanner:
        return 'Bottom Banner';
      case QrFrameType.topBanner:
        return 'Top Banner';
      case QrFrameType.speechBubble:
        return 'Speech Bubble';
      case QrFrameType.ticketHeader:
        return 'Ticket Header';
      case QrFrameType.polaroid:
        return 'Polaroid';
      case QrFrameType.badge:
        return 'Badge';
      case QrFrameType.stamp:
        return 'Stamp';
    }
  }
}
