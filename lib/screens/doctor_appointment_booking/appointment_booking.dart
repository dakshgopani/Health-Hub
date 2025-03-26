import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/doctor_data_model.dart';
import '../../services/email.dart';
import '../../services/pdf.dart';
import '../../services/payment_gateway.dart';

class AppointmentBookingScreen extends StatefulWidget {
  final Doctor selectedDoctor;
  final double fee;

  const AppointmentBookingScreen(
      {Key? key, required this.selectedDoctor, required this.fee})
      : super(key: key);

  @override
  _AppointmentBookingScreenState createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _userEmail;
  String? _selectedPaymentMethod;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF432C81),
              onPrimary: Colors.white,
              onSurface: Color(0xFF432C81),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF432C81),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF432C81),
              onPrimary: Colors.white,
              onSurface: Color(0xFF432C81),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF432C81),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  void _showPaymentMethodDialog() async {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Select Payment Method',
                style: TextStyle(
                    fontFamily: 'Raleway',
                    color: Color(0xFF432C81),
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPaymentMethodDialogOption(
                      'Cash', Icons.money, setState),
                  _buildPaymentMethodDialogOption(
                      'Card', Icons.credit_card, setState),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
                TextButton(
                  onPressed: () {
                    if (_selectedPaymentMethod != null) {
                      Navigator.pop(context);
                      _bookAppointment();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please select a payment method')),
                      );
                    }
                  },
                  child: const Text('Confirm',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _bookAppointment() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final String formattedDate =
          "${_selectedDate?.day}/${_selectedDate?.month}/${_selectedDate?.year}";
      final String formattedTime =
          "${_selectedTime?.hour.toString().padLeft(2, '0')}:${_selectedTime?.minute.toString().padLeft(2, '0')}";

      if (_selectedPaymentMethod == 'Cash') {
        _confirmAppointment(formattedDate, formattedTime);
      } else if (_selectedPaymentMethod == 'Card') {
        _proceedToPayment(formattedDate, formattedTime);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please fill all fields and select a payment method.')),
      );
    }
  }

  void _confirmAppointment(String date, String time) async {
    final pdfFile = await PdfService.generateAppointmentPdf(
      email: _userEmail!,
      doctorName: widget.selectedDoctor.name,
      appointmentDate: date,
      appointmentTime: time,
    );

    try {
      await EmailService.sendEmail(_userEmail!, pdfFile);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Appointment confirmation sent to $_userEmail!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send email: $e')),
      );
    }

    setState(() {
      _selectedDate = null;
      _selectedTime = null;
      _userEmail = null;
      _selectedPaymentMethod = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appointment booked successfully!')),
    );
  }

  void _proceedToPayment(String date, String time) async {
    final bool paymentSuccess = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CheckoutPage(fee: widget.fee)),
    );

    if (paymentSuccess) {
      _confirmAppointment(date, time);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment failed. Please try again.')),
      );
    }
  }

  Widget _buildPaymentMethodDialogOption(
      String method, IconData icon, void Function(void Function()) setState) {
    return RadioListTile<String>(
      title: Row(
        children: [
          Icon(icon, color: const Color(0xFF432C81)),
          const SizedBox(width: 10),
          Text(method,
              style: const TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ],
      ),
      value: method,
      groupValue: _selectedPaymentMethod,
      onChanged: (value) {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      activeColor: const Color(0xFF432C81),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: AnimationLimiter(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 375),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: widget,
                          ),
                        ),
                        children: [
                          _buildDoctorInfo(),
                          const SizedBox(height: 24),
                          _buildEmailField(),
                          const SizedBox(height: 24),
                          _buildDateTimePicker(
                              'Date',
                              _selectedDate?.toString().split(' ')[0] ??
                                  'Select Date',
                              _pickDate),
                          const SizedBox(height: 16),
                          _buildDateTimePicker(
                              'Time',
                              _selectedTime?.format(context) ?? 'Select Time',
                              _pickTime),
                          const SizedBox(height: 32),
                          _buildBookButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFf5f3ff),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: Colors.black,
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Book Appointment',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontFamily: 'Raleway',
                color: Color(0xFF432C81),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildDoctorInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF432C81),
            child: Text(
              widget.selectedDoctor.name[0].toUpperCase(),
              style: const TextStyle(fontSize: 24, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.selectedDoctor.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Raleway',
                    color: Color(0xFF432C81),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.selectedDoctor.specialization,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Enter Your Email',
        labelStyle: TextStyle(
            color: Colors.grey[600],
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.email, color: Color(0xFF432C81)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF432C81)),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      style: TextStyle(
          fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w700),
      onChanged: (value) => _userEmail = value,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter your email';
        if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value))
          return 'Please enter a valid email address';
        return null;
      },
    );
  }

  Widget _buildDateTimePicker(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Raleway',
                color: Color(0xFF432C81),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w700,
                fontFamily: 'Raleway',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookButton() {
    return ElevatedButton(
      onPressed: _showPaymentMethodDialog,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF432C81),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Book Appointment',
        style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Raleway',
            color: Colors.white),
      ),
    );
  }
}
