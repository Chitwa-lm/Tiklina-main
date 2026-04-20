import 'package:flutter/material.dart';
import 'package:tiklini/services/job_store.dart';

class ReportWasteScreen extends StatefulWidget {
  final bool embedded;
  final void Function(Map<String, dynamic>)? onReportSubmitted;

  const ReportWasteScreen({
    super.key,
    this.embedded = false,
    this.onReportSubmitted,
  });

  @override
  State<ReportWasteScreen> createState() => _ReportWasteScreenState();
}

class _ReportWasteScreenState extends State<ReportWasteScreen> {
  double _volumeValue = 3;
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedCategory = 'Mixed Waste';

  static const _categories = [
    'Mixed Waste',
    'Organic',
    'Plastic',
    'Paper / Cardboard',
    'Glass',
    'Metal',
    'Hazardous',
  ];

  static const _volumeLabels = [
    'Small Bag',
    'Car Trunk',
    'Pickup',
    'Truck Load',
    'Multiple',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: widget.embedded
          ? null
          : AppBar(
              backgroundColor: const Color(0xFFF5F6F7).withValues(alpha: 0.9),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2C2F30)),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Report Waste',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF2C2F30),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 24.0),
                  child: Center(
                    child: const Text(
                      'Tiklina',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                        letterSpacing: -1.0,
                        color: Color(0xFF176A21),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: 120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step 1: Evidence
                const Text(
                  'EVIDENCE',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.5,
                    color: Color(0xFF595C5D),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFABACAE),
                      width: 2,
                      style: BorderStyle.none,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: CustomPaint(
                          painter: DashedRectPainter(
                            color: const Color(0xFFABACAE),
                            strokeWidth: 2,
                            gap: 5,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF9DF197),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.photo_camera,
                                  size: 32,
                                  color: Color(0xFF005C15),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Tap to take a photo',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF2C2F30),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'JPEG or PNG up to 10MB',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                  color: Color(0xFF595C5D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Step 2: Location
                const Text(
                  'INCIDENT LOCATION',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.5,
                    color: Color(0xFF595C5D),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _locationController,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      color: Color(0xFF2C2F30),
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. West Wing Loading Dock',
                      hintStyle: TextStyle(
                        color: const Color(0xFFABACAE).withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.location_on,
                        color: Color(0xFF176A21),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF176A21),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                // Step 3: Details
                const Text(
                  'WASTE DESCRIPTION',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.5,
                    color: Color(0xFF595C5D),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _descController,
                    maxLines: 3,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      color: Color(0xFF2C2F30),
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Describe what you see (e.g. household items, garden waste, chemicals)...',
                      hintStyle: TextStyle(
                        color: const Color(0xFFABACAE).withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF176A21),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'WASTE CATEGORY',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.5,
                    color: Color(0xFF595C5D),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Color(0xFF2C2F30),
                      ),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCategory = val);
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ESTIMATED VOLUME',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.5,
                        color: Color(0xFF595C5D),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9DF197),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _volumeLabels[(_volumeValue - 1).toInt()],
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF005C15),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF1F2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF176A21),
                          inactiveTrackColor: const Color(0xFFDADDDF),
                          trackHeight: 8.0,
                          thumbColor: const Color(0xFF176A21),
                          overlayColor: const Color(
                            0xFF176A21,
                          ).withValues(alpha: 0.2),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 12.0,
                          ),
                        ),
                        child: Slider(
                          value: _volumeValue,
                          min: 1,
                          max: 5,
                          divisions: 4,
                          onChanged: (val) {
                            setState(() {
                              _volumeValue = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(_volumeLabels.length, (i) {
                          return Text(
                            _volumeLabels[i],
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: -0.5,
                              color: Color(0xFF595C5D),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Submission Footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F7).withValues(alpha: 0.8),
              ),
              child: Container(
                width: double.infinity,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF176A21), Color(0xFF025D16)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF176A21).withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    if (_locationController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter the incident location.'),
                        ),
                      );
                      return;
                    }
                    final now = DateTime.now();
                    final date =
                        '${now.day} ${_monthName(now.month)} ${now.year}';
                    final reportData = {
                      'location': _locationController.text.trim(),
                      'description': _descController.text.trim(),
                      'category': _selectedCategory,
                      'volume': _volumeLabels[(_volumeValue - 1).toInt()],
                      'date': date,
                    };
                    widget.onReportSubmitted?.call(reportData);
                    // Publish to shared store so collectors can see it
                    JobStore.instance.addJob(
                      Job(
                        id: '${now.millisecondsSinceEpoch}',
                        marketName: '',
                        location: _locationController.text.trim(),
                        category: _selectedCategory,
                        volume: _volumeLabels[(_volumeValue - 1).toInt()],
                        description: _descController.text.trim(),
                        date: date,
                      ),
                    );
                    if (widget.embedded) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Report submitted successfully.'),
                          backgroundColor: Color(0xFF176A21),
                        ),
                      );
                      _locationController.clear();
                      _descController.clear();
                      setState(() => _volumeValue = 3);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Submit',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFFD1FFC8), // on-primary
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.send, color: Color(0xFFD1FFC8), size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _monthName(int month) {
  const months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month];
}

// Dashed Rectangle Painter
class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    this.color = Colors.black,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(16),
        ),
      );

    // A simple dashed path generic implementation would be needed here,
    // for MVP we use a solid line or simply skip the complex dashed path.
    // Replace with standard border if complex dashed is needed
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
