import UIKit

public protocol SearchBarDelegate: AnyObject {
    /// Called when text changed with 0.25 seconds delay
    ///
    /// - Parameters:
    ///   - searchBar: search bar instance
    ///   - text: seatch text
    func searchBar(_ searchBar: SearchBar, textChanged text: String)

    func searchBarSearchButtonTap(_ searchBar: SearchBar)
    func searchBarDidStartEditing(_ searchBar: SearchBar)
    func searchBarDidFinishEditing(_ searchBar: SearchBar)
    /// Called when keyboard will appear
    ///
    /// - Parameter frame: keyboard frame
    func keyboarWillChangeFrame(_ frame: CGRect)
}

public extension SearchBarDelegate {
    func searchBar(_: SearchBar, textChanged _: String) {}

    func searchBarSearchButtonTap(_: SearchBar) {}
    func searchBarDidStartEditing(_: SearchBar) {}
    func searchBarDidFinishEditing(_: SearchBar) {}

    func keyboarWillChangeFrame(_: CGRect) {}
}

/// Custom implementation for searchBar with more flexible appearence
/// layout is following
///  _________________________________________
/// |  _____________textField_______________  |
/// | |                                     | |
/// | |           |image|label|             | |
/// | |_____________________________________| |
/// |_________________________________________|
///
open class SearchBar: UIView, UITextFieldDelegate {
    open weak var delegate: SearchBarDelegate?

    /// Main input view for search bar
    open var textField: UITextField

    /// Text field frame insets, defaults are: top: 7, left: 8, bottom: 7, right: 8
    open var textFieldInsets: UIEdgeInsets

    /// Icon that shows inside of the textfield
    /// default image contained in bundle
    open var imageView: UIImageView
    open var searchBarImage: UIImage? {
        didSet {
            imageView.image = searchBarImage
            setNeedsLayout()
            layoutIfNeeded()
        }
    }

    open var shouldDrawSearchBarImage: Bool {
        didSet {
            if shouldDrawSearchBarImage {
                imageView.image = searchBarImage
                textField.setLeftPadding(kImageWidth)
                decorationViewLeftAligmentConstraint.constant = 0
            } else {
                imageView.image = nil
                textField.setLeftPadding(kTextFieldLeftInset)
                decorationViewLeftAligmentConstraint.constant = kTextFieldLeftInset
            }
            setNeedsLayout()
            layoutIfNeeded()
        }
    }

    /// Label that appears in center of textfield
    open var placeholderLabel: UILabel
    open var placeholder: String? {
        didSet {
            placeholderLabel.text = placeholder
            setNeedsLayout()
            layoutIfNeeded()
        }
    }

    // MARK: helpers

    var decorationView: UIView
    var decorationViewCenterAligmentConstraint: NSLayoutConstraint!
    var decorationViewLeftAligmentConstraint: NSLayoutConstraint!

    var inputText = ""

    let kTextFieldLeftInset: CGFloat = 8
    let kImageWidth: CGFloat = 30

