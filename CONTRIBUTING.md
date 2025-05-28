# Contributing to Flutter Awesome Reels 🤝

Thank you for your interest in contributing to Flutter Awesome Reels! This document provides guidelines and information for contributors.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Git
- A code editor (VS Code, Android Studio, or IntelliJ IDEA recommended)

### Development Setup

1. **Fork the repository**
   ```bash
   # Click the "Fork" button on GitHub, then clone your fork
   git clone https://github.com/your-username/flutter_awesome_reels.git
   cd flutter_awesome_reels
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   cd example
   flutter pub get
   ```

3. **Run the example app**
   ```bash
   cd example
   flutter run
   ```

## 📋 How to Contribute

### 🐛 Reporting Bugs

Before creating bug reports, please check the [existing issues](https://github.com/wailashraf71/flutter_awesome_reels/issues) to avoid duplicates.

**When reporting bugs, please include:**
- Flutter and Dart versions (`flutter --version`)
- Device/Platform information
- Detailed steps to reproduce
- Expected vs actual behavior
- Screenshots or screen recordings if applicable
- Relevant code snippets

### 💡 Suggesting Features

We welcome feature suggestions! Please:
- Check existing issues for similar requests
- Provide a clear description of the feature
- Explain the use case and benefits
- Include mockups or examples if helpful

### 🔧 Code Contributions

#### Branch Naming Convention
- `feature/description` - for new features
- `bugfix/description` - for bug fixes
- `docs/description` - for documentation updates
- `refactor/description` - for code refactoring

#### Pull Request Process

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow the coding standards below
   - Add tests for new functionality
   - Update documentation as needed

3. **Test your changes**
   ```bash
   # Run tests
   flutter test
   
   # Run example app
   cd example
   flutter run
   ```

4. **Commit with descriptive messages**
   ```bash
   git add .
   git commit -m "feat: add long-press pause functionality"
   ```

5. **Push and create PR**
   ```bash
   git push origin feature/your-feature-name
   ```
   Then create a Pull Request on GitHub.

## 📝 Coding Standards

### Code Style

- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter format` to format your code
- Run `flutter analyze` to check for issues
- Add meaningful comments for complex logic

### Documentation

- Document all public APIs with dartdoc comments
- Include usage examples in documentation
- Update README.md for significant changes
- Add entries to CHANGELOG.md

### Testing

- Write unit tests for new functionality
- Test on both iOS and Android
- Test with different screen sizes
- Verify performance impact

### File Organization

```
lib/
├── src/
│   ├── controllers/     # State management
│   ├── models/         # Data models
│   ├── services/       # External services
│   ├── utils/          # Utility functions
│   └── widgets/        # UI components
└── flutter_awesome_reels.dart  # Main export file
```

## 🎯 Areas for Contribution

### High Priority
- Performance optimizations
- Accessibility improvements
- Platform-specific enhancements
- Bug fixes

### Medium Priority
- Additional configuration options
- New animation effects
- Enhanced analytics
- Documentation improvements

### Nice to Have
- Additional example apps
- Integration guides
- Video tutorials
- Translations

## 🔍 Code Review Process

All contributions go through code review:

1. **Automated checks** - CI runs tests and analysis
2. **Maintainer review** - Code quality, design, and functionality
3. **Community feedback** - For significant changes
4. **Testing** - Verify changes work as expected

## 📊 Performance Guidelines

- Keep widget rebuilds to a minimum
- Use `const` constructors where possible
- Implement proper disposal of resources
- Test memory usage with large datasets
- Profile performance with Flutter DevTools

## 🎨 UI/UX Guidelines

- Follow platform conventions (Material Design/Cupertino)
- Ensure accessibility compliance
- Test with different themes (light/dark)
- Consider various screen sizes and orientations
- Maintain smooth animations (60fps)

## 📚 Resources

### Useful Links
- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Material Design Guidelines](https://material.io/design)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)

### Tools
- [Flutter Inspector](https://docs.flutter.dev/development/tools/flutter-inspector)
- [Flutter DevTools](https://docs.flutter.dev/development/tools/devtools/overview)
- [Dart Analysis](https://dart.dev/guides/language/analysis-options)

## 🏷️ Release Process

### Version Numbering
We follow [Semantic Versioning](https://semver.org/):
- MAJOR.MINOR.PATCH (e.g., 1.2.3)
- Breaking changes increment MAJOR
- New features increment MINOR
- Bug fixes increment PATCH

### Release Checklist
- [ ] Update version in `pubspec.yaml`
- [ ] Update `CHANGELOG.md`
- [ ] Run all tests
- [ ] Update documentation
- [ ] Create GitHub release
- [ ] Publish to pub.dev

## 🤔 Questions?

- Check existing [Issues](https://github.com/wailashraf71/flutter_awesome_reels/issues)
- Start a [Discussion](https://github.com/wailashraf71/flutter_awesome_reels/discussions)
- Contact maintainers

## 🎉 Recognition

Contributors will be:
- Listed in the project's contributors
- Credited in release notes for significant contributions
- Invited to join the maintainer team for consistent contributors

Thank you for helping make Flutter Awesome Reels better! 🚀
