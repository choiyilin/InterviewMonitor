<!--
README.md
InterviewMonitor

Main project documentation and user guide

FUNCTIONS:
- Explains project purpose (overlay detection for anti-cheating in interviews)
- Provides installation and build instructions for developers
- Documents usage guidelines and testing procedures
- Covers security considerations and privacy compliance
- Includes troubleshooting guide for common issues
- Details system requirements and permissions needed
- Explains project structure and key components

Created by WingLik Choi on 7/16/25.
-->

# Interview Monitor

A macOS application designed to detect overlay usage and unauthorized screen modifications during interviews and examinations to prevent cheating.

## Overview

Interview Monitor is a third-party security application that monitors screen overlays and unauthorized applications during online interviews or examinations. The application runs as a background service to detect potential cheating attempts through screen overlays, unauthorized window manipulations, and suspicious application behavior.

## Features

### Core Functionality
- **Overlay Detection**: Real-time monitoring of screen overlays and unauthorized window layering
- **Application Monitoring**: Detection of suspicious applications running during interviews
- **Screen Integrity Verification**: Ensures screen content authenticity and detects modifications
- **Background Operation**: Runs silently without interfering with legitimate interview processes
- **Security Reporting**: Generates detailed reports of detected anomalies

### Security Measures
- Detects unauthorized screen overlays
- Monitors window manipulation attempts
- Identifies suspicious application launches
- Tracks screen recording and screenshot attempts
- Validates screen content integrity

## Requirements

### System Requirements
- **macOS**: 10.15 (Catalina) or later
- **Xcode**: 12.0 or later for building from source
- **Swift**: 5.3 or later
- **Memory**: 100MB RAM minimum
- **Disk Space**: 50MB available storage

### Permissions Required
- **Screen Recording**: Required for overlay detection
- **Accessibility**: Needed for window monitoring
- **Privacy**: Application monitoring permissions

## Installation

### Building from Source (Recommended)

1. **Clone the Repository**
   ```bash
   git clone https://github.com/choiyilin/InterviewMonitor.git
   cd interview-monitor
   ```

2. **Open in Xcode**
   ```bash
   open InterviewMonitor/InterviewMonitor.xcodeproj
   ```

3. **Configure Build Settings**
   - Set your development team
   - Configure code signing
   - Verify macOS deployment target

4. **Build and Run**
   - Select your target device
   - Press `Cmd+R` to build and run
   - Grant required permissions when prompted

### Pre-built Binary
Download the latest release from the releases section and follow the installation instructions.

## Usage

### Starting the Monitor
```bash
# Launch the application
open InterviewMonitor.app

# Or run from command line
./InterviewMonitor
```

### Configuration
The application can be configured through:
- System preferences integration
- Configuration file: `~/Library/Application Support/InterviewMonitor/config.json`
- Command line arguments for automated deployment

### Integration with Interview Platforms
Interview Monitor can be integrated with various interview platforms:
- Standalone monitoring mode
- API integration for real-time reporting
- Custom webhook support for security alerts

## Project Structure

```
interview-monitor/
├── Sources/
│   └── InterviewMonitor/
│       ├── Controllers/          # View controllers
│       ├── Models/              # Data models
│       ├── Views/               # UI components
│       ├── Services/            # Core monitoring services
│       ├── Extensions/          # Swift extensions
│       └── Utilities/           # Helper functions
├── Resources/
│   ├── Assets.xcassets/         # App icons and images
│   └── Storyboards/            # Interface Builder files
├── Tests/
│   ├── Unit/                   # Unit tests
│   └── UI/                     # UI tests
├── Tools/
│   └── cleaner/                # Utility scripts
└── InterviewMonitor/           # Xcode project files
```

## Development

### Building for Development
```bash
# Navigate to project directory
cd interview-monitor

# Open in Xcode
open InterviewMonitor/InterviewMonitor.xcodeproj

# Run tests
xcodebuild test -scheme InterviewMonitor
```

### Key Components

#### Overlay Detection Service
- **Location**: `Sources/InterviewMonitor/Services/OverlayDetectionService.swift`
- **Purpose**: Core overlay detection and monitoring
- **Dependencies**: Core Graphics, ApplicationServices

#### Security Monitor
- **Location**: `Sources/InterviewMonitor/Services/SecurityMonitor.swift`
- **Purpose**: Comprehensive security monitoring
- **Features**: Process monitoring, window tracking, screen integrity

#### Report Generator
- **Location**: `Sources/InterviewMonitor/Services/ReportGenerator.swift`
- **Purpose**: Security incident reporting
- **Output**: JSON reports, real-time alerts

## Security Considerations

### Privacy Protection
- All monitoring data is processed locally
- No sensitive information is transmitted without consent
- Temporary data is securely disposed after use
- User privacy is maintained throughout the process

### Compliance
- Designed to comply with educational testing standards
- Supports FERPA and privacy regulations
- Audit trail capabilities for compliance reporting

## Troubleshooting

### Common Issues

**Permission Denied Errors**
- Ensure Screen Recording permission is granted
- Check Accessibility permissions in System Preferences
- Restart the application after granting permissions

**Overlay Detection Not Working**
- Verify macOS version compatibility
- Check for conflicting security software
- Ensure proper code signing certificates

**Performance Issues**
- Monitor CPU and memory usage
- Adjust detection sensitivity settings
- Close unnecessary background applications

### Debug Mode
Enable debug logging by setting the environment variable:
```bash
export INTERVIEW_MONITOR_DEBUG=1
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For technical support and questions:
- Create an issue in the GitHub repository
- Contact the development team
- Review the troubleshooting section above

## Disclaimer

This application is designed for legitimate security monitoring purposes during interviews and examinations. Users must ensure compliance with applicable laws and regulations in their jurisdiction. The developers are not responsible for misuse of this software.