//
//  QuickAddWordPanel.swift
//  Squirrel
//
//  Created by Codex on 4/23/26.
//  Hosts the quick-add floating panel UI, field behaviors, and keyboard shortcuts.
//

import AppKit

import SwiftUI


/// Sends copy, paste, cut, select-all, undo, and redo to the first responder when the host is a menuless accessory app.
private func quickAddPanelDispatchStandardEditCommand(_ event: NSEvent, sender: Any?) -> Bool {
  guard event.modifierFlags.contains(.command) else { return false }
  let ch = event.charactersIgnoringModifiers?.lowercased() ?? ""
  if ch == "z" {
    if event.modifierFlags.contains(.shift) {
      return NSApp.sendAction(Selector(("redo:")), to: nil, from: sender)
    }
    return NSApp.sendAction(Selector(("undo:")), to: nil, from: sender)
  }
  guard ch.count == 1, let c = ch.first else { return false }
  switch c {
  case "a":
    return NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: sender)
  case "c":
    return NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: sender)
  case "v":
    return NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: sender)
  case "x":
    return NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: sender)
  default:
    return false
  }
}


/// Key window for the quick-add panel so standard edit shortcuts work without a main menu bar.
private final class QuickAddWordKeyWindow: NSWindow {
  /// Tries AppKit default handling first, then dispatches copy/paste/select-all/undo to the first responder.
  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    if super.performKeyEquivalent(with: event) {
      return true
    }
    return quickAddPanelDispatchStandardEditCommand(event, sender: self)
  }
}


/// Multiline word field that draws a placeholder when empty and refreshes it after edits.
private final class QuickAddWordPlaceholderTextView: NSTextView {
  /// Hint drawn when the document contains no text.
  var placeholderString: String = ""

  /// Keeps placeholder visibility in sync with programmatic `string` updates.
  override var string: String {
    get {
      super.string
    }
    set {
      super.string = newValue
      needsDisplay = true
    }
  }

  /// Redraws after user edits so the placeholder toggles correctly.
  override func didChangeText() {
    super.didChangeText()
    needsDisplay = true
  }

  /// Handles Cmd shortcuts when the host app does not provide an Edit menu.
  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    if super.performKeyEquivalent(with: event) {
      return true
    }
    return quickAddPanelDispatchStandardEditCommand(event, sender: self)
  }

  /// Draws placeholder text behind the caret when there is no content.
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    guard string.isEmpty, !placeholderString.isEmpty else { return }
    let bodyFont = font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
    let attrs: [NSAttributedString.Key: Any] = [
      .foregroundColor: NSColor.placeholderTextColor,
      .font: bodyFont
    ]
    let attributed = NSAttributedString(string: placeholderString, attributes: attrs)
    let pad = textContainerInset
    let linePad = textContainer?.lineFragmentPadding ?? 0
    let textRect = NSRect(
      x: dirtyRect.minX + pad.width + linePad,
      y: dirtyRect.minY + pad.height,
      width: max(0, dirtyRect.width - 2 * (pad.width + linePad)),
      height: max(0, dirtyRect.height - 2 * pad.height)
    )
    attributed.draw(with: textRect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
  }
}


/// Receives events from the quick add word panel.
protocol QuickAddWordPanelDelegate: AnyObject {
  /// Handles a confirmed quick-add request with validated UI values and option states.
  func quickAddWordPanel(_ panel: QuickAddWordPanel, didConfirmWord word: String, code: String, shouldPinEntry: Bool)
  /// Handles panel dismissal through cancel actions.
  func quickAddWordPanelDidCancel(_ panel: QuickAddWordPanel)
}

/// Provides a small floating panel for quickly collecting phrase and code values.
final class QuickAddWordPanel: NSObject, NSWindowDelegate, NSTextViewDelegate, NSControlTextEditingDelegate, NSTextFieldDelegate {
  private static let panelWidth: CGFloat = 460
  /// Minimum number of visible lines for the word text view.
  private static let wordTextMinLineCount: CGFloat = 10
  /// Snapshot of the word field before turning on clipboard-build, restored when the option is turned off.
  private var wordSnapshotBeforeClipboard: String?
  private let panel: NSWindow
  private let wordScrollView: NSScrollView
  private let wordTextView: QuickAddWordPlaceholderTextView
  private let codeField: NSTextField
  private let pinEntryCheckbox: NSButton
  private let buildFromClipboardCheckbox: NSButton
  private var tailLengthKeyMonitor: Any?
  /// Code value last applied automatically from flypydz when the trimmed word stays a single character.
  private var flypydzAutoSuggestedCode: String?
  weak var delegate: QuickAddWordPanelDelegate?

