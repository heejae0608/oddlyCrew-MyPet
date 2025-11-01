//
//  SemanticVersion+Compare.swift
//  OurPet
//
//  Created by 전희재 on 10/29/25.
//

import Foundation

extension String {
    /// 비교 가능한 형태로 분해된 버전 컴포넌트 (숫자가 아닌 값은 0으로 취급)
    fileprivate var semanticVersionComponents: [Int] {
        split(separator: ".")
            .map { component in
                Int(component) ?? 0
            }
    }

    /// 주어진 버전 문자열과의 세맨틱 비교 결과를 반환한다.
    func compareSemanticVersion(to other: String) -> ComparisonResult {
        let lhs = semanticVersionComponents
        let rhs = other.semanticVersionComponents
        let maxCount = max(lhs.count, rhs.count)

        for index in 0..<maxCount {
            let left = index < lhs.count ? lhs[index] : 0
            let right = index < rhs.count ? rhs[index] : 0
            if left < right { return .orderedAscending }
            if left > right { return .orderedDescending }
        }
        return .orderedSame
    }
}
