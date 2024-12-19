# iOS AR Health Demo

An innovative iOS application that combines Augmented Reality with health report analysis capabilities. This app demonstrates the integration of modern technologies to provide an interactive and informative health monitoring experience.

## Features

### 1. Health Report Analysis
- PDF report processing with OCR capabilities
- Automatic extraction of health metrics:
  - General examination data
  - Blood routine examination
  - Urine routine examination
- Detailed report visualization with reference ranges
- Historical report tracking

### 2. AR Body Visualization
- 3D body model visualization using ARKit
- Interactive AR experience
- Anatomical structure display

### 3. Data Processing
- Advanced OCR using Tesseract
- Intelligent data extraction and categorization
- Structured data storage and management

## Technical Stack

- **Framework**: UIKit, ARKit
- **OCR Engine**: TesseractOCR
- **PDF Processing**: PDFKit, Vision
- **Data Persistence**: UserDefaults (local storage)
- **Dependencies**: CocoaPods

## Requirements

- iOS 13.0+
- Xcode 12.0+
- Swift 5.0+
- CocoaPods

## Installation

1. Clone the repository
```bash
git clone https://github.com/sun409377708/iOSARDemo.git
```

2. Install dependencies using CocoaPods
```bash
cd iOSARDemo
pod install
```

3. Open the workspace
```bash
open iOSARDemo.xcworkspace
```

4. Build and run the project in Xcode

## Usage

1. **Health Report Analysis**
   - Import PDF health reports
   - View detailed analysis of health metrics
   - Track historical health data

2. **AR Visualization**
   - Experience 3D body model in AR
   - Interact with anatomical structures
   - View detailed information in augmented reality

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- ARKit for providing powerful AR capabilities
- Tesseract OCR for text recognition
- Vision framework for advanced image processing
