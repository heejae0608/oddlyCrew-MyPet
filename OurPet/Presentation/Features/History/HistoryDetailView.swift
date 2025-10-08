//
//  HistoryDetailView.swift
//  OurPet
//
//  Created by 조성재 on 9/28/25.
//

import SwiftUI

struct HistoryDetailView: View {
    let conversation: ChatConversation
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
                .font(.body)
                .foregroundColor(.secondary)
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
    
    private var HistoryMessageList: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    // 상단 여백
                    Spacer(minLength: 8)
                    
                    ForEach(messagePreviews) { message in
                        if conversation.isCompleted == true {
                            
                        } else {
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
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
        }
    }
}
