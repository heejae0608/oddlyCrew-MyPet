//
//  HistoryDetailView.swift
//  OurPet
//
//  Created by 조성재 on 9/28/25.
//

import SwiftUI

struct HistoryDetailView: View {
    let conversation: ChatConversation
    let userName: String
    @Binding var updateData: UpdateHistoryToChat
    @Binding var selectedTab: Int
    @Environment(\.dismiss) private var dismiss
    
    var selectedPet: Pet
    
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
        if messagePreviews.isEmpty {
            Text("대화 기록 없음")
                .appFont(17)
                .foregroundStyle(AppColor.subText)
                .italic()
        } else {
                    HistoryMessageList
                .navigationTitle("상담 내역")
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("이전")
                            }
                        }
                    }
                    if conversation.status != .closed {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                updateData = UpdateHistoryToChat(
                                    messages: conversation.messages,
                                    selectedPet: selectedPet
                                )

                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    selectedTab = 2 // 상담 탭
                                }
                            } label: {
                                Text("상담 이어가기")
                            }

                        }
                    }
                }
        }
    }
    
    private var HistoryMessageList: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    // 상단 여백
                    Spacer(minLength: 8)
                    
                    ForEach(messagePreviews) { message in
                        let maxWidth: CGFloat = message.role == .user ? (UIScreen.main.bounds.width * 0.7) : (UIScreen.main.bounds.width * 0.8)
                        
                        if message.role == .user {
                            HStack {
                                Spacer()
                                VStack(alignment: .trailing, spacing: 6) {
                                    HStack(spacing: 6) {
                                        Text(senderLabel(for: message))
                                            .appFont(11, weight: .semibold)
                                            .foregroundStyle(senderAccentColor(for: message))
                                        Text(message.timestamp, style: .time)
                                            .appFont(11)
                                            .foregroundStyle(AppColor.subText)
                                    }
                                    Text(message.content)
                                        .appFont(17)
                                        .foregroundStyle(AppColor.text)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(12)
                                        .background(bubbleBackground(for: message))
                                        .cornerRadius(12)
                                }
                                .frame(maxWidth: maxWidth, alignment: .trailing)
                                .padding(.horizontal, 16)
                            }
                        } else {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 6) {
                                        Text(senderLabel(for: message))
                                            .appFont(11, weight: .semibold)
                                            .foregroundStyle(senderAccentColor(for: message))
                                        Text(message.timestamp, style: .time)
                                            .appFont(11)
                                            .foregroundStyle(AppColor.subText)
                                    }
                                    Text(message.content)
                                        .appFont(17)
                                        .foregroundStyle(AppColor.text)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(12)
                                        .background(bubbleBackground(for: message))
                                        .cornerRadius(12)
                                }
                                .frame(maxWidth: maxWidth, alignment: .leading)
                                .padding(.horizontal, 16)
                                
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
    }
}

private extension HistoryDetailView {
    func senderLabel(for message: ChatMessage) -> String {
        switch message.role {
        case .user:
            return "\(userName)님"
        case .assistant:
            return selectedPet.name.isEmpty
                ? "돌봄 파트너"
                : "\(selectedPet.name)의 돌봄 파트너"
        case .system:
            return "시스템"
        }
    }

    func senderAccentColor(for message: ChatMessage) -> Color {
        switch message.role {
        case .user:
            return AppColor.info
        case .assistant:
            return .appOrange
        case .system:
            return AppColor.mutedGray
        }
    }

    func bubbleBackground(for message: ChatMessage) -> Color {
        switch message.role {
        case .user:
            return AppColor.info.opacity(0.12)
        case .assistant:
            return AppColor.chatAssistantBubbleBackground.opacity(0.12)
        case .system:
            return AppColor.mutedGray.opacity(0.12)
        }
    }
}
