//
//  FilamentTableViewCell.swift
//  ACE-RFID
//
//  Created by Copilot on 07/03/2025.
//

import UIKit

class FilamentTableViewCell: UITableViewCell {

    static let identifier = "FilamentTableViewCell"

    // MARK: - UI Elements

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let colorIndicatorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 6
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let brandLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let materialLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let colorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let temperatureLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let weightLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .systemGreen
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let lastUsedLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .regular)
        label.textColor = .tertiaryLabel
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(containerView)

        containerView.addSubview(colorIndicatorView)
        containerView.addSubview(brandLabel)
        containerView.addSubview(materialLabel)
        containerView.addSubview(colorLabel)
        containerView.addSubview(temperatureLabel)
        containerView.addSubview(weightLabel)
        containerView.addSubview(statusLabel)
        containerView.addSubview(lastUsedLabel)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            // Color indicator
            colorIndicatorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            colorIndicatorView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            colorIndicatorView.widthAnchor.constraint(equalToConstant: 12),
            colorIndicatorView.heightAnchor.constraint(equalToConstant: 12),

            // Brand label
            brandLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            brandLabel.leadingAnchor.constraint(equalTo: colorIndicatorView.trailingAnchor, constant: 8),
            brandLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -8),

            // Material label
            materialLabel.topAnchor.constraint(equalTo: brandLabel.bottomAnchor, constant: 2),
            materialLabel.leadingAnchor.constraint(equalTo: brandLabel.leadingAnchor),
            materialLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -8),

            // Color label
            colorLabel.topAnchor.constraint(equalTo: materialLabel.bottomAnchor, constant: 2),
            colorLabel.leadingAnchor.constraint(equalTo: brandLabel.leadingAnchor),
            colorLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -8),

            // Temperature label
            temperatureLabel.topAnchor.constraint(equalTo: colorLabel.bottomAnchor, constant: 8),
            temperatureLabel.leadingAnchor.constraint(equalTo: brandLabel.leadingAnchor),
            temperatureLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),

            // Weight label
            weightLabel.topAnchor.constraint(equalTo: temperatureLabel.topAnchor),
            weightLabel.leadingAnchor.constraint(equalTo: temperatureLabel.trailingAnchor, constant: 16),
            weightLabel.bottomAnchor.constraint(equalTo: temperatureLabel.bottomAnchor),

            // Status label
            statusLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            statusLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),

            // Last used label
            lastUsedLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 4),
            lastUsedLabel.trailingAnchor.constraint(equalTo: statusLabel.trailingAnchor),
            lastUsedLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
    }

    // MARK: - Configuration

    func configure(with filament: Filament) {
        brandLabel.text = filament.brand
        materialLabel.text = filament.material

        // Show color name and hex value
        let colorName = filament.color
        let hexValue: String
        if colorName.hasPrefix("#") {
            hexValue = colorName.uppercased()
        } else {
            hexValue = hexFromColorName(colorName)
        }
        colorLabel.text = "\(colorName) \(hexValue)"

        temperatureLabel.text = "🌡️ \(filament.printMinTemperature)-\(filament.printMaxTemperature)°C / \(filament.bedMinTemperature)-\(filament.bedMaxTemperature)°C"

        let remainingPercentage = (filament.remainingWeight / filament.weight) * 100
        weightLabel.text = "⚖️ \(String(format: "%.0f", filament.remainingWeight))g (\(String(format: "%.0f", remainingPercentage))%)"

        // Set color indicator
        colorIndicatorView.backgroundColor = colorFromString(filament.color)

        // Set status
        if filament.isFinished {
            statusLabel.text = "Finished"
            statusLabel.textColor = .systemRed
        } else if remainingPercentage < 10 {
            statusLabel.text = "Low"
            statusLabel.textColor = .systemOrange
        } else {
            statusLabel.text = "Available"
            statusLabel.textColor = .systemGreen
        }

        // Set last used
        if let lastUsed = filament.lastUsed {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            lastUsedLabel.text = "Used: \(formatter.string(from: lastUsed))"
        } else {
            lastUsedLabel.text = "Never used"
        }
    }

    // MARK: - Helper Methods

    private func colorFromString(_ colorName: String) -> UIColor {
        let lowercased = colorName.lowercased()
        switch lowercased {
        case "red": return .systemRed
        case "blue": return .systemBlue
        case "green": return .systemGreen
        case "yellow": return .systemYellow
        case "orange": return .systemOrange
        case "purple": return .systemPurple
        case "pink": return .systemPink
        case "black": return .label
        case "white": return .systemGray
        case "gray", "grey": return .systemGray
        case "brown": return .brown
        case "clear", "transparent": return .clear
        default:
            // Try to parse hex string
            if colorName.hasPrefix("#") {
                return UIColor(hex: colorName) ?? .systemGray2
            }
            return .systemGray2
        }
    }

    private func hexFromColorName(_ colorName: String) -> String {
        let lowercased = colorName.lowercased()
        switch lowercased {
        case "red": return "#FF3B30"
        case "blue": return "#007AFF"
        case "green": return "#34C759"
        case "yellow": return "#FFCC00"
        case "orange": return "#FF9500"
        case "purple": return "#AF52DE"
        case "pink": return "#FF2D55"
        case "black": return "#000000"
        case "white": return "#FFFFFF"
        case "gray", "grey": return "#8E8E93"
        case "brown": return "#A2845E"
        case "clear", "transparent": return "#00000000"
        default:
            // If it's already a hex string, return as is
            if colorName.hasPrefix("#") {
                return colorName.uppercased()
            }
            return "#8E8E93" // Default gray
        }
    }

// UIColor(hex:) convenience initializer
}

// Add UIColor(hex:) initializer for hex parsing
extension UIColor {
    convenience init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexString.hasPrefix("#") {
            hexString.remove(at: hexString.startIndex)
        }
        if hexString.count == 6 {
            hexString += "FF" // Add alpha if missing
        }
        guard hexString.count == 8 else { return nil }
        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)
        let r = CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0
        let g = CGFloat((rgbValue & 0x00FF0000) >> 16) / 255.0
        let b = CGFloat((rgbValue & 0x0000FF00) >> 8) / 255.0
        let a = CGFloat(rgbValue & 0x000000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
