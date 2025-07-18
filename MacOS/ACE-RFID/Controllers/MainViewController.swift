
import UIKit
import Foundation

class MainViewController: UIViewController, NFCServiceDelegate {
    private let tableView = UITableView()
    #if !targetEnvironment(macCatalyst)
    private let refreshControl = UIRefreshControl()
    #endif

    private var filaments: [Filament] = []
    private let nfcService: NFCService
    private var availableSerialPorts: [String] = []
    private var selectedSerialPort: String?

    init(nfcService: NFCService) {
        self.nfcService = nfcService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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

    private func setupUI() {
        title = "ACE RFID Filaments"
        view.backgroundColor = .systemBackground

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addFilamentTapped))
        let nfcButton = UIBarButtonItem(image: UIImage(systemName: "radiowaves.left"), style: .plain, target: self, action: #selector(readNFCTapped))
        let configButton = UIBarButtonItem(image: UIImage(systemName: "gearshape"), style: .plain, target: self, action: #selector(configureSerialPortTapped))
        navigationItem.rightBarButtonItems = [addButton, nfcButton, configButton]

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(FilamentTableViewCell.self, forCellReuseIdentifier: FilamentTableViewCell.identifier)
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120

        #if targetEnvironment(macCatalyst)
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshFilaments))
        navigationItem.leftBarButtonItem = refreshButton
        #else
        refreshControl.addTarget(self, action: #selector(refreshFilaments), for: .valueChanged)
        tableView.refreshControl = refreshControl
        #endif

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func readNFCTapped() {
        nfcService.readTag()
    }

    func nfcService(didRead data: Data) {
        if data.count < 128 {
            let hex = data.map { String(format: "%02X", $0) }.joined(separator: " ")
            let msg = "Tag data too short (\(data.count) bytes)\nHex:\n\(hex)\nTry increasing read length or check tag type."
            DispatchQueue.main.async {
                self.showAlert(title: "NFC Data", message: msg)
            }
            return
        }
        let filament = NFCService.decodeFilament(data)

        let info = "SKU: \(filament.sku)\nBrand: \(filament.brand)\nMaterial: \(filament.material)\nColor: \(filament.color.name) (\(filament.color.hex))\nExt: \(Int(filament.printMinTemperature))-\(Int(filament.printMaxTemperature))ºC\nBed: \(Int(filament.bedMinTemperature))-\(Int(filament.bedMaxTemperature))ºC\nLength: \(Int(filament.length)) m\nDiameter: \(filament.diameter) mm"
        DispatchQueue.main.async {
            self.showAlert(title: "NFC Tag Info", message: info)
        }
    }

    func nfcService(didWrite success: Bool) {
        #if targetEnvironment(macCatalyst)
        #endif
        DispatchQueue.main.async {
            let msg = success ? "Filament data written to NFC tag." : "Failed to write filament to NFC tag."
            //self.showAlert(title: "NFC Write Result", message: msg)
        }
    }

    func nfcService(didFail error: Error) {
        DispatchQueue.main.async {
            self.showAlert(title: "NFC Error", message: error.localizedDescription)
        }
    }

    private func loadFilaments() {
        filaments = CoreDataManager.shared.fetchAllFilaments()
        DispatchQueue.main.async {
            self.tableView.reloadData()
            #if !targetEnvironment(macCatalyst)
            self.refreshControl.endRefreshing()
            #endif
        }
    }

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
        }
        pickerVC.modalPresentationStyle = .formSheet
        present(pickerVC, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alertView = UIView()
        alertView.backgroundColor = UIColor.systemBackground
        alertView.layer.cornerRadius = 16
        alertView.layer.shadowColor = UIColor.black.cgColor
        alertView.layer.shadowOpacity = 0.2
        alertView.layer.shadowRadius = 8
        alertView.layer.shadowOffset = CGSize(width: 0, height: 4)
        alertView.translatesAutoresizingMaskIntoConstraints = false

        let iconImageView = UIImageView(image: UIImage(systemName: "radiowaves.left"))
        iconImageView.tintColor = .systemBlue
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        closeButton.tintColor = .systemRed
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(dismissCustomAlert), for: .touchUpInside)

        let saveButton = UIButton(type: .system)
        saveButton.setTitle("Save as Filament", for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        saveButton.tintColor = .systemBlue
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(MainViewController.saveAsFilamentFromAlert), for: .touchUpInside)

        alertView.addSubview(iconImageView)
        alertView.addSubview(titleLabel)
        alertView.addSubview(messageLabel)
        alertView.addSubview(closeButton)
        alertView.addSubview(saveButton)


        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.tag = 9999
        overlay.addSubview(alertView)
        view.addSubview(overlay)

        NSLayoutConstraint.activate([
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            alertView.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            alertView.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            alertView.widthAnchor.constraint(equalToConstant: 320),
            alertView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),

            iconImageView.topAnchor.constraint(equalTo: alertView.topAnchor, constant: 24),
            iconImageView.centerXAnchor.constraint(equalTo: alertView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: alertView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -16),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: alertView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -16),

            saveButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
            saveButton.centerXAnchor.constraint(equalTo: alertView.centerXAnchor),

            closeButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 12),
            closeButton.centerXAnchor.constraint(equalTo: alertView.centerXAnchor),
            closeButton.bottomAnchor.constraint(equalTo: alertView.bottomAnchor, constant: -16)
        ])

        // Animate in
        alertView.alpha = 0
        UIView.animate(withDuration: 0.25) {
            alertView.alpha = 1
        }

        // Store overlay for dismissal
        objc_setAssociatedObject(self, &MainViewController.overlayKey, overlay, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private static var overlayKey: UInt8 = 0

    @objc func saveAsFilamentFromAlert() {
        // Dismiss alert first
        dismissCustomAlert()
        // Present AddEditFilamentViewController
        let addViewController = AddEditFilamentViewController()
        addViewController.delegate = self
        let navigationController = UINavigationController(rootViewController: addViewController)
        present(navigationController, animated: true)
    }

    @objc private func dismissCustomAlert() {
        if let overlay = objc_getAssociatedObject(self, &MainViewController.overlayKey) as? UIView {
            UIView.animate(withDuration: 0.2, animations: {
                overlay.alpha = 0
            }, completion: { _ in
                overlay.removeFromSuperview()
            })
            objc_setAssociatedObject(self, &MainViewController.overlayKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private func showFilamentOptions(for filament: Filament, at indexPath: IndexPath) {
        let alert = UIAlertController(title: filament.brand + " " + filament.material, message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Edit", style: .default) { _ in
            let editViewController = AddEditFilamentViewController()
            editViewController.filament = filament
            editViewController.delegate = self
            let navigationController = UINavigationController(rootViewController: editViewController)
            self.present(navigationController, animated: true)
        })

        alert.addAction(UIAlertAction(title: "Write to Tag", style: .default) { _ in
            self.writeFilamentToTag(filament)
        })

        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.confirmDelete(filament: filament)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = tableView.cellForRow(at: indexPath)
            popover.sourceRect = tableView.cellForRow(at: indexPath)?.bounds ?? CGRect.zero
        }

        present(alert, animated: true)
    }

    private func writeFilamentToTag(_ filament: Filament) {
        let data = NFCService.encodeFilament(filament)
        #if targetEnvironment(macCatalyst)
        #endif
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


extension MainViewController: AddEditFilamentViewControllerDelegate {
    func didSaveFilament(_ filament: Filament) {
        loadFilaments()
    }
}


extension MainViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return availableSerialPorts.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return availableSerialPorts[row]
    }
}
