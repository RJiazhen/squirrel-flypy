//
//  QuickAddWordPanel.swift
//  Squirrel
//
//  Created by Codex on 4/23/26.
//

import AppKit

import SwiftUI


/// Receives events from the quick add word panel.
protocol QuickAddWordPanelDelegate: AnyObject {
  /// Handles a confirmed quick-add request with validated UI values and option states.
  func quickAddWordPanel(_ panel: QuickAddWordPanel, didConfirmWord word: String, code: String, shouldPinEntry: Bool, shouldBuildFromClipboard: Bool)
  /// Handles panel dismissal through cancel actions.
  func quickAddWordPanelDidCancel(_ panel: QuickAddWordPanel)
}

/// Provides a small floating panel for quickly collecting phrase and code values.
final class QuickAddWordPanel: NSObject, NSWindowDelegate {
  private static let panelWidth: CGFloat = 460
  private let panel: NSWindow
  private let wordField: NSTextField
  private let codeField: NSTextField
  private let pinEntryCheckbox: NSButton
  private let buildFromClipboardCheckbox: NSButton
  weak var delegate: QuickAddWordPanelDelegate?

  /// Creates the quick add word panel and all form controls.
  override init() {
    panel = NSWindow(contentRect: NSRect(x: 0, y: 0, width: Self.panelWidth, height: 220), styleMask: [.titled, .closable], backing: .buffered, defer: false)
    wordField = NSTextField(frame: .zero)
    codeField = NSTextField(frame: .zero)
    pinEntryCheckbox = NSButton(checkboxWithTitle: "将新添加词条固项", target: nil, action: nil)
    buildFromClipboardCheckbox = NSButton(checkboxWithTitle: "剪贴板造词", target: nil, action: nil)
    super.init()
    setupPanel()
  }

  /// Displays the panel and optionally pre-fills form fields.
  func show(prefillWord: String?, prefillCode: String?) {
    wordField.stringValue = prefillWord ?? ""
    codeField.stringValue = prefillCode ?? ""
    pinEntryCheckbox.state = .off
    buildFromClipboardCheckbox.state = .off
    panel.center()
    NSApp.activate(ignoringOtherApps: true)
    panel.makeKeyAndOrderFront(nil)
    if wordField.stringValue.isEmpty {
      panel.makeFirstResponder(wordField)
    } else {
      panel.makeFirstResponder(codeField)
    }
  }

  /// Hides the panel if it is currently visible.
  func hide() {
    panel.orderOut(nil)
  }

  /// Returns a detached preview view so Xcode canvas can render the panel layout.
  func previewContentView() -> NSView {
    wordField.stringValue = "示例词条"
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
    delegate?.quickAddWordPanelDidCancel(self)
  }
}

private extension QuickAddWordPanel {
  /// Builds panel controls and binds buttons to selector actions.
  func setupPanel() {
    let topInset: CGFloat = 14
    let bottomInset: CGFloat = 14
    let rowSpacing: CGFloat = 10
    let controlHeight: CGFloat = 24
    let checkboxHeight: CGFloat = 22
    let buttonHeight: CGFloat = 32
    let panelContentHeight = quickAddPanelContentHeight(topInset: topInset,
                                                        bottomInset: bottomInset,
                                                        rowSpacing: rowSpacing,
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
    let wordRowY = contentHeight - topInset - controlHeight
    wordLabel.frame = NSRect(x: 24, y: wordRowY + 2, width: 60, height: 22)
    contentView.addSubview(wordLabel)

    wordField.frame = NSRect(x: 88, y: wordRowY, width: 340, height: controlHeight)
    wordField.placeholderString = "请输入词条"
    contentView.addSubview(wordField)

    let codeLabel = NSTextField(labelWithString: "编码")
    let codeRowY = wordRowY - rowSpacing - controlHeight
    codeLabel.frame = NSRect(x: 24, y: codeRowY + 2, width: 60, height: 22)
    contentView.addSubview(codeLabel)

    codeField.frame = NSRect(x: 88, y: codeRowY, width: 340, height: controlHeight)
    codeField.placeholderString = "请输入编码"
    contentView.addSubview(codeField)

    let checkboxRowY = codeRowY - rowSpacing - 22
    pinEntryCheckbox.frame = NSRect(x: 88, y: checkboxRowY, width: 180, height: 22)
    contentView.addSubview(pinEntryCheckbox)

    buildFromClipboardCheckbox.frame = NSRect(x: 276, y: checkboxRowY, width: 152, height: 22)
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
  }

  /// Calculates the minimum content height from configured paddings and row metrics.
  func quickAddPanelContentHeight(topInset: CGFloat = 14,
                                  bottomInset: CGFloat = 14,
                                  rowSpacing: CGFloat = 10,
                                  controlHeight: CGFloat = 24,
                                  checkboxHeight: CGFloat = 22,
                                  buttonHeight: CGFloat = 32) -> CGFloat {
    topInset + controlHeight + rowSpacing + controlHeight + rowSpacing + checkboxHeight + rowSpacing + buttonHeight + bottomInset
  }

  /// Emits a confirm event with trimmed form values.
  @objc func confirm() {
    let word = wordField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
    let code = codeField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
    delegate?.quickAddWordPanel(self,
                                didConfirmWord: word,
                                code: code,
                                shouldPinEntry: pinEntryCheckbox.state == .on,
                                shouldBuildFromClipboard: buildFromClipboardCheckbox.state == .on)
  }

  /// Emits a cancel event and hides the panel.
  @objc func cancel() {
    panel.close()
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
    .frame(width: 460, height: 170)
}