    /// init with default frame a.k.a (0, 0, screen width, 44)
    public convenience init() {
        let frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 44)
        self.init(frame: frame)
    }

    override public init(frame: CGRect) {
        textField = UITextField()
        textFieldInsets = UIEdgeInsets(top: 7, left: 8, bottom: 7, right: 8)
        placeholderLabel = UILabel()
        decorationView = UIView()
        imageView = UIImageView()
        shouldDrawSearchBarImage = true

        super.init(frame: frame)

        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillChangeFrame),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)

        addSubview(textField)

        setupDefaultAppearence()
        setupDecoration()
        setupTextFieldConstraints()
        setupDecorationViewConstraints()
    }

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Private

    func setupTextFieldConstraints() {
        let views = ["textField": textField]

        let horizontalFormat = "H:|-\(textFieldInsets.left)-[textField]-\(textFieldInsets.right)-|"
        let verticalFormat = "V:|-\(textFieldInsets.top)-[textField(==30)]-\(textFieldInsets.bottom)-|"

        let leftRightConstraints = NSLayoutConstraint.constraints(withVisualFormat: horizontalFormat,
                                                                  options: [],
                                                                  metrics: nil,
                                                                  views: views)

        let topBottomConstraints = NSLayoutConstraint.constraints(withVisualFormat: verticalFormat,
                                                                  options: [],
                                                                  metrics: nil,
                                                                  views: views)
        NSLayoutConstraint.activate(leftRightConstraints + topBottomConstraints)
    }

    func setupDefaultAppearence() {
        textField.backgroundColor = .white
        textField.returnKeyType = .search
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.layer.cornerRadius = 5.0
        textField.clearButtonMode = .always
        textField.delegate = self
        backgroundColor = .lightGray
        textField.setLeftPadding(kTextFieldLeftInset)
        placeholder = "Search me"
        placeholderLabel.font = UIFont.systemFont(ofSize: 14)
        placeholderLabel.textColor = .gray
    }

    func setupDecoration() {
        searchBarImage = UIImage(named: "search_small")
        imageView.image = searchBarImage
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        decorationView.addSubview(imageView)
        textField.setLeftPadding(kImageWidth)

        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.text = placeholder

        decorationView.isUserInteractionEnabled = false
        decorationView.translatesAutoresizingMaskIntoConstraints = false
        decorationView.addSubview(placeholderLabel)

        textField.addSubview(decorationView)
    }

    func setupDecorationViewConstraints() {
        var views: [String: Any] = [:]
        views["decorationView"] = decorationView
        views["placeholderLabel"] = placeholderLabel
        views["imageView"] = imageView

        let decorationContentHorizontalFormat = "H:|-[imageView]-[placeholderLabel]-|"
        let decorationContentImageVerticalFormat = "V:[imageView(<=30)]"
        let decorationVerticalFormat = "V:|-0-[decorationView]-0-|"
        let decorationContentPlaceholderVerticalFormat = "V:|-0-[placeholderLabel]-0-|"

        decorationViewCenterAligmentConstraint = NSLayoutConstraint(item: textField,
                                                                    attribute: .centerX,
                                                                    relatedBy: .equal,
                                                                    toItem: decorationView,
                                                                    attribute: .centerX,
                                                                    multiplier: 1,
                                                                    constant: 0)

        decorationViewLeftAligmentConstraint = NSLayoutConstraint(item: textField,
                                                                  attribute: .left,
                                                                  relatedBy: .equal,
                                                                  toItem: decorationView,
                                                                  attribute: .left,
                                                                  multiplier: 1,
                                                                  constant: 0)

        let imageViewCenterYConstraint = NSLayoutConstraint(item: decorationView,
                                                            attribute: .centerY,
                                                            relatedBy: .equal,
                                                            toItem: imageView,
                                                            attribute: .centerY,
                                                            multiplier: 1,
                                                            constant: 0)

        let decorationVerticalConstraints = NSLayoutConstraint
            .constraints(withVisualFormat: decorationVerticalFormat,
                         options: [],
                         metrics: nil,
                         views: views)

        let decorationContentPlaceholderVerticalConstraints = NSLayoutConstraint
            .constraints(withVisualFormat: decorationContentPlaceholderVerticalFormat,
                         options: [],
                         metrics: nil,
                         views: views)

        let decorationContentImageVerticalConstraints = NSLayoutConstraint
            .constraints(withVisualFormat: decorationContentImageVerticalFormat,
                         options: .alignAllCenterY,
                         metrics: nil,
                         views: views)

        let decorationContentHorizontalConstraints = NSLayoutConstraint
            .constraints(withVisualFormat: decorationContentHorizontalFormat,
                         options: [],
                         metrics: nil,
                         views: views)

        textField.addConstraint(decorationViewCenterAligmentConstraint)
        textField.addConstraint(decorationViewLeftAligmentConstraint)

        decorationView.addConstraint(imageViewCenterYConstraint)
        decorationViewLeftAligmentConstraint.isActive = false

        NSLayoutConstraint.activate(decorationVerticalConstraints +
            decorationContentPlaceholderVerticalConstraints +
            decorationContentHorizontalConstraints +
            decorationContentImageVerticalConstraints)
    }

    // MARK: - UITextFieldDelegate

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.searchBarSearchButtonTap(self)
        return textField.resignFirstResponder()
    }

    public func textFieldDidBeginEditing(_: UITextField) {
        delegate?.searchBarDidStartEditing(self)
    }

    public func textFieldShouldBeginEditing(_: UITextField) -> Bool {
        editingStartAnimation()
        return true
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.searchBarDidFinishEditing(self)
        if let text = textField.text, text.isEmpty {
            editingEndAnimation()
        }
    }

    // MARK: - Animation

    func editingStartAnimation() {
        decorationViewLeftAligmentConstraint.isActive = true
        decorationViewCenterAligmentConstraint.isActive = false
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let __self = self else { return }
            __self.textField.layoutIfNeeded()
        }
    }

    func editingEndAnimation() {
        decorationViewLeftAligmentConstraint.isActive = false
        decorationViewCenterAligmentConstraint.isActive = true
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let __self = self else { return }
            __self.textField.layoutIfNeeded()
        }
    }

    // MARK: - Public

    public func fillText(text: String) {
        if textFieldShouldBeginEditing(textField) {
            textFieldDidBeginEditing(textField)
            delegate?.searchBar(self, textChanged: text)
            placeholderLabel.text = ""
            textField.text = text
        }
    }

    // MARK: - Private

    override open var intrinsicContentSize: CGSize {
        UIView.layoutFittingExpandedSize
    }

    @objc
    func textFieldDidChange(_ textField: UITextField) {
        let inputText = textField.text ?? ""
        placeholderLabel.text = !inputText.isEmpty ? "" : placeholder
        self.inputText = inputText
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let __self = self else { return }
            guard __self.inputText == inputText else { return }
            __self.delegate?.searchBar(__self, textChanged: inputText)
        }
    }

    @objc
    func keyboardWillChangeFrame(notification: NSNotification) {
        let rectValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        if let keyboardFrame = rectValue?.cgRectValue {
            delegate?.keyboarWillChangeFrame(keyboardFrame)
        }
    }
}
