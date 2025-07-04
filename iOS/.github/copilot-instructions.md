<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# ACE RFID iOS App Instructions

This is an iOS Swift project for managing 3D printing filament using RFID/NFC tags for Anycubic ACE 3D printers.

## Project Guidelines

- Use Swift 5.0+ and iOS 13.0+ as minimum deployment target
- Follow iOS Human Interface Guidelines
- Use Core NFC framework for NFC tag reading/writing
- Use Core Data for local data persistence
- Implement proper error handling and user feedback
- Use UIKit for the user interface
- Follow MVC or MVVM architecture patterns
- Ensure proper memory management and avoid retain cycles
- Use proper access control and encapsulation
- Implement proper validation for filament data

## Key Features

- NFC tag reading and writing for filament information
- Filament database management (brand, material, color, weight, temperature settings)
- User-friendly interface for filament management
- Data persistence using Core Data
- Support for multiple filament types (PLA, ABS, PETG, etc.)

## Development Standards

- Use meaningful variable and function names
- Add comprehensive comments for complex logic
- Implement proper error handling with user-friendly messages
- Follow Swift naming conventions
- Use optionals appropriately
- Implement proper data validation
