//
//  MainViewController.swift
//  ACE-RFID
//
//  Created by Copilot on 07/03/2025.
//

import UIKit
import Foundation

class MainViewController: UIViewController, NFCServiceDelegate {
    // MARK: - UI Elements
    private let tableView = UITableView()
    private let refreshControl = UIRefreshControl()

    // MARK: - Properties
    private var filaments: [Filament] = []
    private let nfcService: NFCService
    private var availableSerialPorts: [String] = []
    private var selectedSerialPort: String?

    // MARK: - Initializer
    init(nfcService: NFCService) {
        self.nfcService = nfcService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        nfcService.delegate = self
        setupUI()
        loadFilaments()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFilaments()
    }

    // MARK: - Setup
    private func setupUI() {
        title = "ACE RFID Filaments"
        view.backgroundColor = .systemBackground

        // Navigation bar setup
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addFilamentTapped))
        let nfcButton = UIBarButtonItem(image: UIImage(systemName: "radiowaves.left"), style: .plain, target: self, action: #selector(readNFCTapped))
        let configButton = UIBarButtonItem(image: UIImage(systemName: "gearshape"), style: .plain, target: self, action: #selector(configureSerialPortTapped))
        navigationItem.rightBarButtonItems = [addButton, nfcButton, configButton]

        // Table view setup
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(FilamentTableViewCell.self, forCellReuseIdentifier: FilamentTableViewCell.identifier)
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120

        // Refresh control
        refreshControl.addTarget(self, action: #selector(refreshFilaments), for: .valueChanged)
        tableView.refreshControl = refreshControl

        view.addSubview(tableView)

        // Constraints
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - NFC Actions
    @objc private func readNFCTapped() {
        print("[DEBUG] Read NFC button tapped")
        nfcService.readTag()
    }

    // MARK: - NFCServiceDelegate
    func nfcService(didRead data: Data) {
        print("[DEBUG] nfcService didRead called, data: \(data as NSData)")
        // Parse NFC card content as in Android
        if data.count < 128 {
            let hex = data.map { String(format: "%02X", $0) }.joined(separator: " ")
            let msg = "Tag data too short (\(data.count) bytes)\nHex:\n\(hex)\nTry increasing read length or check tag type."
            DispatchQueue.main.async {
                self.showAlert(title: "NFC Data", message: msg)
            }
            return
        }
        let buffer = [UInt8](data)
        // Helper to clean field
        func cleanField(_ str: String?) -> String {
            guard let s = str else { return "" }
            return s.replacingOccurrences(of: "\0", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // SKU: bytes 4..19 (16 bytes)
        let sku = cleanField(String(bytes: buffer[4..<20], encoding: .utf8))
        // Brand: bytes 20..43 (24 bytes)
        let brand = cleanField(String(bytes: buffer[20..<44], encoding: .utf8))
        // Material Name: bytes 44..59 (16 bytes)
        let materialName = cleanField(String(bytes: buffer[44..<60], encoding: .utf8))
        // Color: bytes 65..67 (3 bytes, hex)
        let colorHex = buffer[65..<68].map { String(format: "%02X", $0) }.joined()
        // Extruder Min/Max: bytes 96..97, 98..99 (little-endian, scale 1)
        let extMin = Int(buffer[96]) | (Int(buffer[97]) << 8)
        let extMax = Int(buffer[98]) | (Int(buffer[99]) << 8)
        // Bed Min/Max: bytes 116..117, 118..119 (little-endian, scale 1)
        let bedMin = Int(buffer[116]) | (Int(buffer[117]) << 8)
        let bedMax = Int(buffer[118]) | (Int(buffer[119]) << 8)
        // Weight: bytes 106..107 (little-endian, scale 0.001)
        let weightRaw = Int(buffer[107]) << 8 | Int(buffer[106])
        // Filament weight lookup table (raw value to kg)
        let weightTable: [Int: String] = [
            330: "1 kg",
            250: "0.75 kg",
            200: "0.5 kg",
            100: "0.25 kg",
            50: "0.1 kg"
        ]
        let weightDisplay = weightTable[weightRaw] ?? String(format: "%.2f kg", Double(weightRaw) / 1000.0)

        // Show parsed info as alert for now
        let info = "Brand: \(brand)\nSKU: \(sku)\nMaterial: \(materialName)\nColor: #\(colorHex)\nExt: \(extMin)-\(extMax)ºC\nBed: \(bedMin)-\(bedMax)ºC\nWeight: \(weightDisplay)"
        DispatchQueue.main.async {
            self.showAlert(title: "NFC Tag Info", message: info)
        }
    }

    func nfcService(didWrite success: Bool) {
        print("[DEBUG] nfcService didWrite called, success: \(success)")
        if let nfcManager = (nfcService as? NFCManager) {
            print("[DEBUG] NFCManager connectionString: \(nfcManager.debugConnectionString)")
        }
        DispatchQueue.main.async {
            let msg = success ? "Filament data written to NFC tag." : "Failed to write filament to NFC tag."
            self.showAlert(title: "NFC Write Result", message: msg)
        }
    }

    func nfcService(didFail error: Error) {
        print("[DEBUG] nfcService didFail called, error: \(error)")
        DispatchQueue.main.async {
            self.showAlert(title: "NFC Error", message: error.localizedDescription)
        }
    }

    // MARK: - Data Management
    private func loadFilaments() {
        filaments = CoreDataManager.shared.fetchAllFilaments()
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.refreshControl.endRefreshing()
        }
    }

    // MARK: - Actions
    @objc func addFilamentTapped() {
        let addViewController = AddEditFilamentViewController()
        addViewController.delegate = self
        let navigationController = UINavigationController(rootViewController: addViewController)
        present(navigationController, animated: true)
    }

    @objc func refreshFilaments() {
        loadFilaments()
    }

    @objc private func configureSerialPortTapped() {
#if targetEnvironment(macCatalyst)
        // Detect serial ports using FileManager
        let devPath = "/dev"
        let fileManager = FileManager.default
        let ports: [String]
        do {
            let devContents = try fileManager.contentsOfDirectory(atPath: devPath)
            ports = devContents.filter { $0.hasPrefix("cu.usb") }.map { "/dev/" + $0 }
        } catch {
            ports = []
        }
        self.availableSerialPorts = ports
        presentSerialPortPicker(ports: ports)
#else
        showAlert(title: "Not supported", message: "Serial port configuration is only available on Mac Catalyst.")
#endif
    }

    private func presentSerialPortPicker(ports: [String]) {
        let pickerVC = SerialPortPickerViewController()
        // Try to preselect the saved port if available
        #if targetEnvironment(macCatalyst)
        let savedPort = UserDefaults.standard.string(forKey: "ACE_RFID_SelectedSerialPort")
        #else
        let savedPort: String? = nil
        #endif
        pickerVC.setPorts(ports, preselect: savedPort)
        pickerVC.onSelect = { [weak self] selectedPort in
            guard let self = self, let port = selectedPort else { return }
            self.selectedSerialPort = port
#if targetEnvironment(macCatalyst)
            self.nfcService.setPort(port)
#endif
            // Removed alert for 'Serial Port Set'
        }
        pickerVC.modalPresentationStyle = .formSheet
        present(pickerVC, animated: true)
    }

    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showFilamentOptions(for filament: Filament, at indexPath: IndexPath) {
        let alert = UIAlertController(title: filament.brand + " " + filament.material, message: nil, preferredStyle: .actionSheet)

        // Edit action
        alert.addAction(UIAlertAction(title: "Edit", style: .default) { _ in
            let editViewController = AddEditFilamentViewController()
            editViewController.filament = filament
            editViewController.delegate = self
            let navigationController = UINavigationController(rootViewController: editViewController)
            self.present(navigationController, animated: true)
        })

        // Write to Tag action (Android-like NFC write)
        alert.addAction(UIAlertAction(title: "Write to Tag", style: .default) { _ in
            self.writeFilamentToTag(filament)
        })

        // Mark as used action
        alert.addAction(UIAlertAction(title: "Mark as Used", style: .default) { _ in
            var updatedFilament = filament
            updatedFilament.lastUsed = Date()
            CoreDataManager.shared.updateFilament(updatedFilament)
            self.loadFilaments()
        })

        // Delete action
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.confirmDelete(filament: filament)
        })

        // Cancel action
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // For iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = tableView.cellForRow(at: indexPath)
            popover.sourceRect = tableView.cellForRow(at: indexPath)?.bounds ?? CGRect.zero
        }

        present(alert, animated: true)
    }

    // Helper to encode and write filament to NFC tag
    private func writeFilamentToTag(_ filament: Filament) {
        print("[DEBUG] writeFilamentToTag called")
        print("[DEBUG] Filament: \(filament)")
        let data = NFCService.encodeFilament(filament)
        print("[DEBUG] Encoded filament data: \(data as NSData)")
        if let nfcManager = (nfcService as? NFCManager) {
            print("[DEBUG] NFCManager connectionString: \(nfcManager.debugConnectionString)")
        }
        nfcService.writeTag(data: data)
        showAlert(title: "NFC Write", message: "Attempting to write filament to NFC tag. Please hold tag near reader.")
    }

    private func confirmDelete(filament: Filament) {
        let alert = UIAlertController(
            title: "Delete Filament",
            message: "Are you sure you want to delete this filament? This action cannot be undone.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            CoreDataManager.shared.deleteFilament(by: filament.id)
            self.loadFilaments()
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filaments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FilamentTableViewCell.identifier, for: indexPath) as? FilamentTableViewCell else {
            return UITableViewCell()
        }
        let filament = filaments[indexPath.row]
        cell.configure(with: filament)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension MainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let filament = filaments[indexPath.row]
        showFilamentOptions(for: filament, at: indexPath)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let filament = filaments[indexPath.row]
            confirmDelete(filament: filament)
        }
    }
}

// MARK: - AddEditFilamentViewControllerDelegate

extension MainViewController: AddEditFilamentViewControllerDelegate {
    func didSaveFilament(_ filament: Filament) {
        loadFilaments()
    }
}

// MARK: - UIPickerViewDataSource, UIPickerViewDelegate

extension MainViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return availableSerialPorts.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return availableSerialPorts[row]
    }
}
