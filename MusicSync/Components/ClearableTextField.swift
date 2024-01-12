//
//  ClearableTextField.swift
//  MusicSync
//
//  Created by Christian Langolf on 12/01/2024.
//

import Foundation
import SwiftUI

struct ClearableTextField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        HStack {
            TextField(placeholder, text: $text)
            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                }) {
                    Image(systemName: "multiply.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