  /// Creates the quick add word panel and all form controls.
  override init() {
    panel = QuickAddWordKeyWindow(contentRect: NSRect(x: 0, y: 0, width: Self.panelWidth, height: 220), styleMask: [.titled, .closable], backing: .buffered, defer: false)
    wordScrollView = NSScrollView(frame: .zero)
    wordTextView = QuickAddWordPlaceholderTextView(frame: .zero)
    codeField = NSTextField(frame: .zero)
    pinEntryCheckbox = NSButton(checkboxWithTitle: "将新添加词条固项", target: nil, action: nil)
    buildFromClipboardCheckbox = NSButton(checkboxWithTitle: "剪贴板造词", target: nil, action: nil)
    super.init()
    setupPanel()
  }

  /// Stops arrow-key monitoring and unregisters notification observers owned by this panel.
  deinit {
    removeTailLengthKeyMonitorIfNeeded()
    NotificationCenter.default.removeObserver(self)
  }

  /// Displays the panel and optionally pre-fills form fields.
  func show(prefillWord: String?, prefillCode: String?) {
    removeTailLengthKeyMonitorIfNeeded()
    wordSnapshotBeforeClipboard = nil
    wordTextView.string = prefillWord ?? ""
    codeField.stringValue = prefillCode ?? ""
    flypydzAutoSuggestedCode = nil
    syncFlypydzCodeFieldWithWordContent()
    pinEntryCheckbox.state = .off
    buildFromClipboardCheckbox.state = .off
    panel.center()
    NSApp.activate(ignoringOtherApps: true)
    panel.makeKeyAndOrderFront(nil)
    installTailLengthKeyMonitorIfNeeded()
    if wordTextView.string.isEmpty {
      panel.makeFirstResponder(wordTextView)
    } else {
      panel.makeFirstResponder(codeField)
    }
  }

  /// Hides the panel if it is currently visible.
  func hide() {
    removeTailLengthKeyMonitorIfNeeded()
    panel.orderOut(nil)
  }

  /// Returns a detached preview view so Xcode canvas can render the panel layout.
  func previewContentView() -> NSView {
    wordTextView.string = "示例词条"
    codeField.stringValue = "abcd"
    pinEntryCheckbox.state = .off
    buildFromClipboardCheckbox.state = .off
    guard let contentView = panel.contentView else {
      return NSView(frame: NSRect(x: 0, y: 0, width: Self.panelWidth, height: quickAddPanelContentHeight()))
    }
    return contentView
  }

  /// Forwards close-window behavior to the cancel delegate callback.
  func windowWillClose(_ notification: Notification) {
    removeTailLengthKeyMonitorIfNeeded()
    delegate?.quickAddWordPanelDidCancel(self)
  }

  /// Refreshes placeholder rendering after edits and reapplies flypydz-backed code hints when appropriate.
  func textDidChange(_ notification: Notification) {
    guard (notification.object as AnyObject?) === wordTextView else { return }
    wordTextView.needsDisplay = true
    syncFlypydzCodeFieldWithWordContent()
  }

  /// Intercepts up/down command selectors from the word text view to resize the recent-tail phrase instead of moving the caret.
  func textView(_: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
    handleTailLengthArrowCommand(commandSelector)
  }

  /// Clears auto-code tracking when the user overrides the flypydz suggestion, and refills when the field is emptied.
  @objc func quickAddCodeControlTextDidChange(_ notification: Notification) {
    guard (notification.object as AnyObject?) === codeField else { return }
    if let auto = flypydzAutoSuggestedCode, codeField.stringValue != auto {
      flypydzAutoSuggestedCode = nil
    }
    if codeField.stringValue.isEmpty {
      syncFlypydzCodeFieldWithWordContent()
    }
  }

