//
//  HistoryView.swift
//  OurPet
//
//  Created by 전희재 on 9/18/25.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @EnvironmentObject private var session: SessionViewModel
    @State private var showingPetSelection = false
    @State private var showingHistoryDetailView = false
    @State private var selectedConversation: ChatConversation? = nil
    @State private var expandedConversationIDs: Set<UUID> = []

    private var groupedHistory: [(String, [ChatConversation])] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ko_KR")

        let grouped = Dictionary(grouping: viewModel.filteredConversations) { conversation in
            calendar.startOfDay(for: conversation.startDate)
        }

        return grouped
            .map { date, conversations in
                (formatter.string(from: date), conversations.sorted { $0.startDate < $1.startDate })
            }
            .sorted { $0.0 > $1.0 }
    }

    var body: some View {
        NavigationStack {
            VStack {
                if session.pets.isNotEmpty {
                    petSelectionBar
                    Divider()
                }

                if viewModel.filteredConversations.isEmpty {
                    EmptyHistoryView()
                        .frame(maxHeight: .infinity, alignment: .center)
                } else {
                    List {
                        ForEach(groupedHistory, id: \.0) { dateString, conversations in
                            Section(header: Text(dateString)) {
                               ForEach(conversations) { conversation in
                                   ChatConversationListView(
                                    conversation: conversation
                                   ) {
                                       self.selectedConversation = conversation
                                   }
                                   .listRowSeparator(.hidden)
                                   .listRowInsets(EdgeInsets())
                                   .padding(.vertical, 8)
                                   .padding(.horizontal, 16)
                                }
                            }
                            
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("상담 히스토리")
            .navigationDestination(
                item: $selectedConversation,
                destination: { conversation in
                    HistoryDetailView(
                        conversation: conversation
                    )
                }
            )
            .sheet(isPresented: $showingPetSelection) {
                HistoryPetSelectionView(
                    pets: session.pets,
                    selectedPet: viewModel.selectedPet
                ) { pet in
                    viewModel.selectedPet = pet
                }
            }
        }
    }

    private var petSelectionBar: some View {
        HStack {
            Button {
                showingPetSelection = true
            } label: {
                HStack {
                    Image(systemName: "pawprint.fill")
                        .foregroundStyle(.appWhite)
                    Text(viewModel.selectedPet?.name ?? "전체 히스토리")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.appWhite)
                    Image(systemName: "chevron.down")
                        .foregroundStyle(.appWhite)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.appOrange)
                )
            }

            Spacer()
        }
        .padding(.horizontal)
    }
}

struct ChatConversationListView: View {
    let conversation: ChatConversation
    let onToggle: () -> Void

    private var messagePreviews: [ChatMessage] {
        if conversation.messages.isEmpty == false {
            return conversation.messages.sorted { $0.timestamp < $1.timestamp }
        }

        if conversation.responses.isEmpty == false {
            return conversation.responses
                .sorted { $0.date < $1.date }
                .map { response in
                    ChatMessage(
                        id: UUID(),
                        role: .assistant,
                        content: response.summary,
                        timestamp: response.date,
                        petId: conversation.petId
                    )
                }
        }

        guard conversation.fullSummary.isEmpty == false else { return [] }
        return [
            ChatMessage(
                id: UUID(),
                role: .assistant,
                content: conversation.fullSummary,
                timestamp: conversation.lastUpdated,
                petId: conversation.petId
            )
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.appOrange)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("상담 세션")
                            .font(.caption)
                            .fontWeight(.semibold)
                        if conversation.isCompleted {
                            Text("완료")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        } else {
                            Text("진행중")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                    }
                    Text("\(conversation.responseCount)개 응답")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(conversation.startDate, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                    if conversation.startDate != conversation.lastUpdated {
                        Text("최근 \(conversation.lastUpdated, style: .time)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if messagePreviews.isEmpty {
                Text("대화 기록 없음")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                Text(messagePreviews.last?.content ?? "")
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.appWhite)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct ChatConversationView: View {
    let conversation: ChatConversation
    let isExpanded: Bool
    let onToggle: () -> Void

    private var messagePreviews: [ChatMessage] {
        if conversation.messages.isEmpty == false {
            return conversation.messages.sorted { $0.timestamp < $1.timestamp }
        }

        if conversation.responses.isEmpty == false {
            return conversation.responses
                .sorted { $0.date < $1.date }
                .map { response in
                    ChatMessage(
                        id: UUID(),
                        role: .assistant,
                        content: response.summary,
                        timestamp: response.date,
                        petId: conversation.petId
                    )
                }
        }

        guard conversation.fullSummary.isEmpty == false else { return [] }
        return [
            ChatMessage(
                id: UUID(),
                role: .assistant,
                content: conversation.fullSummary,
                timestamp: conversation.lastUpdated,
                petId: conversation.petId
            )
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("상담 세션")
                            .font(.caption)
                            .fontWeight(.semibold)
                        if conversation.isCompleted {
                            Text("완료")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        } else {
                            Text("진행중")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                    }
                    Text("\(conversation.responseCount)개 응답")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(conversation.startDate, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                    if conversation.startDate != conversation.lastUpdated {
                        Text("최근 \(conversation.lastUpdated, style: .time)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if messagePreviews.isEmpty {
                Text("대화 기록 없음")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                Text(messagePreviews.last?.content ?? "")
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                if isExpanded {
                    Divider()
                        .padding(.vertical, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(messagePreviews) { message in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 6) {
                                    Text(message.role == .user ? "사용자" : "AI")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(message.role == .user ? .blue : .green)
                                    Text(message.timestamp, style: .time)
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                Text(message.content)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(12)
                                    .background(message.role == .user ? Color.blue.opacity(0.1) : Color.green.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
        .padding(.vertical, 8)
        .animation(.spring(response: 0.32, dampingFraction: 0.82, blendDuration: 0.2), value: isExpanded)
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.circle")
                .font(.system(size: 80))
                .foregroundColor(.gray)

            Text("상담 기록이 없어요")
                .font(.title2)
                .fontWeight(.medium)

            Text("AI 상담을 완료하면 상담 요약이\n여기에 표시됩니다!")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

private struct HistoryPetSelectionView: View {
    let pets: [Pet]
    let selectedPet: Pet?
    let onSelect: (Pet?) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                HStack {
                    Image(systemName: "clock.circle.fill")
                        .foregroundColor(.appOrange)

                    VStack(alignment: .leading) {
                        Text("전체 히스토리")
                            .font(.headline)
                        Text("모든 반려동물의 상담 기록")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    if selectedPet == nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.appOrange)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelect(nil)
                    dismiss()
                }

                ForEach(pets) { pet in
                    HStack {
                        Image(systemName: "pawprint.circle.fill")
                            .foregroundColor(.appOrange)

                        VStack(alignment: .leading) {
                            Text(pet.name)
                                .font(.headline)
                            Text("\(pet.species) • \(pet.calculatedAge)살")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        if selectedPet?.id == pet.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.appOrange)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(pet)
                        dismiss()
                    }
                }
            }
            .navigationTitle("히스토리 필터")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private extension Array where Element: Identifiable {
    var isNotEmpty: Bool {
        isEmpty == false
    }
}
  
