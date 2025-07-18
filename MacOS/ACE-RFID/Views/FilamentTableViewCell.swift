
import UIKit

class FilamentTableViewCell: UITableViewCell {

    static let identifier = "FilamentTableViewCell"


    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let colorIndicatorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 6
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let brandLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let materialLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let colorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let temperatureLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let weightLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .systemGreen
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let lastUsedLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .regular)
        label.textColor = .tertiaryLabel
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()


    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(containerView)

        containerView.addSubview(colorIndicatorView)
        containerView.addSubview(brandLabel)
        containerView.addSubview(materialLabel)
        containerView.addSubview(colorLabel)
        containerView.addSubview(temperatureLabel)
        containerView.addSubview(weightLabel)
        containerView.addSubview(statusLabel)
        containerView.addSubview(lastUsedLabel)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            colorIndicatorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            colorIndicatorView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            colorIndicatorView.widthAnchor.constraint(equalToConstant: 12),
            colorIndicatorView.heightAnchor.constraint(equalToConstant: 12),

            brandLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            brandLabel.leadingAnchor.constraint(equalTo: colorIndicatorView.trailingAnchor, constant: 8),
            brandLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -8),

            materialLabel.topAnchor.constraint(equalTo: brandLabel.bottomAnchor, constant: 2),
            materialLabel.leadingAnchor.constraint(equalTo: brandLabel.leadingAnchor),
            materialLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -8),

            colorLabel.topAnchor.constraint(equalTo: materialLabel.bottomAnchor, constant: 2),
            colorLabel.leadingAnchor.constraint(equalTo: brandLabel.leadingAnchor),
            colorLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -8),

            temperatureLabel.topAnchor.constraint(equalTo: colorLabel.bottomAnchor, constant: 8),
            temperatureLabel.leadingAnchor.constraint(equalTo: brandLabel.leadingAnchor),
            temperatureLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),

            weightLabel.topAnchor.constraint(equalTo: temperatureLabel.topAnchor),
            weightLabel.leadingAnchor.constraint(equalTo: temperatureLabel.trailingAnchor, constant: 16),
            weightLabel.bottomAnchor.constraint(equalTo: temperatureLabel.bottomAnchor),

            statusLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            statusLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),

            lastUsedLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 4),
            lastUsedLabel.trailingAnchor.constraint(equalTo: statusLabel.trailingAnchor),
            lastUsedLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
    }


    func configure(with filament: Filament) {
        brandLabel.text = filament.brand
        materialLabel.text = filament.material

        let colorName = filament.color.name
        let colorHex = filament.color.hex
        colorLabel.text = "\(colorName) (\(colorHex))"

        temperatureLabel.text = "🌡️ \(filament.printMinTemperature)-\(filament.printMaxTemperature)°C / \(filament.bedMinTemperature)-\(filament.bedMaxTemperature)°C"

        let remainingPercentage = (filament.remainingWeight / filament.weight) * 100
        weightLabel.text = "⚖️ \(String(format: "%.0f", filament.remainingWeight))g (\(String(format: "%.0f", remainingPercentage))%)"

        colorIndicatorView.backgroundColor = filament.color.uiColor ?? .systemGray

        if filament.isFinished {
            statusLabel.text = "Finished"
            statusLabel.textColor = .systemRed
        } else if remainingPercentage < 10 {
            statusLabel.text = "Low"
            statusLabel.textColor = .systemOrange
        } else {
            statusLabel.text = "Available"
            statusLabel.textColor = .systemGreen
        }

        if let lastUsed = filament.lastUsed {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            lastUsedLabel.text = "Used: \(formatter.string(from: lastUsed))"
        } else {
            lastUsedLabel.text = "Never used"
        }
    }
}
