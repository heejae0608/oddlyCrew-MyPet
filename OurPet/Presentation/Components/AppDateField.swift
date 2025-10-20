import SwiftUI

struct AppDateField: View {
    let placeholder: String
    @Binding var date: Date
    var focusedField: FocusState<PetFormField?>.Binding
    let field: PetFormField
    var minimumDate: Date? = nil
    var maximumDate: Date? = Date()
    var fontWeight: Font.Weight = .regular

    @State private var isPresentingPicker = false

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()

    var body: some View {
        Button {
            focusedField.wrappedValue = field
            isPresentingPicker = true
        } label: {
            HStack {
                Text(Self.formatter.string(from: date))
                    .appFont(16, weight: fontWeight)
                    .foregroundStyle(AppColor.text)

                Spacer()

                Image(systemName: "calendar")
                    .appFont(16, weight: .medium)
                    .foregroundStyle(AppColor.orange)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppColor.inputSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppColor.inputBorder)
            )
        }
        .buttonStyle(.plain)
        .id(field)
        .sheet(isPresented: $isPresentingPicker) {
            NavigationStack {
                VStack(spacing: 20) {
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { date.clamped(between: minimumDate, and: maximumDate) },
                            set: { newValue in
                                date = newValue.clamped(between: minimumDate, and: maximumDate)
                            }
                        ),
                        in: dateRange,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .tint(AppColor.orange)

                    Text(Self.formatter.string(from: date))
                        .appFont(18, weight: .semibold)
                        .foregroundStyle(AppColor.text)
                }
                .padding()
                .background(AppColor.formBackground.ignoresSafeArea())
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("취소") {
                            focusedField.wrappedValue = nil
                            isPresentingPicker = false
                        }
                        .foregroundStyle(AppColor.subText)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("완료") {
                            focusedField.wrappedValue = field
                            isPresentingPicker = false
                        }
                        .foregroundStyle(AppColor.orange)
                    }
                }
                .navigationTitle(placeholder)
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var dateRange: ClosedRange<Date> {
        let min = minimumDate ?? Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date(timeIntervalSince1970: 0)
        let max = maximumDate ?? Date()
        return min...max
    }
}

private extension Date {
    func clamped(between minimum: Date?, and maximum: Date?) -> Date {
        if let minimum, self < minimum {
            return minimum
        }
        if let maximum, self > maximum {
            return maximum
        }
        return self
    }
}