  /// Intercepts up/down command selectors from the code field editor to resize the recent-tail phrase.
  func control(_ control: NSControl, textView _: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
    guard control === codeField else { return false }
    return handleTailLengthArrowCommand(commandSelector)
  }
}

private extension QuickAddWordPanel {
  /// Computes the word text area height from the system font line height and `wordTextMinLineCount`.
  static func wordTextAreaMinHeight() -> CGFloat {
    let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
    let lineHeight = NSLayoutManager().defaultLineHeight(for: font)
    let inset = wordTextViewVerticalInsetTotal
    return ceil(lineHeight * Self.wordTextMinLineCount) + inset
  }

  /// Total vertical padding matching the word `NSTextView` text container inset (top + bottom).
  static var wordTextViewVerticalInsetTotal: CGFloat { 8 }

  /// Builds panel controls and binds buttons to selector actions.
  func setupPanel() {
    let topInset: CGFloat = 14
    let bottomInset: CGFloat = 14
    let rowSpacing: CGFloat = 10
    let controlHeight: CGFloat = 24
    let wordAreaHeight = Self.wordTextAreaMinHeight()
    let checkboxHeight: CGFloat = 22
    let buttonHeight: CGFloat = 32
    let panelContentHeight = quickAddPanelContentHeight(topInset: topInset,
                                                        bottomInset: bottomInset,
                                                        rowSpacing: rowSpacing,
                                                        wordAreaHeight: wordAreaHeight,
                                                        controlHeight: controlHeight,
                                                        checkboxHeight: checkboxHeight,
                                                        buttonHeight: buttonHeight)

    panel.isReleasedWhenClosed = false
    panel.title = "快速加词"
    panel.delegate = self
    panel.hidesOnDeactivate = false
    panel.level = .normal
    panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    panel.setContentSize(NSSize(width: Self.panelWidth, height: panelContentHeight))

    let contentView = NSView(frame: NSRect(x: 0, y: 0, width: Self.panelWidth, height: panelContentHeight))
    panel.contentView = contentView
    let contentHeight = panelContentHeight

    let wordLabel = NSTextField(labelWithString: "词条")
    let wordAreaBottomY = contentHeight - topInset - wordAreaHeight
    wordLabel.frame = NSRect(x: 24, y: wordAreaBottomY + wordAreaHeight - 22, width: 60, height: 22)
    contentView.addSubview(wordLabel)

    wordScrollView.frame = NSRect(x: 88, y: wordAreaBottomY, width: 340, height: wordAreaHeight)
    wordScrollView.hasVerticalScroller = true
    wordScrollView.hasHorizontalScroller = false
    wordScrollView.autohidesScrollers = true
    wordScrollView.borderType = .bezelBorder
    wordScrollView.drawsBackground = true
    let wordDocWidth: CGFloat = 326
    wordTextView.minSize = NSSize(width: wordDocWidth, height: wordAreaHeight)
    wordTextView.maxSize = NSSize(width: wordDocWidth, height: CGFloat.greatestFiniteMagnitude)
    wordTextView.isVerticallyResizable = true
    wordTextView.isHorizontallyResizable = false
    wordTextView.autoresizingMask = [.width]
    wordTextView.textContainer?.widthTracksTextView = true
    wordTextView.textContainer?.containerSize = NSSize(width: wordDocWidth, height: CGFloat.greatestFiniteMagnitude)
    wordTextView.textContainer?.heightTracksTextView = false
    wordTextView.frame = NSRect(x: 0, y: 0, width: wordDocWidth, height: wordAreaHeight)
    wordTextView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
    wordTextView.isRichText = false
    wordTextView.importsGraphics = false
    wordTextView.usesFontPanel = false
    wordTextView.drawsBackground = true
    wordTextView.isEditable = true
    wordTextView.isSelectable = true
    wordTextView.textContainerInset = NSSize(width: 4, height: 4)
    wordTextView.allowsUndo = true
    wordTextView.placeholderString = "请输入词条"
    wordTextView.delegate = self
    wordTextView.registerForDraggedTypes([.string, .URL, .fileURL])
    wordScrollView.documentView = wordTextView
    contentView.addSubview(wordScrollView)

    let codeLabel = NSTextField(labelWithString: "编码")
    let codeRowY = wordAreaBottomY - rowSpacing - controlHeight
    codeLabel.frame = NSRect(x: 24, y: codeRowY + 2, width: 60, height: 22)
    contentView.addSubview(codeLabel)

    codeField.frame = NSRect(x: 88, y: codeRowY, width: 340, height: controlHeight)
    codeField.placeholderString = "请输入编码"
    codeField.delegate = self
    contentView.addSubview(codeField)

    wordTextView.nextKeyView = codeField
    codeField.nextKeyView = wordTextView

    let checkboxRowY = codeRowY - rowSpacing - 22
    pinEntryCheckbox.frame = NSRect(x: 88, y: checkboxRowY, width: 180, height: 22)
    contentView.addSubview(pinEntryCheckbox)

    buildFromClipboardCheckbox.frame = NSRect(x: 276, y: checkboxRowY, width: 152, height: 22)
    buildFromClipboardCheckbox.target = self
    buildFromClipboardCheckbox.action = #selector(clipboardCheckboxChanged)
    contentView.addSubview(buildFromClipboardCheckbox)

    let buttonRowY = checkboxRowY - rowSpacing - buttonHeight
    let cancelButton = NSButton(frame: NSRect(x: 344, y: buttonRowY, width: 84, height: buttonHeight))
    cancelButton.title = "取消"
    cancelButton.keyEquivalent = "\u{1b}"
    cancelButton.bezelStyle = .rounded
    cancelButton.target = self
    cancelButton.action = #selector(cancel)
    contentView.addSubview(cancelButton)

    let confirmButton = NSButton(frame: NSRect(x: 248, y: buttonRowY, width: 84, height: buttonHeight))
    confirmButton.title = "确定"
    confirmButton.keyEquivalent = "\r"
    confirmButton.bezelStyle = .rounded
    confirmButton.target = self
    confirmButton.action = #selector(confirm)
    contentView.addSubview(confirmButton)

    NotificationCenter.default.addObserver(self, selector: #selector(quickAddCodeControlTextDidChange(_:)), name: NSControl.textDidChangeNotification, object: codeField)
  }

  /// Calculates the minimum content height from configured paddings and row metrics.
  func quickAddPanelContentHeight(topInset: CGFloat = 14,
                                  bottomInset: CGFloat = 14,
                                  rowSpacing: CGFloat = 10,
                                  wordAreaHeight: CGFloat = QuickAddWordPanel.wordTextAreaMinHeight(),
                                  controlHeight: CGFloat = 24,
                                  checkboxHeight: CGFloat = 22,
                                  buttonHeight: CGFloat = 32) -> CGFloat {
    topInset + wordAreaHeight + rowSpacing + controlHeight + rowSpacing + checkboxHeight + rowSpacing + buttonHeight + bottomInset
  }

  /// Emits a confirm event with the word field unchanged and a trimmed code value.
  @objc func confirm() {
    let word = wordTextView.string
    let code = codeField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
    delegate?.quickAddWordPanel(self,
                                didConfirmWord: word,
                                code: code,
                                shouldPinEntry: pinEntryCheckbox.state == .on)
  }

  /// Saves or restores the word field when clipboard-build is toggled, and pastes on enable when possible.
  @objc func clipboardCheckboxChanged(_ sender: NSButton) {
    if sender.state == .off {
      if let snapshot = wordSnapshotBeforeClipboard {
        wordTextView.string = snapshot
      }
      wordSnapshotBeforeClipboard = nil
      syncFlypydzCodeFieldWithWordContent()
      return
    }
    guard sender.state == .on else { return }
    wordSnapshotBeforeClipboard = wordTextView.string
    let text = NSPasteboard.general.string(forType: .string) ?? ""
    if text.isEmpty {
      sender.state = .off
      wordTextView.string = ""
      codeField.stringValue = ""
      flypydzAutoSuggestedCode = nil
      wordSnapshotBeforeClipboard = nil
      return
    }
    wordTextView.string = text
    syncFlypydzCodeFieldWithWordContent()
    panel.makeFirstResponder(codeField)
  }

  /// Emits a cancel event and hides the panel.
  @objc func cancel() {
    panel.close()
  }

  /// Updates the code field from flypydz rules when the phrase is auto-manageable and the code is still auto-managed.
  func syncFlypydzCodeFieldWithWordContent() {
    let trimmed = wordTextView.string.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      if codeField.stringValue == flypydzAutoSuggestedCode {
        codeField.stringValue = ""
      }
      flypydzAutoSuggestedCode = nil
      return
    }
    guard let suggested = NSApp.squirrelAppDelegate.quickAddAutoCode(forWord: trimmed), !suggested.isEmpty else {
      if codeField.stringValue == flypydzAutoSuggestedCode {
        codeField.stringValue = ""
      }
      flypydzAutoSuggestedCode = nil
      return
    }
    let current = codeField.stringValue
    if current.isEmpty || current == flypydzAutoSuggestedCode {
      codeField.stringValue = suggested
      flypydzAutoSuggestedCode = suggested
    } else if current == suggested {
      flypydzAutoSuggestedCode = suggested
    }
  }

