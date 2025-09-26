import SwiftUI
import UIKit

struct ArabicSelectableTextView: UIViewRepresentable {
    let text: String
    let fontScale: Double
    let lineSpacingScale: Double
    let onSelection: (String) -> Void

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.textAlignment = .right
        textView.semanticContentAttribute = .forceRightToLeft
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.dataDetectorTypes = []
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = context.coordinator
        textView.tintColor = UIColor(Color.kuraniAccentLight)
        textView.adjustsFontForContentSizeCategory = true
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
        textView.setNeedsLayout()
        textView.layoutIfNeeded()
        textView.invalidateIntrinsicContentSize()
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        private let parent: ArabicSelectableTextView
        private var lastSelection: String?

        init(_ parent: ArabicSelectableTextView) {
            self.parent = parent
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard let selectedRange = textView.selectedTextRange else { return }
            let selectedText = textView.text(in: selectedRange) ?? ""
            let trimmed = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                lastSelection = nil
                return
            }

            // Avoid repeated callbacks for same selection
            if trimmed == lastSelection { return }
            lastSelection = trimmed
            DispatchQueue.main.async {
                self.parent.onSelection(trimmed)
                textView.selectedTextRange = nil
                self.lastSelection = nil
            }
        }
    }
}
