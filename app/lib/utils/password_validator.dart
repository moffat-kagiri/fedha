// lib/utils/password_validator.dart
class PasswordValidator {
  static const int minLength = 8;
  
  /// Enhanced password validation with detailed results
  PasswordValidationResult validatePassword(String password) {
    final result = PasswordValidationResult();
    
    if (password.isEmpty) {
      return result;
    }
    
    // Check length
    result.hasMinLength = password.length >= minLength;
    
    // Check for uppercase
    result.hasUppercase = password.contains(RegExp(r'[A-Z]'));
    
    // Check for lowercase
    result.hasLowercase = password.contains(RegExp(r'[a-z]'));
    
    // Check for numbers
    result.hasNumber = password.contains(RegExp(r'[0-9]'));
    
    // Check for special characters
    result.hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    // Calculate overall validity
    result.isValid = result.hasMinLength && 
                    result.hasUppercase && 
                    result.hasLowercase && 
                    result.hasNumber && 
                    result.hasSpecialChar;
    
    // Determine strength
    int strengthScore = 0;
    if (result.hasMinLength) strengthScore++;
    if (result.hasUppercase) strengthScore++;
    if (result.hasLowercase) strengthScore++;
    if (result.hasNumber) strengthScore++;
    if (result.hasSpecialChar) strengthScore++;
    
    if (strengthScore <= 2) {
      result.strength = 'weak';
    } else if (strengthScore <= 4) {
      result.strength = 'medium';
    } else {
      result.strength = 'strong';
    }
    
    return result;
  }
  
  /// Legacy method for backward compatibility
  static bool isValid(String password) {
    // For backward compatibility, use less strict validation
    return password.length >= 6 && 
           RegExp(r'[a-zA-Z]').hasMatch(password) && 
           RegExp(r'[0-9]').hasMatch(password);
  }
  
  String? getPasswordErrorMessage(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }
    
    final result = validatePassword(password);
    
    if (!result.hasMinLength) {
      return 'Password must be at least $minLength characters long';
    }
    
    if (!result.hasUppercase) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!result.hasLowercase) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!result.hasNumber) {
      return 'Password must contain at least one number';
    }
    
    if (!result.hasSpecialChar) {
      return 'Password must contain at least one special character';
    }
    
    return null; // Password is valid
  }
  
  List<String> getPasswordRequirements() {
    return [
      'At least $minLength characters long',
      'Contains uppercase letter (A-Z)',
      'Contains lowercase letter (a-z)',
      'Contains number (0-9)',
      'Contains special character (!@#\$%^&*)',
    ];
  }
  
  // Legacy static methods for backward compatibility
  static String? getErrorMessage(String password) {
    final validator = PasswordValidator();
    return validator.getPasswordErrorMessage(password);
  }
  
  static List<String> getUnmetRequirements(String password) {
    final validator = PasswordValidator();
    final result = validator.validatePassword(password);
    final List<String> unmet = [];
    
    if (!result.hasMinLength) {
      unmet.add('At least ${PasswordValidator.minLength} characters');
    }
    if (!result.hasUppercase) {
      unmet.add('Uppercase letter');
    }
    if (!result.hasLowercase) {
      unmet.add('Lowercase letter');
    }
    if (!result.hasNumber) {
      unmet.add('Number');
    }
    if (!result.hasSpecialChar) {
      unmet.add('Special character');
    }
    
    return unmet;
  }
}

class PasswordValidationResult {
  bool hasMinLength = false;
  bool hasUppercase = false;
  bool hasLowercase = false;
  bool hasNumber = false;
  bool hasSpecialChar = false;
  bool isValid = false;
  String strength = 'weak';
}

class PasswordValidatorStatic {
  /// Gets validation error message for invalid passwords
  static String? getErrorMessage(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }
    
    if (password.length < PasswordValidator.minLength) {
      return 'Password must be at least ${PasswordValidator.minLength} characters';
    }
    
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
      return 'Password must contain at least one letter';
    }
    
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one number';
    }
    
    return null; // Password is valid
  }
  
  /// Gets a list of requirements that are not met
  static List<String> getUnmetRequirements(String password) {
    List<String> unmet = [];
    
    if (password.length < PasswordValidator.minLength) {
      unmet.add('At least ${PasswordValidator.minLength} characters');
    }
    
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
      unmet.add('At least one letter (a-z, A-Z)');
    }
    
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      unmet.add('At least one number (0-9)');
    }
    
    return unmet;
  }
}