  /// Replaces the word field with a new tail slice from the delegate and refreshes flypydz code hints.
  func applyTailPhraseFromDelegate(_ phrase: String) {
    wordTextView.string = phrase
    wordTextView.needsDisplay = true
    syncFlypydzCodeFieldWithWordContent()
  }

  /// Handles up/down selector commands by adjusting quick-add tail length and clearing focus from the current editor.
  func handleTailLengthArrowCommand(_ commandSelector: Selector) -> Bool {
    guard buildFromClipboardCheckbox.state == .off else { return false }
    let delta: Int
    if commandSelector == #selector(NSResponder.moveUp(_:)) {
      delta = 1
    } else if commandSelector == #selector(NSResponder.moveDown(_:)) {
      delta = -1
    } else {
      return false
    }
    guard let phrase = NSApp.squirrelAppDelegate.quickAddAdjustTailSliceAndReturnPhrase(delta: delta) else {
      return false
    }
    panel.makeFirstResponder(nil)
    applyTailPhraseFromDelegate(phrase)
    return true
  }

  /// Observes key-down events so arrow keys can resize the recent-commit tail from anywhere inside the panel.
  func installTailLengthKeyMonitorIfNeeded() {
    guard tailLengthKeyMonitor == nil else { return }
    tailLengthKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
      guard let self else { return event }
      guard event.window === self.panel else { return event }
      guard self.buildFromClipboardCheckbox.state == .off else { return event }
      let delta: Int?
      if event.specialKey == .upArrow || event.keyCode == 126 {
        delta = 1
      } else if event.specialKey == .downArrow || event.keyCode == 125 {
        delta = -1
      } else {
        delta = nil
      }
      guard let delta else { return event }
      guard let phrase = NSApp.squirrelAppDelegate.quickAddAdjustTailSliceAndReturnPhrase(delta: delta) else {
        return event
      }
      self.panel.makeFirstResponder(nil)
      self.applyTailPhraseFromDelegate(phrase)
      return nil
    }
  }

  /// Removes the local tail-length key monitor if it was installed.
  func removeTailLengthKeyMonitorIfNeeded() {
    if let monitor = tailLengthKeyMonitor {
      NSEvent.removeMonitor(monitor)
      tailLengthKeyMonitor = nil
    }
  }
}


/// Bridges AppKit panel content into SwiftUI previews.
private struct QuickAddWordPanelPreviewView: NSViewRepresentable {
  /// Creates the AppKit view used by the SwiftUI preview canvas.
  func makeNSView(context _: Context) -> NSView {
    let panel = QuickAddWordPanel()
    return panel.previewContentView()
  }

  /// Keeps preview content in sync when the canvas refreshes.
  func updateNSView(_ nsView: NSView, context _: Context) {
    _ = nsView
  }
}


#Preview("Quick Add Word Panel") {
  QuickAddWordPanelPreviewView()
    .frame(width: 460, height: 380)
}

