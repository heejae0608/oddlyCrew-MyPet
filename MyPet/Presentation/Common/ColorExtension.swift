//
//  ColorExtension.swift
//  MyPet
//
//  Created by hjp on 9/28/25.
//

import SwiftUI
import UIKit

extension UIColor {
    convenience init(hex: UInt, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: alpha
        )
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(UIColor(hex: hex, alpha: alpha))
    }
}

enum AppColor {
    //ex) 메인 색
    static let orange = Color(hex: 0xFA7E1F)
    //ex) 글자 색이나 아이콘의 색
    static let ink    = Color(hex: 0x1B1715)
    static let peach  = Color(hex: 0xFFC192)
    static let white  = Color(hex: 0xFFFFFF)
    //ex) 버튼의 배경 약한 회색
    static let lightGray  = Color(hex: 0xEDEDED)
}


