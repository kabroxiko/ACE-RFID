//
//  AddEditFilamentViewController.swift
//  ACE-RFID
//
//  Created by Copilot on 07/03/2025.
//

import UIKit

protocol AddEditFilamentViewControllerDelegate: AnyObject {
    func didSaveFilament(_ filament: Filament)
}

class AddEditFilamentViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Properties

    weak var delegate: AddEditFilamentViewControllerDelegate?
    private var filament: Filament?
    private var isEditMode: Bool { return filament != nil }

    // Brand management
    private lazy var availableBrands: [String] = {
        var brands = Filament.Brand.allCases.map { $0.rawValue }.sorted()
        brands.append("Add Custom Brand...")
        return brands
    }()

    // Color management
    private lazy var availableColors: [(name: String, color: UIColor)] = {
        // Combine predefined and custom colors
        var colors = Filament.Color.allCases.map { ($0.rawValue, $0.displayColor) }
        let customColors = CustomColorManager.shared.getCustomColors()
        colors.append(contentsOf: customColors)
        colors.append(("Add Custom Color...", UIColor.systemGray))
        return colors
    }()

    // Picker view caching for performance - lazy initialization
    private lazy var cachedPickerViews: [Int: UIPickerView] = [:]

    // MARK: - UI Elements

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    // Form fields
    private let brandTextField = UITextField()
    private let materialTextField = UITextField()
    private let colorTextField = UITextField()
    private let weightTextField = UITextField()
    private let diameterTextField = UITextField()
    private let printTemperatureTextField = UITextField()
    private let bedTemperatureTextField = UITextField()
    private let fanSpeedTextField = UITextField()
    private let printSpeedTextField = UITextField()
    private let notesTextView = UITextView()

    // Cache for color swatch - much faster than view hierarchy search
    private weak var colorSwatchView: UIView?

    // MARK: - Initialization

    init(filament: Filament? = nil) {
        self.filament = filament
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        fillFormWithFilament()

        // Pre-warm pickers in background for faster first access
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.preWarmPickers()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardNotifications()
        // Refresh colors in case custom colors were added elsewhere
        refreshColors()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterKeyboardNotifications()
    }

    // MARK: - Picker Performance Optimization

    private func preWarmPickers() {
        // Pre-create all picker views in background to avoid first-time delays
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Create all pickers but don't assign them yet to avoid blocking UI
            for tag in 0...8 {
                _ = self.getCachedPickerView(tag: tag)
            }
        }
    }

    private func getCachedPickerView(tag: Int) -> UIPickerView {
        if let cachedPicker = cachedPickerViews[tag] {
            return cachedPicker
        }

        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        picker.tag = tag

        // Pre-warm the picker by calling reloadAllComponents in background
        DispatchQueue.global(qos: .userInitiated).async { [weak picker] in
            DispatchQueue.main.async {
                picker?.reloadAllComponents()
            }
        }

        cachedPickerViews[tag] = picker
        return picker
    }

    private func refreshColors() {
        // Only reload if colors actually changed to avoid unnecessary work
        let newColors = Filament.Color.allCases.map { ($0.rawValue, $0.displayColor) } +
                       CustomColorManager.shared.getCustomColors() +
                       [("Add Custom Color...", UIColor.systemGray)]

        let hasChanged = newColors.count != availableColors.count ||
                        !zip(newColors, availableColors).allSatisfy { $0.0.name == $0.1.name }

        if hasChanged {
            availableColors = newColors
            if let colorPicker = cachedPickerViews[2] {
                colorPicker.reloadAllComponents()
            }
        }
    }

    // MARK: - Setup

    private func setupUI() {
        // Enhanced background with gradient
        view.backgroundColor = .systemBackground

        // Add subtle gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.systemBackground.cgColor,
            UIColor.secondarySystemBackground.cgColor
        ]
        gradientLayer.locations = [0, 1]
        view.layer.insertSublayer(gradientLayer, at: 0)

        // Update gradient frame when view layout changes - optimized
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            gradientLayer.frame = self.view.bounds
        }

        // Scroll view setup with enhanced styling
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = .clear

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .clear

        // Stack view setup with enhanced spacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 24 // Increased spacing for better visual hierarchy
        stackView.distribution = .fill

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        // Setup form fields
        setupFormFields()

        // Enhanced constraints with better margins
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    private func setupNavigationBar() {
        title = isEditMode ? "Edit Filament" : "Add Filament"

        // Enhance navigation bar appearance
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .automatic

        // Enhanced cancel button
        let cancelButton = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        cancelButton.tintColor = .systemRed
        navigationItem.leftBarButtonItem = cancelButton

        // Enhanced save button
        let saveButton = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
        saveButton.tintColor = .systemBlue
        navigationItem.rightBarButtonItem = saveButton
    }

    private func setupFormFields() {
        // Brand section
        stackView.addArrangedSubview(createSectionLabel("Brand"))
        brandTextField.placeholder = "Enter brand name or select from list"
        brandTextField.inputView = getCachedPickerView(tag: 0)
        brandTextField.delegate = self // Add text field delegate
        stackView.addArrangedSubview(createFormField(brandTextField))

        // Material and Color side by side
        materialTextField.placeholder = "Select material"
        materialTextField.inputView = getCachedPickerView(tag: 1)

        colorTextField.placeholder = "Select color"
        colorTextField.inputView = getCachedPickerView(tag: 2)

        stackView.addArrangedSubview(createSideBySideFormFields(materialTextField, leftLabel: "Material", colorTextField, rightLabel: "Color"))

        // Weight and Diameter side by side
        weightTextField.placeholder = "Select weight"
        weightTextField.inputView = getCachedPickerView(tag: 3)

        diameterTextField.placeholder = "Select diameter"
        diameterTextField.inputView = getCachedPickerView(tag: 4)

        stackView.addArrangedSubview(createSideBySideFormFields(weightTextField, leftLabel: "Weight", diameterTextField, rightLabel: "Diameter"))

        // Print and Bed Temperature side by side
        printTemperatureTextField.placeholder = "Select temperature"
        printTemperatureTextField.inputView = getCachedPickerView(tag: 5)

        bedTemperatureTextField.placeholder = "Select temperature"
        bedTemperatureTextField.inputView = getCachedPickerView(tag: 6)

        stackView.addArrangedSubview(createSideBySideFormFields(printTemperatureTextField, leftLabel: "Print Temperature", bedTemperatureTextField, rightLabel: "Bed Temperature"))

        // Fan Speed and Print Speed side by side
        fanSpeedTextField.placeholder = "Select fan speed"
        fanSpeedTextField.inputView = getCachedPickerView(tag: 7)

        printSpeedTextField.placeholder = "Select print speed"
        printSpeedTextField.inputView = getCachedPickerView(tag: 8)

        stackView.addArrangedSubview(createSideBySideFormFields(fanSpeedTextField, leftLabel: "Fan Speed", printSpeedTextField, rightLabel: "Print Speed"))

        // Notes section
        stackView.addArrangedSubview(createSectionLabel("Notes"))
        setupNotesTextView()
        stackView.addArrangedSubview(notesTextView)

        // Add toolbar to all text fields for easy dismissal
        addToolbarToPickers()
    }

    private func setupNotesTextView() {
        notesTextView.backgroundColor = .tertiarySystemBackground
        notesTextView.layer.borderColor = UIColor.systemGray5.cgColor
        notesTextView.layer.borderWidth = 0.5
        notesTextView.layer.cornerRadius = 12
        notesTextView.font = UIFont.systemFont(ofSize: 16)
        notesTextView.textColor = .label
        notesTextView.translatesAutoresizingMaskIntoConstraints = false
        notesTextView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        // Add subtle shadow for consistency
        notesTextView.layer.shadowColor = UIColor.black.cgColor
        notesTextView.layer.shadowOffset = CGSize(width: 0, height: 1)
        notesTextView.layer.shadowOpacity = 0.05
        notesTextView.layer.shadowRadius = 2

        notesTextView.heightAnchor.constraint(equalToConstant: 120).isActive = true
    }

    private func addToolbarToPickers() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))

        toolbar.items = [flexSpace, doneButton]

        // Add toolbar to all picker fields
        brandTextField.inputAccessoryView = toolbar
        materialTextField.inputAccessoryView = toolbar
        colorTextField.inputAccessoryView = toolbar
        weightTextField.inputAccessoryView = toolbar
        diameterTextField.inputAccessoryView = toolbar
        printTemperatureTextField.inputAccessoryView = toolbar
        bedTemperatureTextField.inputAccessoryView = toolbar
        fanSpeedTextField.inputAccessoryView = toolbar
        printSpeedTextField.inputAccessoryView = toolbar

        // Add toolbar to notes text view
        notesTextView.inputAccessoryView = toolbar
    }

    private func createSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false

        // Add subtle margin at bottom
        label.heightAnchor.constraint(greaterThanOrEqualToConstant: 22).isActive = true

        return label
    }

    private func createFormField(_ textField: UITextField) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .tertiarySystemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 0.5
        containerView.layer.borderColor = UIColor.systemGray5.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false

        // Add subtle shadow for depth
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 1)
        containerView.layer.shadowOpacity = 0.05
        containerView.layer.shadowRadius = 2

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.font = .systemFont(ofSize: 16, weight: .medium)
        textField.borderStyle = .none
        textField.isUserInteractionEnabled = true
        textField.tintColor = .clear // Hide cursor since these are dropdown-style
        textField.textColor = .label

        // Add dropdown arrow with better styling
        let dropdownImageView = UIImageView(image: UIImage(systemName: "chevron.down"))
        dropdownImageView.tintColor = .systemBlue
        dropdownImageView.contentMode = .scaleAspectFit
        dropdownImageView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(textField)
        containerView.addSubview(dropdownImageView)

        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: 52), // Increased height for better touch targets
            textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: dropdownImageView.leadingAnchor, constant: -12),
            textField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            dropdownImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            dropdownImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            dropdownImageView.widthAnchor.constraint(equalToConstant: 18),
            dropdownImageView.heightAnchor.constraint(equalToConstant: 18)
        ])

        return containerView
    }

    private func createColorFormField(_ textField: UITextField) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .tertiarySystemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 0.5
        containerView.layer.borderColor = UIColor.systemGray5.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false

        // Add subtle shadow for depth
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 1)
        containerView.layer.shadowOpacity = 0.05
        containerView.layer.shadowRadius = 2

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.font = .systemFont(ofSize: 16, weight: .medium)
        textField.borderStyle = .none
        textField.isUserInteractionEnabled = true
        textField.tintColor = .clear // Hide cursor since these are dropdown-style
        textField.textColor = .label

        // Create color swatch view
        let colorSwatchView = UIView()
        colorSwatchView.layer.cornerRadius = 12
        colorSwatchView.layer.borderWidth = 2
        colorSwatchView.layer.borderColor = UIColor.systemGray3.cgColor
        colorSwatchView.backgroundColor = .systemBlue // Default color
        colorSwatchView.translatesAutoresizingMaskIntoConstraints = false

        // Add subtle shadow to make it more visible
        colorSwatchView.layer.shadowColor = UIColor.black.cgColor
        colorSwatchView.layer.shadowOffset = CGSize(width: 0, height: 1)
        colorSwatchView.layer.shadowOpacity = 0.3
        colorSwatchView.layer.shadowRadius = 2

        // Add dropdown arrow with better styling
        let dropdownImageView = UIImageView(image: UIImage(systemName: "chevron.down"))
        dropdownImageView.tintColor = .systemBlue
        dropdownImageView.contentMode = .scaleAspectFit
        dropdownImageView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(colorSwatchView)
        containerView.addSubview(textField)
        containerView.addSubview(dropdownImageView)

        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: 52), // Increased height for better touch targets

            colorSwatchView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            colorSwatchView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            colorSwatchView.widthAnchor.constraint(equalToConstant: 24),
            colorSwatchView.heightAnchor.constraint(equalToConstant: 24),

            textField.leadingAnchor.constraint(equalTo: colorSwatchView.trailingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: dropdownImageView.leadingAnchor, constant: -12),
            textField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            dropdownImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            dropdownImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            dropdownImageView.widthAnchor.constraint(equalToConstant: 18),
            dropdownImageView.heightAnchor.constraint(equalToConstant: 18)
        ])

        // Store the color swatch view reference for later updates
        containerView.tag = 999 // Special tag to identify color field container
        colorSwatchView.tag = 1000 // Special tag to identify color swatch

        // Cache the color swatch for fast access
        self.colorSwatchView = colorSwatchView

        return containerView
    }

    private func createSideBySideFormFields(_ leftField: UITextField, leftLabel: String, _ rightField: UITextField, rightLabel: String) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        // Create horizontal stack view
        let horizontalStack = UIStackView()
        horizontalStack.axis = .horizontal
        horizontalStack.spacing = 16
        horizontalStack.distribution = .fillEqually
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false

        // Create left side container
        let leftContainer = UIView()
        let leftLabelView = createFieldLabel(leftLabel)
        let leftFieldView = createFormField(leftField)

        leftContainer.addSubview(leftLabelView)
        leftContainer.addSubview(leftFieldView)
        leftContainer.translatesAutoresizingMaskIntoConstraints = false

        // Create right side container
        let rightContainer = UIView()
        let rightLabelView = createFieldLabel(rightLabel)
        let rightFieldView = rightField == colorTextField ? createColorFormField(rightField) : createFormField(rightField)

        rightContainer.addSubview(rightLabelView)
        rightContainer.addSubview(rightFieldView)
        rightContainer.translatesAutoresizingMaskIntoConstraints = false

        // Add containers to horizontal stack
        horizontalStack.addArrangedSubview(leftContainer)
        horizontalStack.addArrangedSubview(rightContainer)

        containerView.addSubview(horizontalStack)

        NSLayoutConstraint.activate([
            // Horizontal stack constraints
            horizontalStack.topAnchor.constraint(equalTo: containerView.topAnchor),
            horizontalStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            horizontalStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            horizontalStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            // Left container constraints
            leftLabelView.topAnchor.constraint(equalTo: leftContainer.topAnchor),
            leftLabelView.leadingAnchor.constraint(equalTo: leftContainer.leadingAnchor),
            leftLabelView.trailingAnchor.constraint(equalTo: leftContainer.trailingAnchor),

            leftFieldView.topAnchor.constraint(equalTo: leftLabelView.bottomAnchor, constant: 8),
            leftFieldView.leadingAnchor.constraint(equalTo: leftContainer.leadingAnchor),
            leftFieldView.trailingAnchor.constraint(equalTo: leftContainer.trailingAnchor),
            leftFieldView.bottomAnchor.constraint(equalTo: leftContainer.bottomAnchor),

            // Right container constraints
            rightLabelView.topAnchor.constraint(equalTo: rightContainer.topAnchor),
            rightLabelView.leadingAnchor.constraint(equalTo: rightContainer.leadingAnchor),
            rightLabelView.trailingAnchor.constraint(equalTo: rightContainer.trailingAnchor),

            rightFieldView.topAnchor.constraint(equalTo: rightLabelView.bottomAnchor, constant: 8),
            rightFieldView.leadingAnchor.constraint(equalTo: rightContainer.leadingAnchor),
            rightFieldView.trailingAnchor.constraint(equalTo: rightContainer.trailingAnchor),
            rightFieldView.bottomAnchor.constraint(equalTo: rightContainer.bottomAnchor)
        ])

        return containerView
    }

    private func createFieldLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func fillFormWithFilament() {
        guard let filament = filament else {
            // Set default values for new filament
            setDefaultValues()
            return
        }

        brandTextField.text = filament.brand
        materialTextField.text = filament.material
        colorTextField.text = filament.color

        // Format weight display
        let weight = filament.weight
        weightTextField.text = weight < 1000 ? String(format: "%.0f g", weight) : String(format: "%.1f kg", weight / 1000)

        // Format other fields
        diameterTextField.text = String(format: "%.2f mm", filament.diameter)
        printTemperatureTextField.text = "\(filament.printTemperature)°C"
        bedTemperatureTextField.text = "\(filament.bedTemperature)°C"
        fanSpeedTextField.text = "\(filament.fanSpeed)%"
        printSpeedTextField.text = "\(filament.printSpeed) mm/s"
        notesTextView.text = filament.notes

        // Set picker views to correct selections using cached pickers
        if let brandIndex = availableBrands.firstIndex(of: filament.brand) {
            cachedPickerViews[0]?.selectRow(brandIndex, inComponent: 0, animated: false)
        } else {
            // Add custom brand if not in list
            availableBrands.insert(filament.brand, at: availableBrands.count - 1)
            cachedPickerViews[0]?.reloadAllComponents()
            if let brandIndex = availableBrands.firstIndex(of: filament.brand) {
                cachedPickerViews[0]?.selectRow(brandIndex, inComponent: 0, animated: false)
            }
        }

        if let materialIndex = Filament.Material.allCases.firstIndex(where: { $0.rawValue == filament.material }) {
            cachedPickerViews[1]?.selectRow(materialIndex, inComponent: 0, animated: false)
        }

        if let colorIndex = availableColors.firstIndex(where: { $0.name == filament.color }) {
            cachedPickerViews[2]?.selectRow(colorIndex, inComponent: 0, animated: false)
            // Update color swatch with the selected color - delay to ensure UI is ready
            DispatchQueue.main.async { [weak self] in
                self?.updateColorSwatch(self?.availableColors[colorIndex].color ?? .systemBlue)
            }
        }

        // Set weight picker selection - find closest match if exact match not found
        if let weightIndex = Filament.weightOptions.firstIndex(of: weight) {
            cachedPickerViews[3]?.selectRow(weightIndex, inComponent: 0, animated: false)
        } else {
            // Find closest weight option
            let closestWeightIndex = Filament.weightOptions.enumerated().min { abs($0.element - weight) < abs($1.element - weight) }?.offset ?? 0
            cachedPickerViews[3]?.selectRow(closestWeightIndex, inComponent: 0, animated: false)
        }

        // Set diameter picker selection - find closest match if exact match not found
        if let diameterIndex = Filament.diameterOptions.firstIndex(of: filament.diameter) {
            cachedPickerViews[4]?.selectRow(diameterIndex, inComponent: 0, animated: false)
        } else {
            // Find closest diameter option
            let closestDiameterIndex = Filament.diameterOptions.enumerated().min { abs($0.element - filament.diameter) < abs($1.element - filament.diameter) }?.offset ?? 0
            cachedPickerViews[4]?.selectRow(closestDiameterIndex, inComponent: 0, animated: false)
        }

        // Set temperature and speed picker selections - find closest matches
        if let printTempIndex = Filament.temperatureOptions.firstIndex(of: filament.printTemperature) {
            cachedPickerViews[5]?.selectRow(printTempIndex, inComponent: 0, animated: false)
        } else {
            let closestPrintTempIndex = Filament.temperatureOptions.enumerated().min { abs($0.element - filament.printTemperature) < abs($1.element - filament.printTemperature) }?.offset ?? 0
            cachedPickerViews[5]?.selectRow(closestPrintTempIndex, inComponent: 0, animated: false)
        }

        if let bedTempIndex = Filament.bedTemperatureOptions.firstIndex(of: filament.bedTemperature) {
            cachedPickerViews[6]?.selectRow(bedTempIndex, inComponent: 0, animated: false)
        } else {
            let closestBedTempIndex = Filament.bedTemperatureOptions.enumerated().min { abs($0.element - filament.bedTemperature) < abs($1.element - filament.bedTemperature) }?.offset ?? 0
            cachedPickerViews[6]?.selectRow(closestBedTempIndex, inComponent: 0, animated: false)
        }

        if let fanSpeedIndex = Filament.fanSpeedOptions.firstIndex(of: filament.fanSpeed) {
            cachedPickerViews[7]?.selectRow(fanSpeedIndex, inComponent: 0, animated: false)
        } else {
            let closestFanSpeedIndex = Filament.fanSpeedOptions.enumerated().min { abs($0.element - filament.fanSpeed) < abs($1.element - filament.fanSpeed) }?.offset ?? 0
            cachedPickerViews[7]?.selectRow(closestFanSpeedIndex, inComponent: 0, animated: false)
        }

        if let printSpeedIndex = Filament.printSpeedOptions.firstIndex(of: filament.printSpeed) {
            cachedPickerViews[8]?.selectRow(printSpeedIndex, inComponent: 0, animated: false)
        } else {
            let closestPrintSpeedIndex = Filament.printSpeedOptions.enumerated().min { abs($0.element - filament.printSpeed) < abs($1.element - filament.printSpeed) }?.offset ?? 0
            cachedPickerViews[8]?.selectRow(closestPrintSpeedIndex, inComponent: 0, animated: false)
        }
    }

    private func setDefaultValues() {
        // Set default brand (first one - Anycubic)
        let defaultBrand = Filament.Brand.anycubic
        brandTextField.text = defaultBrand.rawValue
        if let index = availableBrands.firstIndex(of: defaultBrand.rawValue) {
            cachedPickerViews[0]?.selectRow(index, inComponent: 0, animated: false)
        }

        // Set default material (PLA)
        let defaultMaterial = Filament.Material.pla
        materialTextField.text = defaultMaterial.rawValue
        cachedPickerViews[1]?.selectRow(0, inComponent: 0, animated: false)

        // Set default color (Black)
        let defaultColor = Filament.Color.black
        colorTextField.text = defaultColor.rawValue
        cachedPickerViews[2]?.selectRow(0, inComponent: 0, animated: false)
        // Set default color swatch - delay to ensure UI is ready
        DispatchQueue.main.async { [weak self] in
            self?.updateColorSwatch(defaultColor.displayColor)
        }

        // Set default weight and diameter with proper formatting
        let defaultWeight = defaultBrand.defaultWeight
        weightTextField.text = defaultWeight < 1000 ? String(format: "%.0f g", defaultWeight) : String(format: "%.1f kg", defaultWeight / 1000)
        if let weightIndex = Filament.weightOptions.firstIndex(of: defaultWeight) {
            cachedPickerViews[3]?.selectRow(weightIndex, inComponent: 0, animated: false)
        }

        let defaultDiameter = defaultBrand.defaultDiameter
        diameterTextField.text = String(format: "%.2f mm", defaultDiameter)
        if let diameterIndex = Filament.diameterOptions.firstIndex(of: defaultDiameter) {
            cachedPickerViews[4]?.selectRow(diameterIndex, inComponent: 0, animated: false)
        }

        // Apply material-based defaults for temperatures and speeds with proper formatting
        let printTemp = defaultMaterial.defaultPrintTemperature
        let bedTemp = defaultMaterial.defaultBedTemperature
        let fanSpeed = defaultMaterial.defaultFanSpeed
        let printSpeed = defaultMaterial.defaultPrintSpeed

        printTemperatureTextField.text = "\(printTemp)°C"
        bedTemperatureTextField.text = "\(bedTemp)°C"
        fanSpeedTextField.text = "\(fanSpeed)%"
        printSpeedTextField.text = "\(printSpeed) mm/s"

        // Set picker selections for temperatures and speeds
        if let printTempIndex = Filament.temperatureOptions.firstIndex(of: printTemp) {
            cachedPickerViews[5]?.selectRow(printTempIndex, inComponent: 0, animated: false)
        }
        if let bedTempIndex = Filament.bedTemperatureOptions.firstIndex(of: bedTemp) {
            cachedPickerViews[6]?.selectRow(bedTempIndex, inComponent: 0, animated: false)
        }
        if let fanSpeedIndex = Filament.fanSpeedOptions.firstIndex(of: fanSpeed) {
            cachedPickerViews[7]?.selectRow(fanSpeedIndex, inComponent: 0, animated: false)
        }
        if let printSpeedIndex = Filament.printSpeedOptions.firstIndex(of: printSpeed) {
            cachedPickerViews[8]?.selectRow(printSpeedIndex, inComponent: 0, animated: false)
        }
    }

    private func initializeBrands() {
        // Start with predefined brands (sorted alphabetically)
        availableBrands = Filament.Brand.sortedCases.map { $0.rawValue }
        // Add "Add Custom Brand..." option at the end
        availableBrands.append("Add Custom Brand...")
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        guard validateForm() else { return }

        let brand = brandTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let material = materialTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let color = colorTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // Parse weight from formatted text (e.g., "1000 g", "1.0 kg", or just numbers)
        let weightText = weightTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "1000"
        let weight: Double
        if weightText.contains("kg") {
            let weightString = weightText.replacingOccurrences(of: "kg", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            weight = (Double(weightString) ?? 1.0) * 1000
        } else if weightText.contains("g") {
            let weightString = weightText.replacingOccurrences(of: "g", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            weight = Double(weightString) ?? 1000
        } else {
            // Handle plain numbers (assume grams)
            weight = Double(weightText) ?? 1000
        }

        // Parse diameter from formatted text (e.g., "1.75 mm")
        let diameterText = diameterTextField.text ?? "1.75"
        let diameterString = diameterText.replacingOccurrences(of: " mm", with: "")
        let diameter = Double(diameterString) ?? 1.75

        // Parse temperatures from formatted text (e.g., "200°C")
        let printTempText = printTemperatureTextField.text ?? "200"
        let printTempString = printTempText.replacingOccurrences(of: "°C", with: "")
        let printTemp = Int(printTempString) ?? 200

        let bedTempText = bedTemperatureTextField.text ?? "60"
        let bedTempString = bedTempText.replacingOccurrences(of: "°C", with: "")
        let bedTemp = Int(bedTempString) ?? 60

        // Parse fan speed from formatted text (e.g., "100%")
        let fanSpeedText = fanSpeedTextField.text ?? "100"
        let fanSpeedString = fanSpeedText.replacingOccurrences(of: "%", with: "")
        let fanSpeed = Int(fanSpeedString) ?? 100

        // Parse print speed from formatted text (e.g., "50 mm/s")
        let printSpeedText = printSpeedTextField.text ?? "50"
        let printSpeedString = printSpeedText.replacingOccurrences(of: " mm/s", with: "")
        let printSpeed = Int(printSpeedString) ?? 50

        let notes = notesTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines)

        if isEditMode {
            // Update existing filament
            var updatedFilament = filament!

            // Calculate the remaining percentage before updating weight
            let remainingPercentage = updatedFilament.weight > 0 ? (updatedFilament.remainingWeight / updatedFilament.weight) : 1.0

            updatedFilament.brand = brand
            updatedFilament.material = material
            updatedFilament.color = color
            updatedFilament.weight = weight
            updatedFilament.diameter = diameter
            updatedFilament.printTemperature = printTemp
            updatedFilament.bedTemperature = bedTemp
            updatedFilament.fanSpeed = fanSpeed
            updatedFilament.printSpeed = printSpeed
            updatedFilament.notes = notes?.isEmpty == true ? nil : notes

            // Update remaining weight to maintain the same percentage
            updatedFilament.remainingWeight = weight * remainingPercentage

            CoreDataManager.shared.updateFilament(updatedFilament)
            delegate?.didSaveFilament(updatedFilament)
        } else {
            // Create new filament
            let newFilament = Filament(
                brand: brand,
                material: material,
                color: color,
                weight: weight,
                diameter: diameter,
                printTemperature: printTemp,
                bedTemperature: bedTemp,
                fanSpeed: fanSpeed,
                printSpeed: printSpeed,
                notes: notes?.isEmpty == true ? nil : notes
            )

            CoreDataManager.shared.saveFilament(newFilament)
            delegate?.didSaveFilament(newFilament)
        }

        dismiss(animated: true)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Validation

    private func validateForm() -> Bool {
        guard let brand = brandTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !brand.isEmpty else {
            showAlert(title: "Invalid Brand", message: "Please enter a brand name.")
            return false
        }

        guard let material = materialTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !material.isEmpty else {
            showAlert(title: "Invalid Material", message: "Please select a material.")
            return false
        }

        guard let color = colorTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !color.isEmpty else {
            showAlert(title: "Invalid Color", message: "Please enter a color.")
            return false
        }

        return true
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func updateColorSwatch(_ color: UIColor) {
        // Use cached reference for instant updates
        colorSwatchView?.backgroundColor = color
    }

    // MARK: - Custom Brand Management

    private func showAddCustomBrandAlert() {
        let alert = UIAlertController(title: "Add Custom Brand", message: "Enter the name of the filament brand", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Brand name"
            textField.autocapitalizationType = .words
        }

        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self,
                  let textField = alert.textFields?.first,
                  let brandName = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !brandName.isEmpty else { return }

            // Check if brand already exists
            if !self.availableBrands.contains(brandName) {
                // Insert before "Add Custom Brand..." option
                self.availableBrands.insert(brandName, at: self.availableBrands.count - 1)
                if let brandPicker = self.cachedPickerViews[0] {
                    brandPicker.reloadAllComponents()
                }
            }

            // Set the custom brand as selected
            self.brandTextField.text = brandName

            // Select the new brand in the picker
            if let index = self.availableBrands.firstIndex(of: brandName) {
                self.cachedPickerViews[0]?.selectRow(index, inComponent: 0, animated: true)
            }

            self.dismissKeyboard()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            // Reset picker to first item (or current selection)
            guard let self = self else { return }
            if let currentBrand = self.brandTextField.text,
               let index = self.availableBrands.firstIndex(of: currentBrand),
               let brandPicker = self.cachedPickerViews[0] {
                brandPicker.selectRow(index, inComponent: 0, animated: true)
            } else if let brandPicker = self.cachedPickerViews[0] {
                brandPicker.selectRow(0, inComponent: 0, animated: true)
            }
        }

        alert.addAction(addAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }

    // MARK: - Custom Color Picker

    private func showCustomColorPicker() {
        let customColorPicker = CustomColorPickerViewController()
        customColorPicker.delegate = self

        let navController = UINavigationController(rootViewController: customColorPicker)
        navController.modalPresentationStyle = .fullScreen  // Full screen for maximum space
        navController.isModalInPresentation = true  // Prevent swipe-to-dismiss

        present(navController, animated: true)
    }

    // MARK: - Keyboard Handling

    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        let keyboardHeight = keyboardFrame.height
        scrollView.contentInset.bottom = keyboardHeight
        if #available(iOS 13.0, *) {
            scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
        } else {
            scrollView.scrollIndicatorInsets.bottom = keyboardHeight
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset.bottom = 0
        if #available(iOS 13.0, *) {
            scrollView.verticalScrollIndicatorInsets.bottom = 0
        } else {
            scrollView.scrollIndicatorInsets.bottom = 0
        }
    }
}

