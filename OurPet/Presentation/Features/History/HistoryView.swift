//
//  HistoryView.swift
//  OurPet
//
//  Created by 전희재 on 9/18/25.
//

import SwiftUI
import Combine

struct UpdateHistoryToChat: Equatable {
    let messages: [ChatMessage]
    let selectedPet: Pet
}

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @ObservedObject var chatViewModel: ChatViewModel
    @EnvironmentObject private var session: SessionViewModel
    @State private var showingPetSelection = false
    @State private var updateData: UpdateHistoryToChat = UpdateHistoryToChat(
        messages: [],
        selectedPet: Pet(
            userId: UUID(),
            name: "",
            species: "",
            gender: "",
            isNeutered: false
        )
    )
    @Binding var selectedTab: Int
    
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
                (formatter.string(from: date), conversations.sorted { $0.startDate > $1.startDate })
            }
            .sorted { $0.0 > $1.0 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.surfaceBackground
                    .ignoresSafeArea()

                historyList
            }
            .navigationTitle("상담 히스토리")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: ChatConversation.self) { conversation in
                if let selectedPet = viewModel.selectedPet {
                    HistoryDetailView(
                        conversation: conversation,
                        userName: session.currentUser?.name ?? "사용자",
                        updateData: $updateData,
                        selectedTab: $selectedTab,
                        selectedPet: selectedPet
                    )
                }
            }
            .sheet(isPresented: $showingPetSelection) {
                HistoryPetSelectionView(
                    pets: session.pets,
                    selectedPet: viewModel.selectedPet
                ) { pet in
                    viewModel.selectedPet = pet
                }
            }
            .onChange(of: updateData) {
                chatViewModel.updateFromHistoryDetailView(updateData: updateData)
            }
        }.onAppear {
            AnalyticsHelper.sendScreenEvent(event: .history)
        }
    }

    private var historyList: some View {
        VStack {
            List {
                petsSection

                if viewModel.filteredConversations.isEmpty {
                    emptyStateSection
                } else {
                    historySections
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            
            Spacer()
            
            HistoryAdBannerRow()
                .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 12, trailing: 0))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder
    private var petsSection: some View {
        if session.pets.isNotEmpty {
            Section {
                petSelectionRow
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .textCase(nil)
        }
    }

    private var emptyStateSection: some View {
        Section {
            EmptyHistoryView()
                .frame(maxWidth: .infinity, minHeight: 260, alignment: .center)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
        .textCase(nil)
    }

    private var historySections: some View {
        ForEach(groupedHistory, id: \.0) { dateString, conversations in
            Section(header:
                Text(dateString)
                    .appFont(12, weight: .semibold)
                    .foregroundStyle(AppColor.subText)
            ) {
                ForEach(conversations) { conversation in
                                    NavigationLink(value: conversation) {
                                        ChatConversationListView(
                                            conversation: conversation,
                                            isDisabled: false
                                        )
                                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    private var petSelectionRow: some View {
        HStack {
            Button {
                AnalyticsHelper.sendClickEvent(event: .clicked_history_filter)
                showingPetSelection = true
            } label: {
                HStack {
                    Image(systemName: "pawprint.fill")
                        .foregroundStyle(AppColor.white)
                    Text(viewModel.selectedPet?.name ?? "반려동물 선택")
                        .appFont(15, weight: .semibold)
                        .foregroundStyle(AppColor.white)
                    Image(systemName: "chevron.down")
                        .foregroundStyle(AppColor.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(AppColor.orange)
                )
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ChatConversationListView: View {
    let conversation: ChatConversation
    let isDisabled: Bool

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
    
    private var cardBackground: Color {
        switch conversation.status {
        case .inProgress:
            return AppColor.historyInProgressBackground
        case .completed:
            return AppColor.historyCompletedBackground
        case .closed:
            return AppColor.historyClosedBackground
        }
    }

    private var statusTitle: String {
        switch conversation.status {
        case .inProgress: return "진행중인 상담"
        case .completed: return "완료된 상담"
        case .closed: return "종료된 상담"
        }
    }

    private var statusColor: Color {
        switch conversation.status {
        case .inProgress: return AppColor.orange
        case .completed: return AppColor.success
        case .closed: return AppColor.mutedGray
        }
    }

    private var statusIconColor: Color {
        switch conversation.status {
        case .inProgress:
            return AppColor.orange
        case .completed:
            return AppColor.success
        case .closed:
            return AppColor.mutedGray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundStyle(statusIconColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(statusTitle)
                        .appFont(14, weight: .semibold)
                        .foregroundStyle(statusColor)
                    Text("\(conversation.responseCount)개 응답")
                        .appFont(12)
                        .foregroundStyle(AppColor.subText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(conversation.startDate, style: .time)
                        .appFont(11)
                        .foregroundStyle(AppColor.subText)
                    if conversation.startDate != conversation.lastUpdated {
                        Text("최근 \(conversation.lastUpdated, style: .time)")
                            .appFont(11)
                            .foregroundStyle(AppColor.subText)
                    }
                }
            }

            if messagePreviews.isEmpty {
                Text("대화 기록 없음")
                    .appFont(15, weight: .semibold)
                    .foregroundStyle(AppColor.subText)
                    .italic()
            } else if let lastContent = messagePreviews.last?.content {
                Text(lastContent)
                    .appFont(15)
                    .foregroundStyle(AppColor.ink)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackground)
                .shadow(color: AppColor.shadowSoft, radius: 6, x: 0, y: 4)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}


struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.circle")
                .font(.system(size: 34, weight: .regular, design: .rounded))
                .foregroundStyle(AppColor.mutedGray)

            Text("상담 기록이 없어요")
                .appFont(22, weight: .medium)

            Text("반려동물 상담을 완료하면 상담 요약이\n여기에 표시됩니다!")
                .appFont(15)
                .foregroundStyle(AppColor.subText)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#if DEBUG
struct HistoryView_Previews: PreviewProvider {
    @MainActor static var previews: some View {
        Group {
            HistoryPreviewFactory.makeHistoryView(displayName: "History - Light", scheme: .light)
            HistoryPreviewFactory.makeHistoryView(displayName: "History - Dark", scheme: .dark)
        }
    }
}

private enum HistoryPreviewFactory {
    static func makePets() -> [Pet] {
        let ownerId = UUID()
        return [
            Pet(
                userId: ownerId,
                name: "콩이",
                species: "강아지",
                breed: "말티즈",
                gender: "수컷",
                isNeutered: true,
                weight: 4.5,
                existingConditions: "슬개골 탈구",
                birthDate: Calendar.current.date(byAdding: .year, value: -5, to: Date()),
                adoptionDate: Calendar.current.date(byAdding: .year, value: -4, to: Date()),
                registrationDate: Calendar.current.date(byAdding: .year, value: -4, to: Date()) ?? Date()
            ),
            Pet(
                userId: ownerId,
                name: "모모",
                species: "고양이",
                breed: "러시안블루",
                gender: "암컷",
                isNeutered: false,
                weight: 3.8,
                existingConditions: "피부 민감",
                birthDate: Calendar.current.date(byAdding: .year, value: -3, to: Date()),
                adoptionDate: Calendar.current.date(byAdding: .year, value: -2, to: Date()),
                registrationDate: Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
            )
        ]
    }

    static func makeConversations(for pets: [Pet]) -> [UUID: [ChatConversation]] {
        var storage: [UUID: [ChatConversation]] = [:]
        let statuses: [ChatConversation.Status] = [.inProgress, .completed, .closed]
        var counter = 0

        for pet in pets {
            var perPet: [ChatConversation] = []
            for offset in 0..<5 { // 각 펫당 5개, 총 10개의 더미 데이터
                let dayOffset = counter + offset
                let startDate = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
                let details = HistoryPreviewFactory.makeMessageBundle(index: dayOffset, pet: pet, startDate: startDate)

                let conversation = ChatConversation(
                    id: UUID(),
                    petId: pet.id,
                    startDate: startDate,
                    lastUpdated: details.lastUpdated,
                    responses: details.responses,
                    messages: details.messages,
                    fullSummary: details.summary,
                    status: statuses[(dayOffset) % statuses.count]
                )

                perPet.append(conversation)
            }
            storage[pet.id] = perPet
            counter += 5
        }

        return storage
    }

    @MainActor
    static func makeHistoryView(displayName: String, scheme: ColorScheme) -> some View {
        let pets = makePets()
        let session = PreviewSessionFactory.makeSession(pets: pets)
        let conversationsByPet = makeConversations(for: pets)

        let chatUseCase = PreviewChatUseCase(conversationsByPet: conversationsByPet)
        let conversationRepository = PreviewConversationRepository()
        let chatConversationRepository = PreviewChatConversationRepository(conversationsByPet: conversationsByPet)

        let historyViewModel = HistoryViewModel(
            session: session,
            chatUseCase: chatUseCase,
            conversationRepository: conversationRepository,
            chatConversationRepository: chatConversationRepository
        )

        let chatViewModel = ChatViewModel(session: session, chatUseCase: chatUseCase)

        return HistoryView(
            viewModel: historyViewModel,
            chatViewModel: chatViewModel,
            selectedTab: .constant(1)
        )
        .environmentObject(session)
        .previewDisplayName(displayName)
        .preferredColorScheme(scheme)
    }

    private static func makeMessageBundle(index: Int, pet: Pet, startDate: Date) -> (messages: [ChatMessage], responses: [ChatResponse], summary: String, lastUpdated: Date) {
        let userMessage = ChatMessage(
            id: UUID(),
            role: .user,
            content: "\(pet.name) 상태 문의 #\(index)",
            timestamp: startDate,
            petId: pet.id
        )

        let assistantDate = startDate.addingTimeInterval(900)
        let assistantMessage = ChatMessage(
            id: UUID(),
            role: .assistant,
            content: "상담 답변 #\(index): 가벼운 산책과 수분 섭취를 권장합니다.",
            timestamp: assistantDate,
            petId: pet.id
        )

        let followUpDate = assistantDate.addingTimeInterval(600)
        let followUpMessage = ChatMessage(
            id: UUID(),
            role: .assistant,
            content: "추가 안내 #\(index): 이상 증상이 지속되면 병원 방문을 고려해 주세요.",
            timestamp: followUpDate,
            petId: pet.id
        )

        let responses = [
            ChatResponse(responseId: "resp_\(index)_1", summary: "주 증상 확인 및 기본 케어 안내", date: assistantDate),
            ChatResponse(responseId: "resp_\(index)_2", summary: "추가 모니터링 권장", date: followUpDate)
        ]

        let summary = "\(pet.name) 상담 요약 #\(index): 가벼운 증상으로 보이며, 집에서 모니터링을 지속해 주세요."
        return ([userMessage, assistantMessage, followUpMessage], responses, summary, followUpDate)
    }
}

private final class PreviewChatUseCase: ChatUseCaseInterface {
    private var conversationsByPet: [UUID: [ChatConversation]]

    init(conversationsByPet: [UUID: [ChatConversation]]) {
        self.conversationsByPet = conversationsByPet
    }

    func history(for petId: UUID?) -> [ChatMessage] {
        guard let petId, let conversation = conversationsByPet[petId]?.sorted(by: { $0.lastUpdated > $1.lastUpdated }).first else {
            return []
        }
        return conversation.messages
    }

    func loadLastConversation(for pet: Pet) async -> ChatHistoryResult {
        let conversations = conversationsByPet[pet.id]?.sorted(by: { $0.lastUpdated > $1.lastUpdated }) ?? []
        guard let latest = conversations.first else {
            return ChatHistoryResult(messages: [], conversation: nil)
        }
        return ChatHistoryResult(messages: latest.messages, conversation: latest)
    }

    func append(_ message: ChatMessage) {}

    func clearHistory(for petId: UUID?) {}

    func startNewConversation(for petId: UUID) {}
    
    func saveCurrentMessages(conversationId: UUID, messages: [ChatMessage]) async throws {}

    func send(messages: [ChatMessage], pet: Pet?) -> AnyPublisher<AssistantReply, Error> {
        Empty().eraseToAnyPublisher()
    }

    func updateConversationStatus(conversationId: UUID, status: ChatConversation.Status) async {}
}

private final class PreviewChatConversationRepository: ChatConversationRepositoryInterface {
    private var storage: [UUID: [ChatConversation]]
    private let subject: CurrentValueSubject<[ChatConversation], Never>

    init(conversationsByPet: [UUID: [ChatConversation]]) {
        storage = conversationsByPet
        subject = CurrentValueSubject(conversationsByPet.values.flatMap { $0 })
    }

    var conversationsPublisher: AnyPublisher<[ChatConversation], Never> {
        subject.eraseToAnyPublisher()
    }

    func getConversations(for petId: UUID) async throws -> [ChatConversation] {
        storage[petId] ?? []
    }

    func getConversation(by id: UUID) async throws -> ChatConversation? {
        subject.value.first { $0.id == id }
    }

    func saveConversation(_ conversation: ChatConversation) async throws {
        var list = storage[conversation.petId] ?? []
        if let index = list.firstIndex(where: { $0.id == conversation.id }) {
            list[index] = conversation
        } else {
            list.append(conversation)
        }
        storage[conversation.petId] = list
        subject.send(storage.values.flatMap { $0 })
    }

    func deleteConversation(id: UUID) async throws {
        storage = storage.mapValues { $0.filter { $0.id != id } }
        subject.send(storage.values.flatMap { $0 })
    }

    func addResponse(to conversationId: UUID, response: ChatResponse) async throws {}

    func updateConversationSummary(conversationId: UUID, fullSummary: String) async throws {}

    func updateConversationMessages(conversationId: UUID, messages: [ChatMessage]) async throws {}

    func markConversationCompleted(conversationId: UUID) async throws {}

    func updateConversationStatus(conversationId: UUID, status: ChatConversation.Status) async throws {}
}

private final class PreviewConversationRepository: ConversationRepositoryInterface {
    private let subject = CurrentValueSubject<[Conversation], Never>([])

    var conversationsPublisher: AnyPublisher<[Conversation], Never> {
        subject.eraseToAnyPublisher()
    }

    func getConversations(for petId: UUID) async throws -> [Conversation] { [] }

    func getConversation(by responseId: String) async throws -> Conversation? { nil }

    func saveConversation(_ conversation: Conversation) async throws {}

    func deleteConversation(id: UUID) async throws {}
}
#endif

private struct HistoryPetSelectionView: View {
    let pets: [Pet]
    let selectedPet: Pet?
    let onSelect: (Pet) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(pets) { pet in
                    HStack {
                        Image(systemName: "pawprint.circle.fill")
                            .foregroundStyle(AppColor.orange)

                        VStack(alignment: .leading) {
                            Text(pet.name)
                                .appFont(17, weight: .semibold)
                            Text("\(pet.species) • \(pet.calculatedAge)살")
                                .appFont(12)
                                .foregroundStyle(AppColor.subText)
                        }

                        Spacer()

                        if selectedPet?.id == pet.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColor.orange)
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
                        AnalyticsHelper.sendClickEvent(event: .clicked_history_filter_close)
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
  
