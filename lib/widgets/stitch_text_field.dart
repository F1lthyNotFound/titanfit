import 'package:flutter/material.dart';

class StitchTextField extends StatefulWidget {
  const StitchTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? icon;
  final bool obscureText;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;

  @override
  State<StitchTextField> createState() => _StitchTextFieldState();
}

class _StitchTextFieldState extends State<StitchTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      readOnly: widget.readOnly,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: widget.label?.toUpperCase(),
        labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 0.14,
              color: const Color(0xFF8E9192),
            ),
        hintText: widget.hint,
        filled: true,
        fillColor: const Color(0x66201F1F),
        prefixIcon: widget.icon != null ? Icon(widget.icon, size: 22) : null,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );
  }
}
