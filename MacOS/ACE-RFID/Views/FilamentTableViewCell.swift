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

    private let lengthLabel: UILabel = {
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
        containerView.addSubview(lengthLabel)
        containerView.addSubview(statusLabel)

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

            lengthLabel.topAnchor.constraint(equalTo: temperatureLabel.topAnchor),
            lengthLabel.leadingAnchor.constraint(equalTo: temperatureLabel.trailingAnchor, constant: 16),
            lengthLabel.bottomAnchor.constraint(equalTo: temperatureLabel.bottomAnchor),
        ])
    }


    func configure(with filament: Filament) {
        brandLabel.text = filament.brand
        materialLabel.text = filament.material

        let colorName = filament.color.name
        let colorHex = filament.color.hex
        colorLabel.text = "\(colorName) (\(colorHex))"

        temperatureLabel.text = "🌡️ \(filament.printMinTemperature)-\(filament.printMaxTemperature)°C / \(filament.bedMinTemperature)-\(filament.bedMaxTemperature)°C"

        print("[DEBUG] Filament brand: \(filament.brand), material: \(filament.material)")
        print("[DEBUG] Color: \(filament.color.name) (\(filament.color.hex))")
        print("[DEBUG] Print temp: \(filament.printMinTemperature)-\(filament.printMaxTemperature)°C, Bed temp: \(filament.bedMinTemperature)-\(filament.bedMaxTemperature)°C")
        print("[DEBUG] Length: \(filament.length), Converted weight: \(filament.convertedWeight)")
        if filament.convertedWeight % 1000 == 0 {
            print("[DEBUG] Displaying weight as kg: \(filament.convertedWeight / 1000) kg")
        } else {
            print("[DEBUG] Displaying weight as g: \(filament.convertedWeight) g")
        }

        let weight = filament.convertedWeight
        if weight % 1000 == 0 {
            lengthLabel.text = "⚖️ \(weight / 1000) kg"
        } else {
            lengthLabel.text = "⚖️ \(weight) g"
        }

        colorIndicatorView.backgroundColor = filament.color.uiColor ?? .systemGray
    }
}
