//
//  Test syntax file
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

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
