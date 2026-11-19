# Contributing to HealthHub

Thank you for your interest in contributing to HealthHub! This document provides guidelines and instructions for contributing.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment. Be constructive, professional, and adhere to Flutter/Dart best practices.

## How to Contribute

### Reporting Issues

If you find a bug or have a feature request, please create an issue with:

- A clear, descriptive title
- Steps to reproduce (for bugs)
- Expected behavior
- Actual behavior
- Screenshots or logs if applicable
- Your environment (OS, Flutter version, device info)

### Pull Requests

1. Fork the repository
2. Create your feature branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. Make your changes
4. Run tests to ensure your changes don't break existing functionality:
   ```bash
   flutter test
   ```
5. Commit your changes with a clear message:
   ```bash
   git commit -m "Add: description of your changes"
   ```
6. Push to your branch:
   ```bash
   git push origin feature/your-feature-name
   ```
7. Open a Pull Request against the `main` branch

### Coding Standards

- Follow Flutter's Dart conventions
- Use meaningful variable and function names
- Write clear, concise comments where necessary
- Format code using `flutter format`
- Ensure all new code has corresponding tests

## Project Structure

When adding new features:

- Place new screens in `lib/screens/`
- Place new models in `lib/models/`
- Place new services in `lib/services/`
- Place new widgets in `lib/widgets/`

## Testing

All new features should include tests:

- Unit tests for business logic in `test/`
- Widget tests for UI components

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## Questions?

Feel free to open an issue for any questions or clarifications about contributing.