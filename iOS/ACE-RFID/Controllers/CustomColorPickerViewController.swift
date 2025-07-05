//
//  CustomColorPickerViewController.swift
//  ACE-RFID
//
//  Created by Copilot on 07/03/2025.
//

import UIKit

protocol CustomColorPickerDelegate: AnyObject {
    func customColorPicker(_ picker: CustomColorPickerViewController, didSelectColor color: UIColor, withName name: String)
}

class CustomColorPickerViewController: UIViewController {

    weak var delegate: CustomColorPickerDelegate?

    // MARK: - UI Elements
    private let titleLabel = UILabel()
    private let colorWheelView = ColorWheelView()
    private let brightnessSlider = UISlider()
    private let colorPreviewView = UIView()
    private let colorNameTextField = UITextField()
    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)

    private var selectedColor: UIColor = .red {
        didSet {
            updateColorPreview()
        }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()

        // Set initial color
        selectedColor = .red
        colorWheelView.selectedColor = selectedColor
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Title
        titleLabel.text = "Create Custom Color"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Color wheel
        colorWheelView.delegate = self
        colorWheelView.translatesAutoresizingMaskIntoConstraints = false

        // Brightness slider
        brightnessSlider.minimumValue = 0.0
        brightnessSlider.maximumValue = 1.0
        brightnessSlider.value = 1.0
        brightnessSlider.translatesAutoresizingMaskIntoConstraints = false

        // Color preview
        colorPreviewView.layer.cornerRadius = 12
        colorPreviewView.layer.borderWidth = 2
        colorPreviewView.layer.borderColor = UIColor.systemGray4.cgColor
        colorPreviewView.translatesAutoresizingMaskIntoConstraints = false

        // Color name text field
        colorNameTextField.placeholder = "Enter color name"
        colorNameTextField.borderStyle = .roundedRect
        colorNameTextField.font = UIFont.systemFont(ofSize: 16)
        colorNameTextField.translatesAutoresizingMaskIntoConstraints = false

        // Buttons
        saveButton.setTitle("Save Color", for: .normal)
        saveButton.backgroundColor = .systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 8
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        saveButton.translatesAutoresizingMaskIntoConstraints = false

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.systemRed, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        // Add subviews
        view.addSubview(titleLabel)
        view.addSubview(colorWheelView)
        view.addSubview(brightnessSlider)
        view.addSubview(colorPreviewView)
        view.addSubview(colorNameTextField)
        view.addSubview(saveButton)
        view.addSubview(cancelButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Color wheel
            colorWheelView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            colorWheelView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            colorWheelView.widthAnchor.constraint(equalToConstant: 250),
            colorWheelView.heightAnchor.constraint(equalToConstant: 250),

            // Brightness slider
            brightnessSlider.topAnchor.constraint(equalTo: colorWheelView.bottomAnchor, constant: 20),
            brightnessSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            brightnessSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            // Color preview
            colorPreviewView.topAnchor.constraint(equalTo: brightnessSlider.bottomAnchor, constant: 20),
            colorPreviewView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            colorPreviewView.widthAnchor.constraint(equalToConstant: 80),
            colorPreviewView.heightAnchor.constraint(equalToConstant: 80),

            // Color name text field
            colorNameTextField.topAnchor.constraint(equalTo: colorPreviewView.bottomAnchor, constant: 20),
            colorNameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            colorNameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            colorNameTextField.heightAnchor.constraint(equalToConstant: 40),

            // Buttons
            saveButton.topAnchor.constraint(equalTo: colorNameTextField.bottomAnchor, constant: 30),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 120),
            saveButton.heightAnchor.constraint(equalToConstant: 44),

            cancelButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 10),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cancelButton.widthAnchor.constraint(equalToConstant: 120),
            cancelButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupActions() {
        brightnessSlider.addTarget(self, action: #selector(brightnessChanged), for: .valueChanged)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc private func brightnessChanged() {
        // Adjust the selected color's brightness
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        selectedColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        selectedColor = UIColor(hue: hue, saturation: saturation, brightness: CGFloat(brightnessSlider.value), alpha: alpha)
    }

    @objc private func saveButtonTapped() {
        guard let colorName = colorNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !colorName.isEmpty else {
            showAlert(title: "Missing Color Name", message: "Please enter a name for your custom color.")
            return
        }

        // Check if color name already exists
        if CustomColorManager.shared.colorNameExists(colorName) {
            showAlert(title: "Color Name Exists", message: "A color with this name already exists. Please choose a different name.")
            return
        }

        // Check if name conflicts with predefined colors
        if Filament.Color.allCases.contains(where: { $0.rawValue.lowercased() == colorName.lowercased() }) {
            showAlert(title: "Reserved Color Name", message: "This name is reserved for a predefined color. Please choose a different name.")
            return
        }

        delegate?.customColorPicker(self, didSelectColor: selectedColor, withName: colorName)
        dismiss(animated: true)
    }

    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }

    private func updateColorPreview() {
        colorPreviewView.backgroundColor = selectedColor
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - ColorWheelViewDelegate
extension CustomColorPickerViewController: ColorWheelViewDelegate {
    func colorWheelView(_ colorWheelView: ColorWheelView, didSelectColor color: UIColor) {
        selectedColor = color

        // Update brightness slider to match the selected color's brightness
        var brightness: CGFloat = 0
        color.getHue(nil, saturation: nil, brightness: &brightness, alpha: nil)
        brightnessSlider.value = Float(brightness)
    }
}

// MARK: - ColorWheelView
protocol ColorWheelViewDelegate: AnyObject {
    func colorWheelView(_ colorWheelView: ColorWheelView, didSelectColor color: UIColor)
}

class ColorWheelView: UIView {

    weak var delegate: ColorWheelViewDelegate?

    var selectedColor: UIColor = .red {
        didSet {
            setNeedsDisplay()
        }
    }

    private var wheelRadius: CGFloat {
        return min(bounds.width, bounds.height) / 2 - 10
    }

    private var centerPoint: CGPoint {
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else { return }

        // Draw color wheel
        drawColorWheel(in: context)

        // Draw selection indicator
        drawSelectionIndicator(in: context)
    }

    private func drawColorWheel(in context: CGContext) {
        let center = centerPoint
        let radius = wheelRadius

        // Create color wheel using a more efficient approach
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        // Draw color wheel with optimized segments for smooth rendering
        let segments = 360 // One segment per degree for smooth color transitions
        let angleStep = 2.0 * Double.pi / Double(segments)

        for i in 0..<segments {
            let startAngle = CGFloat(Double(i) * angleStep)
            let endAngle = CGFloat(Double(i + 1) * angleStep)

            let hue = CGFloat(i) / CGFloat(segments)
            let color = UIColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
            context.setFillColor(color.cgColor)

            // Draw thin arc segment
            context.move(to: center)
            context.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            context.closePath()
            context.fillPath()
        }

        // Draw saturation gradient (white to transparent from center to edge)
        let locations: [CGFloat] = [0.0, 1.0]
        let gradientColors = [UIColor.white.cgColor, UIColor.clear.cgColor]

        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors as CFArray, locations: locations) else {
            return
        }

        context.saveGState()
        context.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        context.clip()
        context.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
        context.restoreGState()
    }

    private func drawSelectionIndicator(in context: CGContext) {
        let center = centerPoint
        let radius = wheelRadius

        // Get the position for the current color
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        selectedColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)

        // Only draw indicator if we have valid color values
        guard saturation > 0 || hue > 0 else {
            // For gray colors (saturation = 0), draw at center
            if brightness > 0.1 && brightness < 0.9 {
                let indicatorRect = CGRect(x: center.x - 8, y: center.y - 8, width: 16, height: 16)
                context.setFillColor(UIColor.white.cgColor)
                context.setStrokeColor(UIColor.black.cgColor)
                context.setLineWidth(2)
                context.addEllipse(in: indicatorRect)
                context.drawPath(using: .fillStroke)
            }
            return
        }

        // Convert hue to angle - match the coordinate system used in touch handling
        let angle = hue * 2 * .pi
        let distance = saturation * radius

        let indicatorX = center.x + cos(angle) * distance
        let indicatorY = center.y + sin(angle) * distance

        // Only draw if the indicator is within the wheel bounds
        let distanceFromCenter = sqrt(pow(indicatorX - center.x, 2) + pow(indicatorY - center.y, 2))
        guard distanceFromCenter <= radius else { return }

        // Draw white circle with black border
        context.setFillColor(UIColor.white.cgColor)
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(2)

        let indicatorRect = CGRect(x: indicatorX - 8, y: indicatorY - 8, width: 16, height: 16)
        context.addEllipse(in: indicatorRect)
        context.drawPath(using: .fillStroke)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouch(touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouch(touches)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Final touch handling
        handleTouch(touches)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Handle touch cancellation gracefully - no additional action needed
    }

    private func handleTouch(_ touches: Set<UITouch>) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        let center = centerPoint
        let radius = wheelRadius

        // Calculate distance from center
        let dx = location.x - center.x
        let dy = location.y - center.y
        let distance = sqrt(dx * dx + dy * dy)

        // Only respond to touches within the wheel
        guard distance <= radius else { return }

        // Calculate angle from touch position
        let angle = atan2(dy, dx)

        // Convert angle to hue (0-1 range)
        // atan2 returns -π to π, normalize to 0 to 2π
        let normalizedAngle = angle < 0 ? angle + 2 * .pi : angle
        let hue = normalizedAngle / (2 * .pi)

        // Calculate saturation based on distance from center
        let saturation = min(distance / radius, 1.0)

        // Create color and notify delegate
        let color = UIColor(hue: hue, saturation: saturation, brightness: 1.0, alpha: 1.0)
        selectedColor = color
        delegate?.colorWheelView(self, didSelectColor: color)

        // Redraw with new selection
        setNeedsDisplay()
    }
}
