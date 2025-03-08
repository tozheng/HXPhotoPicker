//
//  EditorStickerTextView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/7/22.
//

import UIKit

class EditorStickerTextView: UIView {
    let config: EditorConfiguration.Text
    var textView: UITextView!
    private var boldButton: UIButton!
    private var italicButton: UIButton!
    private var underlineButton: UIButton!
    private var strikethroughButton: UIButton!
    private var fontButton: UIButton!
    private var colorButton: UIButton!
    private var buttonBkView: UIView!
    var customColorView: EditorStickerTextViewCell!
    
    var selectedFontFamilyName: String = UIFont.boldSystemFont(ofSize: 25).familyName {
        didSet {
            boldButton.isSelected = false
            boldButton.isEnabled = UIFont(name: selectedFontFamilyName, size: config.font.pointSize)?.bold() != nil
            italicButton.isSelected = false
            italicButton.isEnabled = UIFont(name: selectedFontFamilyName, size: config.font.pointSize)?.italic() != nil
            fontChanged(isBold: boldButton.isSelected, isItalic: italicButton.isSelected)
        }
    }
    
    var text: String {
        textView.text
    }
    var currentSelectedIndex: Int = 0
    var customColor: PhotoEditorBrushCustomColor
    var isShowCustomColor: Bool {
        if #available(iOS 14.0, *), config.colors.count > 1 {
            return true
        }
        return false
    }
    var currentSelectedColor: UIColor = .clear
    var typingAttributes: [NSAttributedString.Key: Any] = [:]
    var stickerText: EditorStickerText?
    
    var showBackgroudColor: Bool = false
    var useBgColor: UIColor = .clear
    var textIsDelete: Bool = false
    var textLayer: EditorStickerTextLayer?
    var rectArray: [CGRect] = []
    var blankWidth: CGFloat = 22
    var layerRadius: CGFloat = 8
    var keyboardFrame: CGRect = .zero
    var maxIndex: Int = 0
    
    init(
        config: EditorConfiguration.Text,
        stickerText: EditorStickerText?
    ) {
        self.config = config
        if #available(iOS 14.0, *), config.colors.count > 1, let color = config.colors.last?.color {
            self.customColor = .init(color: color)
        }else {
            self.customColor = .init(color: .clear)
        }
        self.stickerText = stickerText
        super.init(frame: .zero)
        initViews()
        setupTextConfig()
        setupStickerText()
        setupTextColors()
        addKeyboardNotificaition()
        
        textView.becomeFirstResponder()
    }
    
    private func initViews() {
        textView = UITextView()
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.layoutManager.delegate = self
        textView.textContainerInset = UIEdgeInsets(
            top: 15,
            left: 15 + UIDevice.leftMargin,
            bottom: 15,
            right: 15 + UIDevice.rightMargin
        )
        textView.contentInset = .zero
        addSubview(textView)
        
        buttonBkView = UIView()
        buttonBkView.backgroundColor = UIColor.gray.withAlphaComponent(0.6)
        buttonBkView.layer.cornerRadius = 18
        buttonBkView.clipsToBounds = true
        addSubview(buttonBkView)
        
        let selectedColor = UIColor(red: 23/255.0, green: 125/255.0, blue: 247/255.0, alpha: 1.0)
        boldButton = UIButton(type: .custom)
        boldButton.tintColor = UIColor.white
        boldButton.setImage(UIImage(systemName: "bold"), for: .normal)
        boldButton.setImage(UIImage(systemName: "bold")?.withColor(selectedColor), for: .selected)
        boldButton.addTarget(self, action: #selector(didBoldButtonClick(button:)), for: .touchUpInside)
        addSubview(boldButton)

        italicButton = UIButton(type: .custom)
        italicButton.tintColor = UIColor.white
        italicButton.setImage(UIImage(systemName: "italic"), for: .normal)
        italicButton.setImage(UIImage(systemName: "italic")?.withColor(selectedColor), for: .selected)
        italicButton.addTarget(self, action: #selector(didItalicButtonClick(button:)), for: .touchUpInside)
        addSubview(italicButton)

        underlineButton = UIButton(type: .custom)
        underlineButton.tintColor = UIColor.white
        underlineButton.setImage(UIImage(systemName: "underline"), for: .normal)
        underlineButton.setImage(UIImage(systemName: "underline")?.withColor(selectedColor), for: .selected)
        underlineButton.addTarget(self, action: #selector(didUnderlineButtonClick(button:)), for: .touchUpInside)
        addSubview(underlineButton)

        strikethroughButton = UIButton(type: .custom)
        strikethroughButton.tintColor = UIColor.white
        strikethroughButton.setImage(UIImage(systemName: "strikethrough"), for: .normal)
        strikethroughButton.setImage(UIImage(systemName: "strikethrough")?.withColor(selectedColor), for: .selected)
        strikethroughButton.addTarget(self, action: #selector(didStrikethroughButtonClick(button:)), for: .touchUpInside)
        addSubview(strikethroughButton)

        fontButton = UIButton(type: .custom)
        fontButton.tintColor = UIColor.white
        fontButton.setImage(UIImage(systemName: "textformat"), for: .normal)
        fontButton.addTarget(self, action: #selector(didFontButtonClick(button:)), for: .touchUpInside)
        addSubview(fontButton)

        customColorView = EditorStickerTextViewCell()
        customColorView.customColor = customColor
        addSubview(customColorView)

        colorButton = UIButton(type: .custom)
        colorButton.tintColor = UIColor.white
        colorButton.addTarget(self, action: #selector(didColorButtonClick(button:)), for: .touchUpInside)
        addSubview(colorButton)

        selectedFontFamilyName = config.font.familyName
    }
    
    private func setupStickerText() {
        if let text = stickerText {
            showBackgroudColor = text.showBackgroud
            textView.text = text.text
        }
        setupTextAttributes()
    }
    
    private func setupTextConfig() {
        textView.tintColor = config.tintColor
    }
    
    private func setupTextAttributes() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        let attributes = [NSAttributedString.Key.font: config.font,
                          NSAttributedString.Key.paragraphStyle: paragraphStyle]
        typingAttributes = attributes
        textView.attributedText = NSAttributedString(string: stickerText?.text ?? "", attributes: attributes)
    }
    
    private func setupTextColors() {
        var hasColor: Bool = false
        for (index, colorHex) in config.colors.enumerated() {
            let color = colorHex.color
            if let text = stickerText {
                if color == text.textColor {
                    if text.showBackgroud {
                        if color.isWhite {
                            changeTextColor(color: .black)
                        }else {
                            changeTextColor(color: .white)
                        }
                        useBgColor = color
                    }else {
                        changeTextColor(color: color)
                    }
                    currentSelectedColor = color
                    hasColor = true
                }
            }else {
                if index == 0 {
                    changeTextColor(color: color)
                    currentSelectedColor = color
                    hasColor = true
                }
            }
        }
        if !hasColor {
            if let text = stickerText {
                changeTextColor(color: text.textColor)
                currentSelectedColor = text.textColor
            }
        }
        if boldButton.isSelected {
            drawTextBackgroudColor()
        }
    }
    
    @objc
    private func didTextButtonClick(button: UIButton) {
        button.isSelected = !button.isSelected
        showBackgroudColor = button.isSelected
        useBgColor = currentSelectedColor
        if button.isSelected {
            if currentSelectedColor.isWhite {
                changeTextColor(color: .black)
            }else {
                changeTextColor(color: .white)
            }
        }else {
            changeTextColor(color: currentSelectedColor)
        }
    }
    
    private func fontChanged(isBold: Bool, isItalic: Bool) {
        var font = UIFont(name: selectedFontFamilyName, size: config.font.pointSize)
        if isBold && isItalic {
            font = font?.boldItalic()
        } else if isBold {
            font = font?.bold()
        } else if isItalic {
            font = font?.italic()
        }

        textView.font = font
        var attributes = typingAttributes
        attributes[NSAttributedString.Key.font] = font
        typingAttributes = attributes
        textView.typingAttributes = typingAttributes
        textView.attributedText = NSAttributedString(string: textView.text, attributes: typingAttributes)
    }

    @objc
    private func didBoldButtonClick(button: UIButton) {
        button.isSelected = !button.isSelected
        fontChanged(isBold: boldButton.isSelected, isItalic: italicButton.isSelected)
    }

    @objc
    private func didItalicButtonClick(button: UIButton) {
        button.isSelected = !button.isSelected
        fontChanged(isBold: boldButton.isSelected, isItalic: italicButton.isSelected)
    }

    @objc
    private func didUnderlineButtonClick(button: UIButton) {
        button.isSelected = !button.isSelected

        var attributes = typingAttributes
        if button.isSelected {
            attributes[NSAttributedString.Key.underlineStyle] = NSUnderlineStyle.single.rawValue
        } else {
            attributes[NSAttributedString.Key.underlineStyle] = nil
        }

        typingAttributes = attributes
        textView.typingAttributes = typingAttributes
        textView.attributedText = NSAttributedString(string: textView.text, attributes: typingAttributes)
    }

    @objc
    private func didStrikethroughButtonClick(button: UIButton) {
        button.isSelected = !button.isSelected

        var attributes = typingAttributes
        if button.isSelected {
            attributes[NSAttributedString.Key.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        } else {
            attributes[NSAttributedString.Key.strikethroughStyle] = nil
        }

        typingAttributes = attributes
        textView.typingAttributes = typingAttributes
        textView.attributedText = NSAttributedString(string: textView.text, attributes: typingAttributes)
    }

    @objc
    private func didFontButtonClick(button: UIButton) {
        let fontConfig = UIFontPickerViewController.Configuration()
        fontConfig.includeFaces = false
        let fontPicker = UIFontPickerViewController(configuration: fontConfig)
        fontPicker.delegate = self
        viewController?.present(fontPicker, animated: true, completion: nil)
    }

    @objc
    private func didColorButtonClick(button: UIButton) {
        if #available(iOS 14.0, *) {
            let vc = UIColorPickerViewController()
            vc.delegate = self
            vc.selectedColor = customColor.color
            viewController?.present(vc, animated: true, completion: nil)
            customColor.isFirst = false
            customColor.isSelected = true
        }
    }

    private func addKeyboardNotificaition() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillAppearance),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillDismiss),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc
    private func keyboardWillAppearance(notifi: Notification) {
        guard let info = notifi.userInfo,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let keyboardFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        self.keyboardFrame = keyboardFrame
        UIView.animate(withDuration: duration) {
            self.layoutSubviews()
        }
    }
    
    @objc
    private func keyboardWillDismiss(notifi: Notification) {
        guard let info = notifi.userInfo,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
            return
        }
        keyboardFrame = .zero
        UIView.animate(withDuration: duration) {
            self.layoutSubviews()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        boldButton.frame = CGRect(
            x: 16,
            y: height,
            width: 50,
            height: 50
        )
        if keyboardFrame.isEmpty {
            if UIDevice.isPad {
                if config.modalPresentationStyle == .fullScreen {
                    boldButton.y = height - (UIDevice.bottomMargin + 50)
                }else {
                    boldButton.y = height - 50
                }
            }else {
                boldButton.y = height - (UIDevice.bottomMargin + 50)
            }
        }else {
            if UIDevice.isPad {
                let firstTextButtonY: CGFloat
                if config.modalPresentationStyle == .fullScreen {
                    firstTextButtonY = height - UIDevice.bottomMargin - 50
                }else {
                    firstTextButtonY = height - 50
                }
                let buttonRect = convert(
                    .init(x: 0, y: firstTextButtonY, width: 50, height: 50),
                    to: UIApplication._keyWindow
                )
                if buttonRect.maxY > keyboardFrame.minY {
                    boldButton.y = height - (buttonRect.maxY - keyboardFrame.minY + 50)
                }else {
                    if config.modalPresentationStyle == .fullScreen {
                        boldButton.y = height - (UIDevice.bottomMargin + 50)
                    }else {
                        boldButton.y = height - 50
                    }
                }
            }else {
                boldButton.y = height - (50 + keyboardFrame.height)
            }
        }
        italicButton.frame = boldButton.frame
        italicButton.x = boldButton.frame.maxX

        underlineButton.frame = italicButton.frame
        underlineButton.x = italicButton.frame.maxX

        strikethroughButton.frame = underlineButton.frame
        strikethroughButton.x = underlineButton.frame.maxX

        let buttonBkRect = CGRect(x: boldButton.frame.minX,
                                  y: boldButton.frame.minY + 7,
                                  width: strikethroughButton.frame.maxX - boldButton.frame.minX,
                                  height: strikethroughButton.height - 14)
        buttonBkView.frame = buttonBkRect

        fontButton.frame = strikethroughButton.frame
        fontButton.x = buttonBkRect.maxX + 12

        colorButton.frame = fontButton.frame
        colorButton.x = fontButton.frame.maxX

        customColorView.center = colorButton.center

        textView.frame = CGRect(x: 10, y: 0, width: width - 20, height: boldButton.y)
        textView.textContainerInset = UIEdgeInsets(
            top: 15,
            left: 15 + UIDevice.leftMargin,
            bottom: 15,
            right: 15 + UIDevice.rightMargin
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension EditorStickerTextView: UIFontPickerViewControllerDelegate {

    func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) {
        if let fontFamilyName = viewController.selectedFontDescriptor?.fontAttributes[.family] as? String {
            selectedFontFamilyName = fontFamilyName
        }
        viewController.dismiss(animated: true)
    }
}

class EditorStickerTextViewCell: UICollectionViewCell {
    private var colorBgView: UIView!
    private var imageView: UIImageView!
    private var colorView: UIView!
    
    var colorHex: String! {
        didSet {
            imageView.isHidden = true
            guard let colorHex = colorHex else { return }
            let color = colorHex.color
            if color.isWhite {
                colorBgView.backgroundColor = "#dadada".color
            }else {
                colorBgView.backgroundColor = .white
            }
            colorView.backgroundColor = color
        }
    }
    
    var customColor: PhotoEditorBrushCustomColor? {
        didSet {
            guard let customColor = customColor else {
                return
            }
            imageView.isHidden = false
            colorView.backgroundColor = customColor.color
        }
    }
    
    override var isSelected: Bool {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.colorBgView.transform = self.isSelected ? .init(scaleX: 1.25, y: 1.25) : .identity
                self.colorView.transform = self.isSelected ? .init(scaleX: 1.3, y: 1.3) : .identity
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView = UIImageView(image: .imageResource.editor.text.customColor.image)
        imageView.isHidden = true
        
        let bgLayer = CAShapeLayer()
        bgLayer.contentsScale = UIScreen._scale
        bgLayer.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
        bgLayer.fillColor = UIColor.black.cgColor
        let bgPath = UIBezierPath(
            roundedRect: CGRect(x: 1.5, y: 1.5, width: 19, height: 19),
            cornerRadius: 19 * 0.5
        )
        bgLayer.path = bgPath.cgPath
        imageView.layer.addSublayer(bgLayer)

        let maskLayer = CAShapeLayer()
        maskLayer.contentsScale = UIScreen._scale
        maskLayer.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
        let maskPath = UIBezierPath(rect: bgLayer.bounds)
        maskPath.append(
            UIBezierPath(
                roundedRect: CGRect(x: 3, y: 3, width: 16, height: 16),
                cornerRadius: 8
            ).reversing()
        )
        maskLayer.path = maskPath.cgPath
        imageView.layer.mask = maskLayer
        
        colorBgView = UIView()
        colorBgView.size = CGSize(width: 22, height: 22)
        colorBgView.layer.cornerRadius = 11
        colorBgView.layer.masksToBounds = true
        colorBgView.addSubview(imageView)
        contentView.addSubview(colorBgView)
        
        colorView = UIView()
        colorView.size = CGSize(width: 16, height: 16)
        colorView.layer.cornerRadius = 8
        colorView.layer.masksToBounds = true
        contentView.addSubview(colorView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        colorBgView.center = CGPoint(x: width / 2, y: height / 2)
        imageView.frame = colorBgView.bounds
        colorView.center = CGPoint(x: width / 2, y: height / 2)
    }
}

struct PhotoEditorBrushCustomColor {
    var isFirst: Bool = true
    var isSelected: Bool = false
    var color: UIColor
}
