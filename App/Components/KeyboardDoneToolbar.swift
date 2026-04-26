// KeyboardDoneToolbar.swift
// Numeric / phone keypads on iPhone (.decimalPad, .numberPad, .phonePad)
// have no return key, so without a keyboard accessory the keyboard
// stays up with nothing to dismiss it. Apply `.keyboardDoneToolbar()`
// to the root of any scrolling form / inputs screen to attach a Done
// button above the keyboard that resigns first responder.
//
// Place this at ONE scope per screen — attaching it both to a parent
// and to a child TextField produces duplicate toolbars.

import SwiftUI
import UIKit

struct KeyboardDoneToolbar: ViewModifier {
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
                .accessibilityIdentifier("keyboardDone")
            }
        }
    }
}

extension View {
    /// Attach a "Done" button to the software keyboard that dismisses
    /// it. Use on any screen that hosts numeric / phone keyboards
    /// (which lack a built-in return key).
    func keyboardDoneToolbar() -> some View {
        modifier(KeyboardDoneToolbar())
    }
}
