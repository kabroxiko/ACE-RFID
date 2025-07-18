
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
            self.showFilamentSaveAlert(title: "NFC Tag Info", message: info)
        }
    }

    func nfcService(didWrite success: Bool) {
        #if targetEnvironment(macCatalyst)
        #endif
        DispatchQueue.main.async {
            //self.showAlert(title: "NFC Write Result", message: success ? "Filament data written to NFC tag." : "Failed to write filament to NFC tag.")
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
        FancyAlert.show(
            on: self,
            title: title,
            message: message
        )
    }

    private func showFilamentSaveAlert(title: String, message: String) {
        let circleIcon = UIImage(systemName: "circle")
        let saveButton = FancyAlert.AlertButton(title: "Save as Filament", action: { [weak self] in
            guard let self = self else { return }
            let addViewController = AddEditFilamentViewController()
            addViewController.delegate = self
            let navigationController = UINavigationController(rootViewController: addViewController)
            self.present(navigationController, animated: true)
        })
        let cancelButton = FancyAlert.AlertButton(title: "Cancel", action: nil)
        FancyAlert.show(
            on: self,
            title: title,
            message: message,
            icon: circleIcon,
            buttons: [saveButton, cancelButton]
        )
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
        let icon = UIImage(systemName: "circle")
        let editButton = FancyAlert.AlertButton(title: "Edit", action: { [weak self] in
            guard let self = self else { return }
            let editViewController = AddEditFilamentViewController()
            editViewController.filament = filament
            editViewController.delegate = self
            let navigationController = UINavigationController(rootViewController: editViewController)
            self.present(navigationController, animated: true)
        })
        let writeButton = FancyAlert.AlertButton(title: "Write to Tag", action: { [weak self] in
            self?.writeFilamentToTag(filament)
        })
        let deleteButton = FancyAlert.AlertButton(title: "Delete", action: { [weak self] in
            self?.confirmDelete(filament: filament)
        })
        let cancelButton = FancyAlert.AlertButton(title: "Cancel", action: nil)
        FancyAlert.show(
            on: self,
            title: filament.brand + " " + filament.material,
            message: "",
            icon: icon,
            buttons: [editButton, writeButton, deleteButton, cancelButton]
        )
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
