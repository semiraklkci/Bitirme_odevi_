# 🏛️ Historical Artifact Recognition App

An AI-powered mobile application that recognizes historical artifacts and monuments from Turkey using the device camera, and provides rich storytelling about each artifact through a unique narrator character.

---

## 📱 Download

**[⬇️ Download APK (Android)](https://github.com/semiraklkci/Bitirme_odevi_/releases/tag/v1.0)**

https://github.com/semiraklkci/Bitirme_odevi_/releases/tag/v1.0

> Requires Android 6.0 or higher. Allow installation from unknown sources before installing.

---

## 🚀 Features

- 📸 **Instant Recognition** — Point your camera at a historical artifact and the app identifies it automatically
- 🤖 **Dual AI System** — A custom-trained TFLite model works as the primary recognizer; OpenAI GPT-4o Mini is used as a fallback for unknown artifacts
- 🎭 **Narrator Characters** — Each artifact type has a unique storytelling character (Ottoman palace servant, wise imam, ancient soldier, archaeologist, etc.)
- 🔊 **Voice Narration** — The story is read aloud in Turkish using text-to-speech
- 📖 **5-Scene Storytelling** — Every artifact is presented through 5 engaging narrative scenes covering history, legends, and visitor tips

---

## 🛠️ Technologies Used

| Technology | Purpose |
|---|---|
| Flutter | Mobile application framework |
| TFLite (tflite_flutter) | On-device artifact recognition model |
| OpenAI GPT-4o Mini | Fallback recognition & story generation |
| Flutter TTS | Turkish voice narration |
| Camera | Live camera feed |
| Lottie | Narrator character animations |

---

## 🧠 How It Works

```
Camera Feed
    ↓
TFLite Model (Turkish historical artifacts)
    ↓
Confidence Score > 0.85?
    ├── YES → Send artifact name to OpenAI (no image, saves cost)
    ├── 0.50–0.85 → Send image + hint to OpenAI
    └── < 0.50 → Send image only to OpenAI for full analysis
         ↓
    OpenAI generates 5-scene story with narrator character
         ↓
    Voice narration + animated display
```

---

## 📂 Project Structure

```
lib/
  main.dart          # Main application code
assets/
  eser_tanima.tflite # Custom trained TFLite model
  siniflar.json      # Artifact class labels
  karakter.json      # Lottie narrator animation
pubspec.yaml         # Flutter dependencies
Untitled11.ipynb     # Model training notebook (Google Colab)
```

---

## 🔧 Run From Source

```bash
git clone https://github.com/semiraklkci/Bitirme_odevi_.git
cd Bitirme_odevi_
flutter pub get
# Add your OpenAI API key in lib/main.dart
flutter run
```

---

*Developed as a graduation project — 2026*
