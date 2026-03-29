//
//  ErrorView.swift
//  ScreenshotEditor
//
//  Error alert sheet
//

import SwiftUI

struct ErrorView: View {
    @Binding var message: String?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text("Error")
                .font(.headline)

            Text(message ?? "Unknown error")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("OK") {
                message = nil
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 300)
    }
}

#Preview {
    ErrorView(message: .constant("This is an error message"))
}
