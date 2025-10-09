import SwiftUI

struct PetOverviewSection: View {
    let pet: Pet
    let onEdit: (Pet) -> Void

    var body: some View {
        PetDetailCard(pet: pet, onEdit: { onEdit(pet) })
    }
}

struct PetDetailCard: View {
    let pet: Pet
    let onEdit: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppColor.cardGradientStart, AppColor.cardGradientEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(AppColor.cardBorder.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 12)

            VStack(alignment: .leading, spacing: 24) {
                headerSection
                detailPanel
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 20) {
            PetProfileImageView(pet: pet)
                .frame(width: 140, height: 140)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Text(pet.name)
                        .appFont(26, weight: .bold)
                        .foregroundColor(.white)

                    Button(action: onEdit) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.18))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(pet.name) 정보 수정")
                }

                Text(speciesLabel)
                    .appFont(15, weight: .medium)
                    .foregroundColor(Color.white.opacity(0.85))

                headerInfoRows
            }

            Spacer(minLength: 0)
        }
    }

    private var headerInfoRows: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let ageHeader = ageHeaderText {
                headerInfoRow(icon: "clock", text: ageHeader)
            }

            if let birth = birthText {
                headerInfoRow(icon: "gift.fill", text: "생일 \(birth)")
            }

            if let adoption = adoptionText {
                headerInfoRow(icon: "calendar", text: "함께한 지 \(adoption)")
            }
        }
    }

    private func headerInfoRow(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Color.white.opacity(0.75))
            Text(text)
                .appFont(13, weight: .semibold)
                .foregroundColor(Color.white.opacity(0.75))
        }
    }

    private var detailPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 16) {
                ForEach(infoItems) { item in
                    gridInfo(item: item)
                }
            }

            if let note = pet.existingConditions, note.isEmpty == false {
                VStack(alignment: .leading, spacing: 6) {
                    Text("특이사항")
                        .appFont(12, weight: .semibold)
                        .foregroundColor(AppColor.cardDetailLabel)
                    Text(note)
                        .appFont(15, weight: .medium)
                        .foregroundColor(AppColor.cardDetailValue)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColor.cardDetailBackground)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 6)
    }

    private var gridColumns: [GridItem] {
        [GridItem(.flexible(), alignment: .topLeading), GridItem(.flexible(), alignment: .topLeading)]
    }

    private struct InfoItem: Identifiable {
        let id = UUID()
        let label: String
        let value: String
    }

    private var infoItems: [InfoItem] {
        var items: [InfoItem] = []
        items.append(.init(label: "성별", value: pet.gender))
        items.append(.init(label: "중성화", value: pet.isNeutered ? "완료" : "미완료"))
        if let weight = weightText {
            items.append(.init(label: "몸무게", value: weight))
        }
        items.append(.init(label: "등록일", value: registrationText))
        if let adoptionDDay = adoptionDDayChip {
            items.append(.init(label: "가족이 된 날 D-Day", value: adoptionDDay))
        }
        if let birthDDay = birthDDayChip {
            items.append(.init(label: "생일 D-Day", value: birthDDay))
        }
        return items
    }

    private func gridInfo(item: InfoItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.label)
                .appFont(12, weight: .semibold)
                .foregroundColor(AppColor.cardDetailLabel)
            Text(item.value)
                .appFont(15, weight: .medium)
                .foregroundColor(AppColor.cardDetailValue)
                .multilineTextAlignment(.leading)
        }
    }

    private var ageHeaderText: String? {
        let years = pet.calculatedAge
        if years > 0 {
            return "나이 \(years)살"
        }
        return nil
    }

    private var ageText: String {
        let years = pet.calculatedAge
        return years > 0 ? "\(years)살" : "정보 없음"
    }

    private var weightText: String? {
        guard let weight = pet.weight else { return nil }
        return String(format: "%.1f", weight) + "kg"
    }

    private var birthText: String? {
        pet.birthDate.map { PetDetailCard.dateFormatter.string(from: $0) }
    }

    private var adoptionText: String? {
        guard let adoptionDate = pet.adoptionDate else { return nil }
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: adoptionDate)
        let endDate = calendar.startOfDay(for: Date())
        guard startDate <= endDate else { return nil }

        let components = calendar.dateComponents([.year, .month], from: startDate, to: endDate)
        var parts: [String] = []

        if let years = components.year, years > 0 {
            parts.append("\(years)년")
        }

        if let months = components.month, months > 0 {
            parts.append("\(months)개월")
        }

        if parts.isEmpty {
            let dayComponents = calendar.dateComponents([.day], from: startDate, to: endDate)
            let days = dayComponents.day ?? 0
            return days > 0 ? "\(days)일" : "0일"
        }

        return parts.joined(separator: " ")
    }

    private var registrationText: String {
        PetDetailCard.dateFormatter.string(from: pet.registrationDate)
    }

    private var adoptionDDayChip: String? {
        guard let adoptionDate = pet.adoptionDate else { return nil }
        return Self.ddayChipText(for: adoptionDate)
    }

    private var birthDDayChip: String? {
        guard let birthDate = pet.birthDate else { return nil }
        return Self.ddayChipText(for: birthDate)
    }

    private var speciesLabel: String {
        if let breed = pet.breed, breed.isEmpty == false {
            return "\(pet.species) • \(breed)"
        }
        return pet.species
    }

    fileprivate static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()

    private static func ddayChipText(for date: Date) -> String? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var components = calendar.dateComponents([.month, .day], from: date)
        components.year = calendar.component(.year, from: today)

        guard var nextOccurrence = calendar.date(from: components) else { return nil }

        if nextOccurrence < today {
            nextOccurrence = calendar.date(byAdding: .year, value: 1, to: nextOccurrence) ?? nextOccurrence
        }

        let remaining = calendar.dateComponents([.day], from: today, to: nextOccurrence).day ?? 0

        if remaining == 0 {
            return "오늘"
        }
        return "D-\(remaining)"
    }
}

struct PetProfileImageView: View {
    let pet: Pet

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppColor.white.opacity(0.45), AppColor.peach.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            profileImage
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(radius: 6, x: 0, y: 4)
                .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    @ViewBuilder
    private var profileImage: some View {
        if let image = decodedProfileImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Image(systemName: "pawprint.circle")
            .resizable()
            .scaledToFit()
            .foregroundColor(AppColor.orange.opacity(0.35))
            .padding(18)
            .background(AppColor.white.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var decodedProfileImage: UIImage? {
        guard let data = pet.decodedProfileImageData else { return nil }
        return UIImage(data: data)
    }
}
