import SwiftUI

struct PetOrderSheet: View {
    @Environment(\.dismiss) private var dismiss
    let pets: [Pet]
    let initialOrder: [UUID]
    let onComplete: ([UUID]) -> Void
    @State private var items: [PetOrderItem] = []

    var body: some View {
        NavigationStack {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppColor.surfaceBackground.opacity(0.2))

                List {
                    ForEach(items) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .appFont(17, weight: .semibold)
                                .foregroundStyle(AppColor.text)
                            Text(item.species)
                                .appFont(15)
                                .foregroundStyle(AppColor.subText)
                        }
                        .padding(.vertical, 6)
                    }
                    .onMove(perform: move)
                    .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        AnalyticsHelper.sendClickEvent(event: .clicked_home_change_ourpet_order_cancel)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        AnalyticsHelper.sendClickEvent(event: .clicked_home_change_ourpet_order_confirm)
                        
                        let newOrder = items.map(\.id)
                        onComplete(newOrder)
                        dismiss()
                    }
                    .disabled(items.isEmpty)
                }
            }
            .environment(\.editMode, .constant(.active))
        }
        .presentationDetents([.medium, .large])
        .onAppear(perform: loadItems)
    }

    private func loadItems() {
        var order = initialOrder
        let ids = pets.map(\.id)
        if order.isEmpty {
            order = ids
        } else {
            order = order.filter(ids.contains)
            for id in ids where order.contains(id) == false {
                order.append(id)
            }
        }

        items = order.compactMap { id in
            guard let pet = pets.first(where: { $0.id == id }) else { return nil }
            return PetOrderItem(id: pet.id, name: pet.name, species: pet.species)
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }
}

private struct PetOrderItem: Identifiable, Equatable {
    let id: UUID
    let name: String
    let species: String
}
