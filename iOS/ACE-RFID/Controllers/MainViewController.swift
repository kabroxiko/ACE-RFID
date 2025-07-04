//
//  MainViewController.swift
//  ACE-RFID
//
//  Created by Copilot on 07/03/2025.
//

import UIKit

class MainViewController: UIViewController {

    // MARK: - UI Elements

    private let tableView = UITableView()
    private let refreshControl = UIRefreshControl()

    // MARK: - Properties

    private var filaments: [Filament] = []
    private let nfcService = NFCService()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNFC()
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
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addFilamentTapped)),
            UIBarButtonItem(image: UIImage(systemName: "wave.3.right"), style: .plain, target: self, action: #selector(scanNFCTapped))
        ]

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

        // Check NFC availability
        if !NFCService.isNFCAvailable {
            #if targetEnvironment(simulator)
            showAlert(title: "NFC Not Available", message: "NFC is not supported in the iOS Simulator. Deploy to a physical iPhone device to test NFC functionality. You can still manage filaments manually.")
            #else
            showAlert(title: "NFC Not Available", message: "This device does not support NFC. You can still manage filaments manually.")
            #endif
        }
    }

    private func setupNFC() {
        nfcService.delegate = self
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

    @objc private func addFilamentTapped() {
        let addViewController = AddEditFilamentViewController()
        addViewController.delegate = self
        let navigationController = UINavigationController(rootViewController: addViewController)
        present(navigationController, animated: true)
    }

    @objc private func scanNFCTapped() {
        guard NFCService.isNFCAvailable else {
            showAlert(title: "NFC Not Available", message: "This device does not support NFC.")
            return
        }

        nfcService.startReading()
    }

    @objc private func refreshFilaments() {
        loadFilaments()
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
            let editViewController = AddEditFilamentViewController(filament: filament)
            editViewController.delegate = self
            let navigationController = UINavigationController(rootViewController: editViewController)
            self.present(navigationController, animated: true)
        })

        // Write to NFC action
        if NFCService.isNFCAvailable {
            alert.addAction(UIAlertAction(title: "Write to NFC Tag", style: .default) { _ in
                self.nfcService.writeFilament(filament)
            })
        }

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

// MARK: - NFCServiceDelegate

extension MainViewController: NFCServiceDelegate {

    func nfcDidReadFilament(_ filament: Filament) {
        // Check if filament already exists
        if let existingFilament = CoreDataManager.shared.fetchFilament(by: filament.id) {
            showAlert(title: "Filament Found", message: "This filament is already in your database: \(existingFilament.brand) \(existingFilament.material)")
        } else {
            // Save new filament
            CoreDataManager.shared.saveFilament(filament)
            loadFilaments()
            showAlert(title: "Filament Added", message: "Successfully added \(filament.brand) \(filament.material) from NFC tag.")
        }
    }

    func nfcDidWriteFilament(_ filament: Filament) {
        showAlert(title: "NFC Write Success", message: "Successfully wrote \(filament.brand) \(filament.material) to NFC tag.")
    }

    func nfcDidFailWithError(_ error: Error) {
        showAlert(title: "NFC Error", message: error.localizedDescription)
    }
}

// MARK: - AddEditFilamentViewControllerDelegate

extension MainViewController: AddEditFilamentViewControllerDelegate {

    func didSaveFilament(_ filament: Filament) {
        loadFilaments()
    }
}
