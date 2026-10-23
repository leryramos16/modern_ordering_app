/// Validation rules shared by the Flutter app and the backend.
/// Each function returns null when the value is valid, or an error message.
class Validators {
  Validators._();

  static final _nameRegex = RegExp(r'^[\p{L} ]+$', unicode: true);
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _hasLetter = RegExp(r'[A-Za-z]');
  static final _hasNumber = RegExp(r'\d');

  static String? name(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Name is required';
    if (name.length < 2) return 'Name is too short';
    if (name.length > 50) return 'Name must be 50 characters or less';
    if (!_nameRegex.hasMatch(name)) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(email)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (!_hasLetter.hasMatch(password)) {
      return 'Password must contain a letter';
    }
    if (!_hasNumber.hasMatch(password)) {
      return 'Password must contain a number';
    }
    return null;
  }

  static String? productName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Enter product name';
    if (name.length > 150) return 'Name is too long (max 150 characters)';
    return null;
  }

  static String? price(String? value) {
    final price = double.tryParse(value?.trim() ?? '');
    if (price == null) return 'Enter a valid price';
    if (price <= 0) return 'Price must be more than 0';
    if (price >= 100000000) return 'Price is too high';
    return null;
  }

  static String? categoryName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Enter category name';
    if (name.length > 100) return 'Name is too long (max 100 characters)';
    return null;
  }
}