// MARK: - UIPickerViewDataSource

extension AddEditFilamentViewController: UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case 0: // Brand picker
            return availableBrands.count
        case 1: // Material picker
            return Filament.Material.allCases.count
        case 2: // Color picker
            return availableColors.count
        case 3: // Weight picker
            return Filament.weightOptions.count
        case 4: // Diameter picker
            return Filament.diameterOptions.count
        case 5: // Print temperature picker
            return Filament.temperatureOptions.count
        case 6: // Bed temperature picker
            return Filament.bedTemperatureOptions.count
        case 7: // Fan speed picker
            return Filament.fanSpeedOptions.count
        case 8: // Print speed picker
            return Filament.printSpeedOptions.count
        default:
            return 0
        }
    }
}

// MARK: - UIPickerViewDelegate

extension AddEditFilamentViewController: UIPickerViewDelegate {

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        if pickerView.tag == 2 { // Color picker
            // Reuse views for better performance
            let containerView: UIView
            let colorIndicator: UIView
            let label: UILabel

            if let reusableView = view {
                containerView = reusableView
                colorIndicator = containerView.subviews[0]
                label = containerView.subviews[1] as! UILabel
            } else {
                containerView = UIView()
                containerView.frame = CGRect(x: 0, y: 0, width: 200, height: 30)

                colorIndicator = UIView()
                colorIndicator.layer.cornerRadius = 8
                colorIndicator.layer.borderWidth = 1
                colorIndicator.layer.borderColor = UIColor.systemGray4.cgColor
                colorIndicator.translatesAutoresizingMaskIntoConstraints = false

                label = UILabel()
                label.font = UIFont.systemFont(ofSize: 17)
                label.textColor = .label
                label.translatesAutoresizingMaskIntoConstraints = false

                containerView.addSubview(colorIndicator)
                containerView.addSubview(label)

                NSLayoutConstraint.activate([
                    colorIndicator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
                    colorIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                    colorIndicator.widthAnchor.constraint(equalToConstant: 16),
                    colorIndicator.heightAnchor.constraint(equalToConstant: 16),

                    label.leadingAnchor.constraint(equalTo: colorIndicator.trailingAnchor, constant: 12),
                    label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
                    label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
                ])
            }

            let colorInfo = availableColors[row]
            colorIndicator.backgroundColor = colorInfo.color
            label.text = colorInfo.name

            return containerView
        } else {
            // Reuse labels for other pickers
            let label: UILabel
            if let reusableView = view as? UILabel {
                label = reusableView
            } else {
                label = UILabel()
                label.textAlignment = .center
                label.font = UIFont.systemFont(ofSize: 17)
                label.textColor = .label
            }

            switch pickerView.tag {
            case 0: // Brand picker
                label.text = availableBrands[row]
            case 1: // Material picker
                label.text = Filament.Material.allCases[row].rawValue
            case 3: // Weight picker
                let weight = Filament.weightOptions[row]
                label.text = weight < 1000 ? String(format: "%.0f g", weight) : String(format: "%.1f kg", weight / 1000)
            case 4: // Diameter picker
                label.text = String(format: "%.2f mm", Filament.diameterOptions[row])
            case 5: // Print temperature picker
                label.text = "\(Filament.temperatureOptions[row])°C"
            case 6: // Bed temperature picker
                label.text = "\(Filament.bedTemperatureOptions[row])°C"
            case 7: // Fan speed picker
                label.text = "\(Filament.fanSpeedOptions[row])%"
            case 8: // Print speed picker
                label.text = "\(Filament.printSpeedOptions[row]) mm/s"
            default:
                label.text = ""
            }

            return label
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        // This method is now only used as fallback for older iOS versions
        switch pickerView.tag {
        case 0: // Brand picker
            return availableBrands[row]
        case 1: // Material picker
            return Filament.Material.allCases[row].rawValue
        case 2: // Color picker
            return availableColors[row].name
        default:
            return nil
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag {
        case 0: // Brand picker
            let selectedBrandName = availableBrands[row]

            if selectedBrandName == "Add Custom Brand..." {
                // Show alert to add custom brand
                showAddCustomBrandAlert()
            } else {
                brandTextField.text = selectedBrandName

                // Update weight and diameter defaults when brand changes (only for predefined brands)
                if let predefinedBrand = Filament.Brand.allCases.first(where: { $0.rawValue == selectedBrandName }) {
                    if weightTextField.text?.isEmpty ?? true || weightTextField.text == "1000" {
                        let defaultWeight = predefinedBrand.defaultWeight
                        weightTextField.text = defaultWeight < 1000 ? String(format: "%.0f g", defaultWeight) : String(format: "%.1f kg", defaultWeight / 1000)

                        // Update weight picker selection
                        if let weightIndex = Filament.weightOptions.firstIndex(of: defaultWeight),
                           let weightPicker = cachedPickerViews[3] {
                            weightPicker.selectRow(weightIndex, inComponent: 0, animated: false)
                        }
                    }
                    if diameterTextField.text?.isEmpty ?? true || diameterTextField.text == "1.75" {
                        let defaultDiameter = predefinedBrand.defaultDiameter
                        diameterTextField.text = String(format: "%.2f mm", defaultDiameter)

                        // Update diameter picker selection
                        if let diameterIndex = Filament.diameterOptions.firstIndex(of: defaultDiameter),
                           let diameterPicker = cachedPickerViews[4] {
                            diameterPicker.selectRow(diameterIndex, inComponent: 0, animated: false)
                        }
                    }
                }
            }

        case 1: // Material picker
            let selectedMaterial = Filament.Material.allCases[row]
            materialTextField.text = selectedMaterial.rawValue

            // Auto-fill temperature and speed defaults based on material
            let printTemp = selectedMaterial.defaultPrintTemperature
            let bedTemp = selectedMaterial.defaultBedTemperature
            let fanSpeed = selectedMaterial.defaultFanSpeed
            let printSpeed = selectedMaterial.defaultPrintSpeed

            printTemperatureTextField.text = "\(printTemp)°C"
            bedTemperatureTextField.text = "\(bedTemp)°C"
            fanSpeedTextField.text = "\(fanSpeed)%"
            printSpeedTextField.text = "\(printSpeed) mm/s"

            // Update picker selections
            if let printTempIndex = Filament.temperatureOptions.firstIndex(of: printTemp),
               let printTempPicker = cachedPickerViews[5] {
                printTempPicker.selectRow(printTempIndex, inComponent: 0, animated: false)
            }
            if let bedTempIndex = Filament.bedTemperatureOptions.firstIndex(of: bedTemp),
               let bedTempPicker = cachedPickerViews[6] {
                bedTempPicker.selectRow(bedTempIndex, inComponent: 0, animated: false)
            }
            if let fanSpeedIndex = Filament.fanSpeedOptions.firstIndex(of: fanSpeed),
               let fanSpeedPicker = cachedPickerViews[7] {
                fanSpeedPicker.selectRow(fanSpeedIndex, inComponent: 0, animated: false)
            }
            if let printSpeedIndex = Filament.printSpeedOptions.firstIndex(of: printSpeed),
               let printSpeedPicker = cachedPickerViews[8] {
                printSpeedPicker.selectRow(printSpeedIndex, inComponent: 0, animated: false)
            }

        case 2: // Color picker
            let selectedColorInfo = availableColors[row]

            if selectedColorInfo.name == "Add Custom Color..." {
                // Show custom color picker
                showCustomColorPicker()
            } else {
                colorTextField.text = selectedColorInfo.name
                // Update color swatch
                updateColorSwatch(selectedColorInfo.color)
                // Note: Do not auto-dismiss color picker - let user close with Done button
            }

        case 3: // Weight picker
            let selectedWeight = Filament.weightOptions[row]
            weightTextField.text = selectedWeight < 1000 ? String(format: "%.0f g", selectedWeight) : String(format: "%.1f kg", selectedWeight / 1000)

        case 4: // Diameter picker
            let selectedDiameter = Filament.diameterOptions[row]
            diameterTextField.text = String(format: "%.2f mm", selectedDiameter)

        case 5: // Print temperature picker
            let selectedTemp = Filament.temperatureOptions[row]
            printTemperatureTextField.text = "\(selectedTemp)°C"

        case 6: // Bed temperature picker
            let selectedTemp = Filament.bedTemperatureOptions[row]
            bedTemperatureTextField.text = "\(selectedTemp)°C"

        case 7: // Fan speed picker
            let selectedSpeed = Filament.fanSpeedOptions[row]
            fanSpeedTextField.text = "\(selectedSpeed)%"

        case 8: // Print speed picker
            let selectedSpeed = Filament.printSpeedOptions[row]
            printSpeedTextField.text = "\(selectedSpeed) mm/s"

        default:
            break
        }
    }
}

// MARK: - UITextFieldDelegate

extension AddEditFilamentViewController {

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == brandTextField {
            guard let brandName = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !brandName.isEmpty else { return }

            // Check if this is a new custom brand
            if !availableBrands.contains(brandName) && brandName != "Add Custom Brand..." {
                // Insert before "Add Custom Brand..." option
                availableBrands.insert(brandName, at: availableBrands.count - 1)
                if let brandPicker = cachedPickerViews[0] {
                    brandPicker.reloadAllComponents()
                }
            }
        }
    }
}

// MARK: - CustomColorPickerDelegate

extension AddEditFilamentViewController: CustomColorPickerDelegate {
    func customColorPicker(_ picker: CustomColorPickerViewController, didSelectColor color: UIColor, withName name: String) {
        // Save the custom color
        CustomColorManager.shared.addCustomColor(name: name, color: color)

        // Refresh the color list
        refreshColors()

        // Set the new color as selected
        colorTextField.text = name

        // Update color swatch
        updateColorSwatch(color)

        // Update picker selection to the new color
        if let colorIndex = availableColors.firstIndex(where: { $0.name == name }) {
            if let colorPicker = cachedPickerViews[2] {
                colorPicker.selectRow(colorIndex, inComponent: 0, animated: false)
            }
        }
    }
}
