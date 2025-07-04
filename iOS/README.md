# ACE RFID iOS App

An iOS application for managing 3D printing filament using RFID/NFC tags, specifically designed for Anycubic ACE 3D printers.

## Features

- **NFC/RFID Tag Reading & Writing**: Read and write filament information to NFC tags
- **Filament Database**: Store and manage detailed filament information
- **Material Support**: Support for various filament types (PLA, ABS, PETG, TPU, etc.)
- **Temperature Profiles**: Store print and bed temperature settings for each filament
- **Weight Tracking**: Track filament weight and remaining amount
- **Usage History**: Track when filaments were last used
- **Core Data Integration**: Local data persistence using Core Data

## Requirements

- iOS 13.0+
- iPhone/iPad with NFC capability (for NFC features)
- Xcode 12.0+
- Swift 5.0+

## Installation

1. Clone this repository
2. Open `ACE-RFID.xcodeproj` in Xcode
3. Select your development team in the project settings
4. Build and run the project on your device

## Usage

### Adding Filaments

1. Tap the "+" button in the navigation bar
2. Fill in the filament details:
   - Brand name
   - Material type (PLA, ABS, PETG, etc.)
   - Color
   - Weight in grams
   - Diameter (typically 1.75mm)
   - Print temperature
   - Bed temperature
   - Fan speed and print speed
   - Optional notes
3. Tap "Save" to store the filament

### Reading NFC Tags

1. Tap the NFC icon in the navigation bar
2. Hold your iPhone near the NFC tag
3. The app will automatically read and add the filament to your database

### Writing to NFC Tags

1. Long press on a filament in the list or tap "Write to NFC Tag"
2. Hold your iPhone near a writable NFC tag
3. The filament information will be written to the tag

### Managing Filaments

- Tap on any filament to see options (Edit, Write to NFC, Mark as Used, Delete)
- Swipe left on a filament to quickly delete it
- Use pull-to-refresh to update the filament list

## Data Model

Each filament stores the following information:

- **Basic Info**: Brand, material, color, diameter
- **Weight**: Total weight and remaining weight
- **Temperature Settings**: Print temperature, bed temperature
- **Print Settings**: Fan speed, print speed
- **Metadata**: Date added, last used date, finished status
- **Notes**: Optional user notes

## NFC Tag Format

The app stores filament data as JSON in NDEF text records on NFC tags. The data includes all filament properties and can be read by compatible devices.

## Privacy

All filament data is stored locally on your device using Core Data. No data is transmitted to external servers.

## Architecture

The app follows the MVC (Model-View-Controller) pattern:

- **Models**: `Filament` struct with Core Data integration
- **Views**: Custom table view cells and form components
- **Controllers**: Main view controller and add/edit view controller
- **Services**: NFC service for tag reading/writing, Core Data manager

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Inspired by the need for better filament management in 3D printing
- Built for compatibility with Anycubic ACE 3D printers
- Uses Apple's Core NFC framework for NFC functionality
