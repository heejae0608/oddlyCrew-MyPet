import Foundation

struct DailyTip {
    let title: String
    let message: String
    let icon: String
}

struct PetCareTips: Codable {
    let dog: [String]
    let cat: [String]
    let general: [String]
}

final class PetCareTipProvider {
    static let shared = PetCareTipProvider()

    private enum PetKind {
        case dog
        case cat
    }

    private let tips: PetCareTips

    private init() {
        if let url = Bundle.main.url(forResource: "pet_care_tips", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(PetCareTips.self, from: data) {
            self.tips = decoded
        } else {
            self.tips = PetCareTips(dog: [], cat: [], general: [])
        }
    }

    func randomTip(for pets: [Pet]) -> DailyTip? {
        var candidates: [(icon: String, title: String, message: String)] = []

        let kinds = Set(pets.compactMap(classify))

        if kinds.contains(.dog) {
            candidates += tips.dog.map { ("pawprint.fill", "오늘의 강아지 팁", $0) }
        }

        if kinds.contains(.cat) {
            candidates += tips.cat.map { ("cat.fill", "오늘의 고양이 팁", $0) }
        }

        if candidates.isEmpty {
            candidates = tips.general.map { ("heart.text.square.fill", "반려동물과 함께하기", $0) }
        }

        guard let picked = candidates.randomElement() else {
            return nil
        }

        return DailyTip(title: picked.title, message: picked.message, icon: picked.icon)
    }

    private func classify(_ pet: Pet) -> PetKind? {
        let normalized = pet.species.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        switch normalized {
        case "강아지", "개", "견", "dog", "dogs", "puppy", "puppies":
            return .dog
        case "고양이", "cat", "cats", "kitten", "kittens":
            return .cat
        default:
            return nil
        }
    }
}
