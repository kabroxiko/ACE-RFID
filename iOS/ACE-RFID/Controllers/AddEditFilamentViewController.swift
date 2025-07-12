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

class AddEditFilamentViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, CustomColorPickerDelegate {
    // MARK: - UIPickerViewDataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case 0:
            return availableBrands.count
        case 1:
            return Filament.Material.allCases.count
        case 3:
            return Filament.weightOptions.count
        case 4:
            return Filament.diameterOptions.count
        case 5:
            return Filament.temperatureOptions.count
        case 6:
            return Filament.bedTemperatureOptions.count
        case 7:
            return Filament.fanSpeedOptions.count
        case 8:
            return Filament.printSpeedOptions.count
        default:
            return 0
        }
    }

    // MARK: - Properties

    weak var delegate: AddEditFilamentViewControllerDelegate?
    private var filament: Filament?
    private var isEditMode: Bool { return filament != nil }

    // Brand management
    private var availableBrands: [String] = []

    // Color management
    private var availableColors: [(name: String, color: UIColor)] = []

    // MARK: - UI Elements

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    // Form fields
    private let brandTextField = UITextField()
    private let brandPickerView = UIPickerView()
    private let materialTextField = UITextField()
    private let materialPickerView = UIPickerView()
    private let colorTextField = UITextField()
    // Modern color picker UI elements
    private var colorGridStack: UIStackView?
    private var selectedColorSwatch: UIView?
    private var addCustomColorButton: UIButton?
    private let weightTextField = UITextField()
    private let weightPickerView = UIPickerView()
    private let diameterTextField = UITextField()
    private let diameterPickerView = UIPickerView()
    private let printTemperatureTextField = UITextField()
    private let printTemperaturePickerView = UIPickerView()
    private let bedTemperatureTextField = UITextField()
    private let bedTemperaturePickerView = UIPickerView()
    private let fanSpeedTextField = UITextField()
    private let fanSpeedPickerView = UIPickerView()
    private let printSpeedTextField = UITextField()
    private let printSpeedPickerView = UIPickerView()
    private let notesTextView = UITextView()

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
        initializeBrands()
        initializeColors()
        setupUI()
        setupNavigationBar()
        fillFormWithFilament()
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

        // Update gradient frame when view layout changes
        DispatchQueue.main.async {
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
        brandTextField.inputView = brandPickerView
        brandTextField.delegate = self // Add text field delegate
        brandPickerView.delegate = self
        brandPickerView.dataSource = self
        brandPickerView.tag = 0 // Tag to identify picker
        stackView.addArrangedSubview(createFormField(brandTextField))

        // Material field (unchanged)
        materialTextField.placeholder = "Select material"
        materialTextField.inputView = materialPickerView
        materialPickerView.delegate = self
        materialPickerView.dataSource = self
        materialPickerView.tag = 1 // Tag to identify picker


        // Modern Color Picker Section
        let colorSectionView = UIView()
        colorSectionView.translatesAutoresizingMaskIntoConstraints = false

        let colorLabel = createFieldLabel("Color")
        colorSectionView.addSubview(colorLabel)
        colorLabel.topAnchor.constraint(equalTo: colorSectionView.topAnchor).isActive = true
        colorLabel.leadingAnchor.constraint(equalTo: colorSectionView.leadingAnchor).isActive = true
        colorLabel.trailingAnchor.constraint(equalTo: colorSectionView.trailingAnchor).isActive = true

        // Horizontal scrollable color grid
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        colorSectionView.addSubview(scrollView)
        scrollView.topAnchor.constraint(equalTo: colorLabel.bottomAnchor, constant: 8).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: colorSectionView.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: colorSectionView.trailingAnchor).isActive = true
        scrollView.heightAnchor.constraint(equalToConstant: 56).isActive = true

        let gridStack = UIStackView()
        gridStack.axis = .horizontal
        gridStack.spacing = 12
        gridStack.alignment = .center
        gridStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(gridStack)
        gridStack.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        gridStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        gridStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 12).isActive = true
        gridStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -12).isActive = true
        self.colorGridStack = gridStack

        // Add color swatches to grid
        for (index, colorInfo) in availableColors.enumerated() {
            let swatchButton = UIButton(type: .custom)
            swatchButton.backgroundColor = colorInfo.color
            swatchButton.layer.cornerRadius = 16
            swatchButton.layer.borderWidth = 2
            swatchButton.layer.borderColor = UIColor.systemGray4.cgColor
            swatchButton.translatesAutoresizingMaskIntoConstraints = false
            swatchButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
            swatchButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
            swatchButton.tag = index
            swatchButton.accessibilityLabel = colorInfo.name
            swatchButton.addTarget(self, action: #selector(colorSwatchTapped(_:)), for: .touchUpInside)
            // Show a plus icon for custom color
            if colorInfo.name == "Add Custom Color..." {
                let plusIcon = UIImageView(image: UIImage(systemName: "plus"))
                plusIcon.tintColor = .systemBlue
                plusIcon.translatesAutoresizingMaskIntoConstraints = false
                swatchButton.addSubview(plusIcon)
                NSLayoutConstraint.activate([
                    plusIcon.centerXAnchor.constraint(equalTo: swatchButton.centerXAnchor),
                    plusIcon.centerYAnchor.constraint(equalTo: swatchButton.centerYAnchor),
                    plusIcon.widthAnchor.constraint(equalToConstant: 18),
                    plusIcon.heightAnchor.constraint(equalToConstant: 18)
                ])
            }
            gridStack.addArrangedSubview(swatchButton)
        }

        // Selected color preview and name field
        let colorPreviewStack = UIStackView()
        colorPreviewStack.axis = .horizontal
        colorPreviewStack.spacing = 12
        colorPreviewStack.alignment = .center
        colorPreviewStack.translatesAutoresizingMaskIntoConstraints = false
        colorSectionView.addSubview(colorPreviewStack)
        colorPreviewStack.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 12).isActive = true
        colorPreviewStack.leadingAnchor.constraint(equalTo: colorSectionView.leadingAnchor).isActive = true
        colorPreviewStack.trailingAnchor.constraint(equalTo: colorSectionView.trailingAnchor).isActive = true
        colorPreviewStack.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let previewSwatch = UIView()
        previewSwatch.layer.cornerRadius = 12
        previewSwatch.layer.borderWidth = 1.5
        previewSwatch.layer.borderColor = UIColor.systemGray4.cgColor
        previewSwatch.backgroundColor = .systemBlue
        previewSwatch.translatesAutoresizingMaskIntoConstraints = false
        previewSwatch.widthAnchor.constraint(equalToConstant: 32).isActive = true
        previewSwatch.heightAnchor.constraint(equalToConstant: 32).isActive = true
        colorPreviewStack.addArrangedSubview(previewSwatch)
        self.selectedColorSwatch = previewSwatch

        colorTextField.placeholder = "Color name"
        colorTextField.borderStyle = .roundedRect
        colorTextField.font = .systemFont(ofSize: 16)
        colorTextField.textColor = .label
        colorTextField.translatesAutoresizingMaskIntoConstraints = false
        colorPreviewStack.addArrangedSubview(colorTextField)

        // Add Custom Color button
        let customColorButton = UIButton(type: .system)
        customColorButton.setTitle("Add Custom Color", for: .normal)
        customColorButton.setTitleColor(.systemBlue, for: .normal)
        customColorButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        customColorButton.layer.cornerRadius = 8
        customColorButton.layer.borderWidth = 1
        customColorButton.layer.borderColor = UIColor.systemBlue.cgColor
        customColorButton.backgroundColor = .secondarySystemBackground
        customColorButton.translatesAutoresizingMaskIntoConstraints = false
        customColorButton.heightAnchor.constraint(equalToConstant: 36).isActive = true
        customColorButton.addTarget(self, action: #selector(addCustomColorTapped), for: .touchUpInside)
        colorSectionView.addSubview(customColorButton)
        customColorButton.topAnchor.constraint(equalTo: colorPreviewStack.bottomAnchor, constant: 8).isActive = true
        customColorButton.leadingAnchor.constraint(equalTo: colorSectionView.leadingAnchor).isActive = true
        customColorButton.widthAnchor.constraint(equalToConstant: 160).isActive = true
        customColorButton.bottomAnchor.constraint(equalTo: colorSectionView.bottomAnchor).isActive = true
        self.addCustomColorButton = customColorButton

        // Add to stackView
        // Add material and color sections side by side
        let materialColorContainer = UIView()
        materialColorContainer.translatesAutoresizingMaskIntoConstraints = false

        let horizontalStack = UIStackView()
        horizontalStack.axis = .horizontal
        horizontalStack.spacing = 16
        horizontalStack.distribution = .fillEqually
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false
        materialColorContainer.addSubview(horizontalStack)
        NSLayoutConstraint.activate([
            horizontalStack.topAnchor.constraint(equalTo: materialColorContainer.topAnchor),
            horizontalStack.leadingAnchor.constraint(equalTo: materialColorContainer.leadingAnchor),
            horizontalStack.trailingAnchor.constraint(equalTo: materialColorContainer.trailingAnchor),
            horizontalStack.bottomAnchor.constraint(equalTo: materialColorContainer.bottomAnchor)
        ])

        // Left: Material
        let leftContainer = UIView()
        let leftLabelView = createFieldLabel("Material")
        let leftFieldView = createFormField(materialTextField)
        leftContainer.addSubview(leftLabelView)
        leftContainer.addSubview(leftFieldView)
        leftContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leftLabelView.topAnchor.constraint(equalTo: leftContainer.topAnchor),
            leftLabelView.leadingAnchor.constraint(equalTo: leftContainer.leadingAnchor),
            leftLabelView.trailingAnchor.constraint(equalTo: leftContainer.trailingAnchor),
            leftFieldView.topAnchor.constraint(equalTo: leftLabelView.bottomAnchor, constant: 8),
            leftFieldView.leadingAnchor.constraint(equalTo: leftContainer.leadingAnchor),
            leftFieldView.trailingAnchor.constraint(equalTo: leftContainer.trailingAnchor),
            leftFieldView.bottomAnchor.constraint(equalTo: leftContainer.bottomAnchor)
        ])

        // Right: Color (use colorSectionView directly)
        let rightContainer = UIView()
        let rightLabelView = createFieldLabel("Color")
        rightContainer.addSubview(rightLabelView)
        rightContainer.addSubview(colorSectionView)
        rightContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rightLabelView.topAnchor.constraint(equalTo: rightContainer.topAnchor),
            rightLabelView.leadingAnchor.constraint(equalTo: rightContainer.leadingAnchor),
            rightLabelView.trailingAnchor.constraint(equalTo: rightContainer.trailingAnchor),
            colorSectionView.topAnchor.constraint(equalTo: rightLabelView.bottomAnchor, constant: 8),
            colorSectionView.leadingAnchor.constraint(equalTo: rightContainer.leadingAnchor),
            colorSectionView.trailingAnchor.constraint(equalTo: rightContainer.trailingAnchor),
            colorSectionView.bottomAnchor.constraint(equalTo: rightContainer.bottomAnchor)
        ])

        horizontalStack.addArrangedSubview(leftContainer)
        horizontalStack.addArrangedSubview(rightContainer)
        stackView.addArrangedSubview(materialColorContainer)

        // Weight and Diameter side by side
        weightTextField.placeholder = "Select weight"
        weightTextField.text = "1.0 kg" // Default value - properly formatted
        weightTextField.inputView = weightPickerView
        weightPickerView.delegate = self
        weightPickerView.dataSource = self
        weightPickerView.tag = 3 // Tag to identify picker

        diameterTextField.placeholder = "Select diameter"
        diameterTextField.text = "1.75 mm" // Default value - properly formatted
        diameterTextField.inputView = diameterPickerView
        diameterPickerView.delegate = self
        diameterPickerView.dataSource = self
        diameterPickerView.tag = 4 // Tag to identify picker

        stackView.addArrangedSubview(createSideBySideFormFields(weightTextField, leftLabel: "Weight", diameterTextField, rightLabel: "Diameter"))

        // Print and Bed Temperature side by side
        printTemperatureTextField.placeholder = "Select temperature"
        printTemperatureTextField.text = "200°C" // Default value - properly formatted
        printTemperatureTextField.inputView = printTemperaturePickerView
        printTemperaturePickerView.delegate = self
        printTemperaturePickerView.dataSource = self
        printTemperaturePickerView.tag = 5 // Tag to identify picker

        bedTemperatureTextField.placeholder = "Select temperature"
        bedTemperatureTextField.text = "60°C" // Default value - properly formatted
        bedTemperatureTextField.inputView = bedTemperaturePickerView
        bedTemperaturePickerView.delegate = self
        bedTemperaturePickerView.dataSource = self
        bedTemperaturePickerView.tag = 6 // Tag to identify picker

        stackView.addArrangedSubview(createSideBySideFormFields(printTemperatureTextField, leftLabel: "Print Temperature", bedTemperatureTextField, rightLabel: "Bed Temperature"))

        // Fan Speed and Print Speed side by side
        fanSpeedTextField.placeholder = "Select fan speed"
        fanSpeedTextField.text = "100%" // Default value - properly formatted
        fanSpeedTextField.inputView = fanSpeedPickerView
        fanSpeedPickerView.delegate = self
        fanSpeedPickerView.dataSource = self
        fanSpeedPickerView.tag = 7 // Tag to identify picker

        printSpeedTextField.placeholder = "Select print speed"
        printSpeedTextField.text = "50 mm/s" // Default value - properly formatted
        printSpeedTextField.inputView = printSpeedPickerView
        printSpeedPickerView.delegate = self
        printSpeedPickerView.dataSource = self
        printSpeedPickerView.tag = 8 // Tag to identify picker

        stackView.addArrangedSubview(createSideBySideFormFields(fanSpeedTextField, leftLabel: "Fan Speed", printSpeedTextField, rightLabel: "Print Speed"))

        // Notes section
        stackView.addArrangedSubview(createSectionLabel("Notes"))
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
        stackView.addArrangedSubview(notesTextView)

        // Add toolbar to picker keyboards
        addToolbarToPickers()
        // Add toolbar to number pad keyboards
        addToolbarToKeyboard()
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
        colorSwatchView.layer.cornerRadius = 8
        colorSwatchView.layer.borderWidth = 1
        colorSwatchView.layer.borderColor = UIColor.systemGray4.cgColor
        colorSwatchView.backgroundColor = .systemBlue // Default color
        colorSwatchView.translatesAutoresizingMaskIntoConstraints = false

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
            colorSwatchView.widthAnchor.constraint(equalToConstant: 16),
            colorSwatchView.heightAnchor.constraint(equalToConstant: 16),

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
    }

    private func addToolbarToKeyboard() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))

        toolbar.items = [flexSpace, doneButton]

        // All form fields now use pickers, so only add toolbar to text view
        notesTextView.inputAccessoryView = toolbar
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

        // Set picker views to correct selections
        if let brandIndex = availableBrands.firstIndex(of: filament.brand) {
            brandPickerView.selectRow(brandIndex, inComponent: 0, animated: false)
        } else {
            // Add custom brand if not in list
            availableBrands.insert(filament.brand, at: availableBrands.count - 1)
            brandPickerView.reloadAllComponents()
            if let brandIndex = availableBrands.firstIndex(of: filament.brand) {
                brandPickerView.selectRow(brandIndex, inComponent: 0, animated: false)
            }
        }

        if let materialIndex = Filament.Material.allCases.firstIndex(where: { $0.rawValue == filament.material }) {
            materialPickerView.selectRow(materialIndex, inComponent: 0, animated: false)
        }

        if let colorIndex = availableColors.firstIndex(where: { $0.name == filament.color }) {
            updateColorSwatch(availableColors[colorIndex].color)
        }

        // Set weight picker selection
        if let weightIndex = Filament.weightOptions.firstIndex(of: weight) {
            weightPickerView.selectRow(weightIndex, inComponent: 0, animated: false)
        }

        // Set diameter picker selection
        if let diameterIndex = Filament.diameterOptions.firstIndex(of: filament.diameter) {
            diameterPickerView.selectRow(diameterIndex, inComponent: 0, animated: false)
        }

        // Set temperature and speed picker selections
        if let printTempIndex = Filament.temperatureOptions.firstIndex(of: filament.printTemperature) {
            printTemperaturePickerView.selectRow(printTempIndex, inComponent: 0, animated: false)
        }

        if let bedTempIndex = Filament.bedTemperatureOptions.firstIndex(of: filament.bedTemperature) {
            bedTemperaturePickerView.selectRow(bedTempIndex, inComponent: 0, animated: false)
        }

        if let fanSpeedIndex = Filament.fanSpeedOptions.firstIndex(of: filament.fanSpeed) {
            fanSpeedPickerView.selectRow(fanSpeedIndex, inComponent: 0, animated: false)
        }

        if let printSpeedIndex = Filament.printSpeedOptions.firstIndex(of: filament.printSpeed) {
            printSpeedPickerView.selectRow(printSpeedIndex, inComponent: 0, animated: false)
        }
    }

    private func setDefaultValues() {
        // Set default brand (first one - Anycubic)
        let defaultBrand = Filament.Brand.anycubic
        brandTextField.text = defaultBrand.rawValue
        if let index = availableBrands.firstIndex(of: defaultBrand.rawValue) {
            brandPickerView.selectRow(index, inComponent: 0, animated: false)
        }

        // Set default material (PLA)
        let defaultMaterial = Filament.Material.pla
        materialTextField.text = defaultMaterial.rawValue
        materialPickerView.selectRow(0, inComponent: 0, animated: false)

        // Set default color (Black)
        let defaultColorName = availableColors.first?.name ?? "Black"
        let defaultColor = availableColors.first?.color ?? UIColor.black
        colorTextField.text = defaultColorName
        updateColorSwatch(defaultColor)

        // Set default weight and diameter with proper formatting
        let defaultWeight = defaultBrand.defaultWeight
        weightTextField.text = defaultWeight < 1000 ? String(format: "%.0f g", defaultWeight) : String(format: "%.1f kg", defaultWeight / 1000)
        if let weightIndex = Filament.weightOptions.firstIndex(of: defaultWeight) {
            weightPickerView.selectRow(weightIndex, inComponent: 0, animated: false)
        }

        let defaultDiameter = defaultBrand.defaultDiameter
        diameterTextField.text = String(format: "%.2f mm", defaultDiameter)
        if let diameterIndex = Filament.diameterOptions.firstIndex(of: defaultDiameter) {
            diameterPickerView.selectRow(diameterIndex, inComponent: 0, animated: false)
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
            printTemperaturePickerView.selectRow(printTempIndex, inComponent: 0, animated: false)
        }
        if let bedTempIndex = Filament.bedTemperatureOptions.firstIndex(of: bedTemp) {
            bedTemperaturePickerView.selectRow(bedTempIndex, inComponent: 0, animated: false)
        }
        if let fanSpeedIndex = Filament.fanSpeedOptions.firstIndex(of: fanSpeed) {
            fanSpeedPickerView.selectRow(fanSpeedIndex, inComponent: 0, animated: false)
        }
        if let printSpeedIndex = Filament.printSpeedOptions.firstIndex(of: printSpeed) {
            printSpeedPickerView.selectRow(printSpeedIndex, inComponent: 0, animated: false)
        }
    }

    private func initializeBrands() {
        // Start with predefined brands (sorted alphabetically)
        availableBrands = Filament.Brand.sortedCases.map { $0.rawValue }
        // Add "Add Custom Brand..." option at the end
        availableBrands.append("Add Custom Brand...")
    }

    private func initializeColors() {
        // Get all available colors (predefined + custom)
        availableColors = Filament.Color.allAvailableColors
        // Add "Add Custom Color..." option at the end
        availableColors.append(("Add Custom Color...", UIColor.systemBlue))
        // Repopulate color grid if UI exists
        if let gridStack = colorGridStack {
            gridStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            for (index, colorInfo) in availableColors.enumerated() {
                let swatchButton = UIButton(type: .custom)
                swatchButton.backgroundColor = colorInfo.color
                swatchButton.layer.cornerRadius = 16
                swatchButton.layer.borderWidth = 2
                swatchButton.layer.borderColor = UIColor.systemGray4.cgColor
                swatchButton.translatesAutoresizingMaskIntoConstraints = false
                swatchButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
                swatchButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
                swatchButton.tag = index
                swatchButton.accessibilityLabel = colorInfo.name
                swatchButton.addTarget(self, action: #selector(colorSwatchTapped(_:)), for: .touchUpInside)
                if colorInfo.name == "Add Custom Color..." {
                    let plusIcon = UIImageView(image: UIImage(systemName: "plus"))
                    plusIcon.tintColor = .systemBlue
                    plusIcon.translatesAutoresizingMaskIntoConstraints = false
                    swatchButton.addSubview(plusIcon)
                    NSLayoutConstraint.activate([
                        plusIcon.centerXAnchor.constraint(equalTo: swatchButton.centerXAnchor),
                        plusIcon.centerYAnchor.constraint(equalTo: swatchButton.centerYAnchor),
                        plusIcon.widthAnchor.constraint(equalToConstant: 18),
                        plusIcon.heightAnchor.constraint(equalToConstant: 18)
                    ])
                }
                gridStack.addArrangedSubview(swatchButton)
            }
        }
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
        // Update the redesigned color swatch preview
        selectedColorSwatch?.backgroundColor = color
    }

    // MARK: - Redesigned Color Picker Actions
    @objc private func colorSwatchTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < availableColors.count else { return }
        let colorInfo = availableColors[index]
        if colorInfo.name == "Add Custom Color..." {
            addCustomColorTapped()
        } else {
            colorTextField.text = colorInfo.name
            updateColorSwatch(colorInfo.color)
        }
    }

    @objc private func addCustomColorTapped() {
        showCustomColorPicker()
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
                self.brandPickerView.reloadAllComponents()
            }

            // Set the custom brand as selected
            self.brandTextField.text = brandName

            // Select the new brand in the picker
            if let index = self.availableBrands.firstIndex(of: brandName) {
                self.brandPickerView.selectRow(index, inComponent: 0, animated: true)
            }

            self.dismissKeyboard()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            // Reset picker to first item (or current selection)
            guard let self = self else { return }
            if let currentBrand = self.brandTextField.text,
               let index = self.availableBrands.firstIndex(of: currentBrand) {
                self.brandPickerView.selectRow(index, inComponent: 0, animated: true)
            } else {
                self.brandPickerView.selectRow(0, inComponent: 0, animated: true)
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
        navController.modalPresentationStyle = .pageSheet
        navController.isModalInPresentation = true  // Prevent swipe-to-dismiss for iOS 14+

        if #available(iOS 15.0, *) {
            if let sheet = navController.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = false  // Remove grabber to discourage swipe-to-dismiss
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false  // Disable scroll-to-expand
                sheet.prefersEdgeAttachedInCompactHeight = true  // Keep attached to edge
                sheet.largestUndimmedDetentIdentifier = .large  // Keep background dimmed
            }
        }

        present(navController, animated: true)
    }

    private func refreshColors() {
        // Refresh the colors list and reload the color grid
        initializeColors()
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
    // MARK: - UITextFieldDelegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == brandTextField {
            guard let brandName = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !brandName.isEmpty else { return }

            // Check if this is a new custom brand
            if !availableBrands.contains(brandName) && brandName != "Add Custom Brand..." {
                // Insert before "Add Custom Brand..." option
                availableBrands.insert(brandName, at: availableBrands.count - 1)
                brandPickerView.reloadAllComponents()
            }
        }
    }

    // MARK: - CustomColorPickerDelegate
    func customColorPicker(_ picker: CustomColorPickerViewController, didSelectColor color: UIColor, withName name: String) {
        // Save the custom color
        CustomColorManager.shared.addCustomColor(name: name, color: color)
        // Refresh the color list
        refreshColors()
        // Set the new color as selected
        colorTextField.text = name
        // Update color swatch
        updateColorSwatch(color)
    }
}
