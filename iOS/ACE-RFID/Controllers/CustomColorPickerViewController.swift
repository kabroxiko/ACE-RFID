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
    private let topBar = UIStackView()
    private let titleLabel = UILabel()
    private let colorPreviewView = UIView()
    private let colorNameTextField = UITextField()
    private let colorGridScrollView = UIScrollView()
    private let colorGridStack = UIStackView()
    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)

    private var selectedColor: UIColor = .systemBlue {
        didSet {
            updateColorPreview(animated: true)
            provideHapticFeedback()
        }
    }

    private var availableColors: [(name: String, color: UIColor)] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        availableColors = Filament.Color.allAvailableColors.filter { $0.name != "Add Custom Color..." }
        setupUI()
        setupConstraints()
        setupActions()
        selectedColor = availableColors.first?.color ?? .systemBlue
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Top bar with Cancel and Save
        topBar.axis = .horizontal
        topBar.distribution = .equalSpacing
        topBar.alignment = .center
        topBar.translatesAutoresizingMaskIntoConstraints = false

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.systemRed, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        saveButton.setTitle("Save", for: .normal)
        saveButton.backgroundColor = .systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 8
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        saveButton.translatesAutoresizingMaskIntoConstraints = false

        topBar.addArrangedSubview(cancelButton)
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        topBar.addArrangedSubview(spacer)
        topBar.addArrangedSubview(saveButton)
        view.addSubview(topBar)

        // Title
        titleLabel.text = "Create Custom Color"
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // Color preview
        colorPreviewView.layer.cornerRadius = 32
        colorPreviewView.layer.borderWidth = 3
        colorPreviewView.layer.borderColor = UIColor.systemGray4.cgColor
        colorPreviewView.translatesAutoresizingMaskIntoConstraints = false
        colorPreviewView.backgroundColor = selectedColor
        view.addSubview(colorPreviewView)

        // Horizontal color grid
        colorGridScrollView.showsHorizontalScrollIndicator = false
        colorGridScrollView.translatesAutoresizingMaskIntoConstraints = false
        colorGridStack.axis = .horizontal
        colorGridStack.spacing = 16
        colorGridStack.alignment = .center
        colorGridStack.translatesAutoresizingMaskIntoConstraints = false
        colorGridScrollView.addSubview(colorGridStack)
        view.addSubview(colorGridScrollView)

        // Add color swatches to grid
        for (index, colorInfo) in availableColors.enumerated() {
            let swatchButton = UIButton(type: .custom)
            swatchButton.backgroundColor = colorInfo.color
            swatchButton.layer.cornerRadius = 20
            swatchButton.layer.borderWidth = 2
            swatchButton.layer.borderColor = UIColor.systemGray4.cgColor
            swatchButton.translatesAutoresizingMaskIntoConstraints = false
            swatchButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
            swatchButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
            swatchButton.tag = index
            swatchButton.accessibilityLabel = colorInfo.name
            swatchButton.addTarget(self, action: #selector(colorSwatchTapped(_:)), for: .touchUpInside)
            colorGridStack.addArrangedSubview(swatchButton)
        }

        // Color name text field
        colorNameTextField.placeholder = "Color name"
        colorNameTextField.borderStyle = .roundedRect
        colorNameTextField.font = UIFont.systemFont(ofSize: 18)
        colorNameTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(colorNameTextField)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Top bar
            cancelButton.widthAnchor.constraint(equalToConstant: 80),
            saveButton.widthAnchor.constraint(equalToConstant: 80),
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            topBar.heightAnchor.constraint(equalToConstant: 44),

            // Title
            titleLabel.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            titleLabel.heightAnchor.constraint(equalToConstant: 32),

            // Color preview
            colorPreviewView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            colorPreviewView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            colorPreviewView.widthAnchor.constraint(equalToConstant: 64),
            colorPreviewView.heightAnchor.constraint(equalToConstant: 64),

            // Horizontal color grid
            colorGridScrollView.topAnchor.constraint(equalTo: colorPreviewView.bottomAnchor, constant: 24),
            colorGridScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            colorGridScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            colorGridScrollView.heightAnchor.constraint(equalToConstant: 56),
            colorGridStack.topAnchor.constraint(equalTo: colorGridScrollView.topAnchor),
            colorGridStack.bottomAnchor.constraint(equalTo: colorGridScrollView.bottomAnchor),
            colorGridStack.leadingAnchor.constraint(equalTo: colorGridScrollView.leadingAnchor, constant: 8),
            colorGridStack.trailingAnchor.constraint(equalTo: colorGridScrollView.trailingAnchor, constant: -8),

            // Color name text field
            colorNameTextField.topAnchor.constraint(equalTo: colorGridScrollView.bottomAnchor, constant: 24),
            colorNameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 36),
            colorNameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -36),
            colorNameTextField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupActions() {
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc private func brightnessChanged() {
        // Removed: brightness slider logic (not implemented)
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

    private func updateColorPreview(animated: Bool = false) {
        if animated {
            UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: {
                self.colorPreviewView.backgroundColor = self.selectedColor
            }, completion: nil)
        } else {
            colorPreviewView.backgroundColor = selectedColor
        }
    }

    private func provideHapticFeedback() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    @objc private func colorSwatchTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < availableColors.count else { return }
        let colorInfo = availableColors[index]
        selectedColor = colorInfo.color
        colorNameTextField.text = colorInfo.name
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
        // Removed: brightness slider logic (not implemented)
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
