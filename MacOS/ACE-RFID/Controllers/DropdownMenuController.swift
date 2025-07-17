import UIKit

class DropdownMenuController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let options: [String]
    private let selectionHandler: (String) -> Void
    private let tableView = UITableView()

    init(options: [String], selectionHandler: @escaping (String) -> Void) {
        self.options = options
        self.selectionHandler = selectionHandler
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, macCatalyst 15.0, *) {
            if let sheet = sheetPresentationController {
                sheet.detents = [.medium()]
                sheet.prefersGrabberVisible = true
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTableView()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DropdownCell")
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DropdownCell", for: indexPath)
        cell.textLabel?.text = options[indexPath.row]
        cell.textLabel?.font = .systemFont(ofSize: 17)
        cell.textLabel?.textColor = .label
        cell.selectionStyle = .default
        return cell
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selected = options[indexPath.row]
        dismiss(animated: true) {
            self.selectionHandler(selected)
        }
    }
}
