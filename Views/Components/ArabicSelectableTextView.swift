import SwiftUI
import UIKit

struct ArabicSelectableTextView: UIViewRepresentable {
    let text: String
    let fontScale: Double
    let lineSpacingScale: Double
    let onSelection: (Int) -> Void

    func makeUIView(context: Context) -> UITextView {
        let textView = IntrinsicTextView()
        textView.backgroundColor = .clear
        textView.textAlignment = .right
        textView.semanticContentAttribute = .forceRightToLeft
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.dataDetectorTypes = []
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainer.widthTracksTextView = true
        textView.delegate = context.coordinator
        textView.tintColor = UIColor(Color.kuraniAccentLight)
        textView.adjustsFontForContentSizeCategory = true
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        updateTextAttributes(for: textView)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        updateTextAttributes(for: uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private var fontPointSize: CGFloat {
        20 * fontScale
    }

    private func updateTextAttributes(for textView: UITextView) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .right
        paragraph.baseWritingDirection = .rightToLeft
        paragraph.lineSpacing = 4 * lineSpacingScale

        let attributed = NSAttributedString(
            string: text,
            attributes: [
                .paragraphStyle: paragraph,
                .font: UIFont.systemFont(ofSize: fontPointSize, weight: .regular),
                .foregroundColor: UIColor(Color.kuraniTextPrimary)
            ]
        )
        textView.attributedText = attributed
        textView.invalidateIntrinsicContentSize()
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        private let parent: ArabicSelectableTextView
        private var lastSelectionIndex: Int?

        init(_ parent: ArabicSelectableTextView) {
            self.parent = parent
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard
                let selectedTextRange = textView.selectedTextRange,
                let text = textView.text,
                !text.isEmpty
            else {
                lastSelectionIndex = nil
                return
            }

            let location = textView.offset(from: textView.beginningOfDocument, to: selectedTextRange.start)
            let length = textView.offset(from: selectedTextRange.start, to: selectedTextRange.end)
            guard length >= 0 else { return }
            let range = NSRange(location: location, length: length)

            guard let index = tokenIndex(for: range, in: text) else {
                lastSelectionIndex = nil
                return
            }

            if index == lastSelectionIndex { return }
            lastSelectionIndex = index

            DispatchQueue.main.async {
                self.parent.onSelection(index)
                textView.selectedTextRange = nil
                self.lastSelectionIndex = nil
            }
        }

        private func tokenIndex(for selectedRange: NSRange, in text: String) -> Int? {
            let nsText = text as NSString
            var currentIndex = 0
            var matchedIndex: Int?
            nsText.enumerateSubstrings(
                in: NSRange(location: 0, length: nsText.length),
                options: [.byWords, .localized]
            ) { _, wordRange, _, stop in
                if NSIntersectionRange(wordRange, selectedRange).length > 0 {
                    matchedIndex = currentIndex
                    stop.pointee = true
                }
                currentIndex += 1
            }

            if let matchedIndex { return matchedIndex }

            let prefix = nsText.substring(to: max(0, selectedRange.location))
            let delimiters = CharacterSet.whitespacesAndNewlines
            let precedingWords = prefix.unicodeScalars.split(whereSeparator: { delimiters.contains($0) }).count
            return precedingWords
        }
    }
}

private final class IntrinsicTextView: UITextView {
    private var previousBounds: CGSize = .zero

    override var intrinsicContentSize: CGSize {
        let targetWidth: CGFloat
        if bounds.width > 0 {
            targetWidth = bounds.width
        } else {
            targetWidth = UIScreen.main.bounds.width - layoutMargins.left - layoutMargins.right
        }

        let size = CGSize(width: targetWidth, height: CGFloat.greatestFiniteMagnitude)
        let fitting = sizeThatFits(size)
        return CGSize(width: UIView.noIntrinsicMetric, height: fitting.height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != previousBounds {
            previousBounds = bounds.size
            invalidateIntrinsicContentSize()
        }
    }
}
