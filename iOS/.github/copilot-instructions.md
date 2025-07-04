<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# ACE RFID iOS App Instructions

This is a fully functional iOS Swift project for managing 3D printing filament using RFID/NFC tags for Anycubic ACE 3D printers. The app is complete and ready for production use.

## Project Status: ✅ COMPLETE

The app successfully builds and runs on both iOS simulator and device. All core functionality has been implemented and tested.

## Architecture & Technologies

- **Language**: Swift 5.0+ with iOS 13.0+ minimum deployment target
- **UI Framework**: UIKit with programmatic layout (no Storyboards except LaunchScreen)
- **Architecture**: MVC pattern with clear separation of concerns
- **Data Persistence**: Core Data with FilamentDataModel
- **NFC**: Core NFC framework (requires paid Apple Developer account for device testing)
- **Project Structure**: Organized folders (Models, Views, Controllers, Services, Core Data, Resources)

## Implemented Features ✅

### Core Functionality
- ✅ **Filament Management**: Full CRUD operations for filament records
- ✅ **NFC Integration**: Read/write filament data to/from NFC tags (device only)
- ✅ **Core Data Persistence**: Local database with proper data modeling
- ✅ **Material-Specific Defaults**: Intelligent temperature and speed suggestions

### User Interface
- ✅ **Brand Selection**: 18 predefined brands (Anycubic, Hatchbox, Overture, etc.)
- ✅ **Color Picker**: 23 common colors with visual color swatches
- ✅ **Material Picker**: 10 material types (PLA, ABS, PETG, TPU, etc.)
- ✅ **Smart Defaults**: Auto-fill weight (1000g), diameter (1.75mm), temperatures, speeds
- ✅ **Form Validation**: Comprehensive input validation with user-friendly errors
- ✅ **Responsive UI**: Scroll views, keyboard handling, picker toolbars

### Data Model
- ✅ **Filament Struct**: Complete model with all necessary properties
- ✅ **Brand Enum**: 18 popular 3D printing filament brands
- ✅ **Material Enum**: Material types with specific default settings
- ✅ **Color Enum**: Color palette with UIColor mappings for visual swatches
- ✅ **JSON Serialization**: For NFC tag data storage and retrieval

### NFC Capabilities
- ✅ **NFC Service**: Complete implementation with proper error handling
- ✅ **Simulator Support**: Mock methods for testing without NFC hardware
- ✅ **Device Detection**: Context-aware messages for different environments
- ✅ **Entitlements**: Configured for both free and paid developer accounts

## Key Files & Components

### Models
- `Filament.swift` - Complete data model with enums for Brand, Material, Color
- `CoreDataManager.swift` - Core Data stack management and operations

### Views
- `FilamentTableViewCell.swift` - Custom table view cell for filament display
- `MainViewController.swift` - Primary interface with table view and NFC controls
- `AddEditFilamentViewController.swift` - Form interface with advanced pickers

### Services
- `NFCService.swift` - NFC tag reading/writing with simulator fallbacks

### Core Data
- `FilamentDataModel.xcdatamodeld` - Core Data model with proper versioning

## Development Guidelines

### Code Standards ✅
- Swift naming conventions followed throughout
- Comprehensive error handling with user-friendly messages
- Proper memory management and retain cycle prevention
- Clear separation of concerns (MVC pattern)
- Meaningful variable and function names
- Extensive comments for complex logic

### UI/UX Standards ✅
- iOS Human Interface Guidelines compliance
- Programmatic Auto Layout with proper constraints
- Accessibility considerations
- Dark mode support
- Professional color scheme and typography
- Intuitive navigation and user flows

### Data Management ✅
- Core Data best practices
- Proper data validation
- JSON serialization for NFC storage
- Default value management
- Material-specific intelligent defaults

## Build & Deployment

### Requirements Met ✅
- Xcode project properly configured
- All dependencies resolved
- No build errors or warnings
- Simulator and device builds successful
- Proper code signing setup

### Testing Status ✅
- Simulator testing: ✅ Complete
- NFC functionality: ✅ Implemented (requires device + paid account)
- Form validation: ✅ Tested
- Core Data operations: ✅ Tested
- UI responsiveness: ✅ Tested

## Future Enhancements (Optional)

While the app is feature-complete, potential enhancements could include:
- Additional filament brands
- More color options
- Export/import functionality
- Cloud synchronization
- Apple Watch companion app
- Advanced printing statistics

## Development Notes

- NFC functionality requires a paid Apple Developer account for device testing
- The app gracefully handles NFC unavailability (free accounts, simulator)
- All core features work without NFC for comprehensive testing
- Project structure follows iOS best practices for maintainability
- Code is well-documented and follows Swift conventions
