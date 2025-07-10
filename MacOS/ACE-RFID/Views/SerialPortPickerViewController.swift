import UIKit

class SerialPortPickerViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    var ports: [String] = []
    var onSelect: ((String?) -> Void)?
    private let pickerView = UIPickerView()
    private let setButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private var selectedPort: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        preferredContentSize = CGSize(width: 320, height: 260)

        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pickerView)

        setButton.setTitle("Set", for: .normal)
        setButton.addTarget(self, action: #selector(setTapped), for: .touchUpInside)
        setButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(setButton)

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            pickerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            pickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            pickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            pickerView.heightAnchor.constraint(equalToConstant: 140),
            setButton.topAnchor.constraint(equalTo: pickerView.bottomAnchor, constant: 20),
            setButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -10),
            cancelButton.topAnchor.constraint(equalTo: pickerView.bottomAnchor, constant: 20),
            cancelButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10)
        ])
    }

    func setPorts(_ ports: [String], preselect: String? = nil) {
        self.ports = ports
        pickerView.reloadAllComponents()
        if let preselect = preselect, let idx = ports.firstIndex(of: preselect) {
            pickerView.selectRow(idx, inComponent: 0, animated: false)
            selectedPort = ports[idx]
        } else if !ports.isEmpty {
            pickerView.selectRow(0, inComponent: 0, animated: false)
            selectedPort = ports[0]
        }
    }

    // MARK: - UIPickerViewDataSource/Delegate
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { ports.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? { ports[row] }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedPort = ports[row]
    }

    @objc private func setTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onSelect?(self?.selectedPort)
        }
    }
    @objc private func cancelTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onSelect?(nil)
        }
    }
}
