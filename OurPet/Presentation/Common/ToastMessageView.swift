//
//  ToastMessageView.swift
//  OurPet
//
//  Created by 조성재 on 10/23/25.
//

import SwiftUI

struct ToastMessageView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(radius: 4)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: UUID())
    }
}

#Preview {
    ToastMessageView(message: "toast message test")
}
