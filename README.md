# Wordle Solver

A multi-language Wordle solver app built with Flutter that provides intelligent word recommendations and feedback-driven filtering to help you solve Wordle puzzles efficiently.

## 🌟 Features

- **Multi-Language Support**: English and Spanish dictionaries included
- **Intelligent Recommendations**: Advanced scoring algorithm based on letter frequency analysis
- **Dynamic Feedback System**: Tap-to-color interface for quick feedback input
- **Adaptive Word Length**: Support for custom word lengths (not just 5-letter words)
- **Prefix Support**: Find words with specific starting letters
- **Filler Word Analysis**: Discover optimal words to uncover new letters
- **Responsive Design**: Beautiful UI that adapts to any device
- **Cross-Platform**: Runs on iOS, Android, Web, Windows, macOS, and Linux

## 🏗️ Architecture

This app follows a **Clean Architecture** pattern with a client-server model:

### Frontend (Flutter)
- **Clean Architecture** with Repository pattern
- **Riverpod/BLoC** for state management
- **Responsive UI** with adaptive components
- **Dynamic grid** that adjusts to word length
- **Tap-to-color feedback** system

### Backend (Planned - Firebase)
- **Python Cloud Functions** for solver engine
- **Firestore** for user feedback and data
- **Cloud Storage** for dictionary management
- **Firebase Authentication** (anonymous by default)

## 📱 UI/UX Design

- **Dynamic Input Grid**: Automatically adjusts to specified word length
- **Tap-to-Color Feedback**: Quick feedback input (Gray → Yellow → Green)
- **Smart Recommendations**: Top-ranked word suggestions with scores
- **Remaining Words Display**: Shows possible solutions as they narrow down
- **Filler Word Suggestions**: Helps discover new letters efficiently
- **Clean, Modern Interface**: Intuitive design following platform conventions

## 🎯 How It Works

### Core Algorithm

1. **Letter Frequency Analysis**: Calculates frequency of letters in the dictionary
2. **Word Scoring**: Ranks words based on common letters and strategic value
3. **Feedback Processing**: Filters possible words using Wordle's rules:
   - **Green (G)**: Letter is correct and in the right position
   - **Yellow (Y)**: Letter is in the word but wrong position
   - **Black/Gray (B)**: Letter is not in the word (or appears too many times)

### Smart Features

- **Variable Letter Detection**: Identifies positions where letters vary across remaining words
- **Filler Word Optimization**: Suggests words to maximize new letter discovery
- **Progressive Filtering**: Narrows down possibilities with each guess
- **Duplicate Letter Handling**: Accounts for words with repeated letters

## 📚 Dictionaries

The app includes comprehensive word dictionaries:

- **English**: `assets/words/english.json` - Extensive English word list
- **Spanish**: `assets/words/spanish.json` - Comprehensive Spanish dictionary

Dictionaries are stored as JSON arrays for fast loading and processing.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Your favorite IDE (VS Code, Android Studio, etc.)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/dev-ro/wordle_solver.git
   cd wordle_solver
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Usage

1. **Start a new game** - The app will show recommended starting words
2. **Enter your guess** - Type a word or select from recommendations
3. **Provide feedback** - Tap tiles to cycle through colors (Gray → Yellow → Green)
4. **Get next suggestions** - The app filters possibilities and suggests optimal next moves
5. **Repeat until solved** - Continue until you find the target word

## 🔧 Configuration

### Custom Word Length
The app supports variable word lengths for different Wordle variants.

### Prefix Support
Perfect for games like Twitch Wordle where words must start with specific letters.

### Dictionary Selection
Easy switching between English and Spanish dictionaries.

## 🎮 Game Modes

- **Standard Wordle**: 5-letter words, no prefix
- **Custom Length**: Any word length (3-8+ letters)
- **Prefix Mode**: Words starting with specific letters
- **Multi-Language**: English and Spanish support

## 📊 Algorithm Details

### Scoring System

Words are scored based on:
- **Letter frequency** in the target dictionary
- **Unique letter count** (for early guesses)
- **Position-specific analysis**
- **Strategic value** for information gathering

### Optimization Features

- **Progressive difficulty**: Different strategies for early vs. late game
- **Duplicate handling**: Smart processing of repeated letters
- **Contextual recommendations**: Adapts to remaining word pool

## 🔮 Future Features

- **Cloud-based solving**: Server-side processing for complex analysis
- **User feedback system**: Community-driven dictionary improvements
- **Statistics tracking**: Personal solving statistics and trends
- **Social features**: Share results and compete with friends
- **Advanced analytics**: Deep insights into solving patterns

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by the original Wordle game by Josh Wardle
- Built with Flutter and the amazing Dart ecosystem
- Dictionary data sourced from open-source word lists
- Special thanks to the Flutter community for excellent packages and resources

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/dev-ro/wordle_solver/issues)
- **Discussions**: [GitHub Discussions](https://github.com/dev-ro/wordle_solver/discussions)
- **Repository**: [GitHub Repository](https://github.com/dev-ro/wordle_solver)

---

**Happy Wordling!** 🎉

*Built with ❤️ using Flutter*