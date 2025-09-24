//
//  ChatView.swift
//  MyPet
//
//  Created by 전희재 on 9/18/25.
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @EnvironmentObject private var session: SessionViewModel
    @State private var showingPetSelection = false
    @State private var showingPetRegistration = false
    @FocusState private var isMessageFieldFocused: Bool

    var body: some View {
        NavigationView {
            if session.pets.isNotEmpty {
                VStack(spacing: 0) {
                    // 상단 고정 영역
                    VStack(spacing: 0) {
                        petSelectionBar(pets: session.pets)
                        Divider()
                    }
                    .background(Color(.systemBackground))

                    // 중간 스크롤 영역 (메시지 리스트)
                    messageList

                    // 하단 고정 영역 (입력창)
                    messageComposer
                        .background(Color(.systemBackground))
                }
            } else {
                MissingPetInfoView {
                    showingPetRegistration = true
                }
            }
        }
        .navigationTitle("AI 상담")
        .navigationBarTitleDisplayMode(.inline)
        .navigationViewStyle(StackNavigationViewStyle())
        .toolbar {
            if session.pets.isNotEmpty && viewModel.selectedPet != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.startNewConversation()
                    } label: {
                        Image(systemName: "plus.bubble")
                            .foregroundColor(.blue)
                    }
                    .accessibilityLabel("새 대화 시작")
                }
            }
        }
        .sheet(isPresented: $showingPetSelection) {
            PetSelectionView(
                pets: session.pets,
                selectedPet: viewModel.selectedPet
            ) { pet in
                viewModel.selectPet(pet)
            }
        }
        .sheet(isPresented: $showingPetRegistration) {
            PetRegistrationView()
                .environmentObject(session)
        }
    }

    private func petSelectionBar(pets: [Pet]) -> some View {
        HStack {
            Button {
                showingPetSelection = true
            } label: {
                HStack {
                    Image(systemName: "pawprint.fill")
                    Text(viewModel.selectedPet?.name ?? "반려동물 선택")
                    Image(systemName: "chevron.down")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(20)
            }
            .foregroundColor(.blue)

            Spacer()

            Button(role: .destructive) {
                viewModel.clearChat()
            } label: {
                Image(systemName: "trash")
            }
            .disabled(viewModel.messages.isEmpty)
        }
        .padding(.horizontal)
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    // 상단 여백
                    Spacer(minLength: 8)

                    if viewModel.messages.isEmpty {
                        EmptyChatView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else {
                        ForEach(viewModel.messages) { message in
                            ChatMessageView(message: message, chatViewModel: viewModel)
                                .id(message.id)
                                .padding(.horizontal, 16)
                        }
                    }

                    if viewModel.isLoading {
                        loadingIndicator
                            .id("loading")
                            .padding(.horizontal, 16)
                    }

                    // 하단 여백 - 키보드와 입력창에 가려지지 않도록
                    Spacer(minLength: 120)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .onChange(of: viewModel.messages.count) {
                DispatchQueue.main.async {
                    withAnimation(.easeOut(duration: 0.2)) {
                        if let last = viewModel.messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            .onChange(of: viewModel.isLoading) {
                if viewModel.isLoading {
                    DispatchQueue.main.async {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo("loading", anchor: .bottom)
                        }
                    }
                }
            }
            .onChange(of: isMessageFieldFocused) {
                if isMessageFieldFocused {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            if let last = viewModel.messages.last {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            } else if viewModel.isLoading {
                                proxy.scrollTo("loading", anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isMessageFieldFocused = false
            }
        }
    }

    private var loadingIndicator: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("AI가 생각 중...")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }


    private var messageComposer: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color(.separator))

            HStack(alignment: .bottom, spacing: 12) {
                // 텍스트 입력 필드
                TextField(
                    "반려동물에 대해 궁금한 것을 물어보세요...",
                    text: $viewModel.messageText,
                    axis: .vertical
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isMessageFieldFocused)
                .lineLimit(1...4)
                .submitLabel(.send)
                .onSubmit {
                    if !viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isLoading {
                        viewModel.sendMessage()
                    }
                    isMessageFieldFocused = false
                }
                .disabled(viewModel.isLoading)

                // 전송 버튼
                Button {
                    viewModel.sendMessage()
                    isMessageFieldFocused = false
                } label: {
                    Image(systemName: viewModel.isLoading ? "stop.circle.fill" : "paperplane.fill")
                        .font(.title2)
                        .foregroundColor(
                            viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading
                            ? .gray : .blue
                        )
                }
                .disabled(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
        .disabled(session.pets.isEmpty)
    }
}

private struct PetSelectionView: View {
    let pets: [Pet]
    let selectedPet: Pet?
    let onSelect: (Pet?) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section {
                    Label("전체 히스토리", systemImage: "clock.circle.fill")
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelect(nil)
                            dismiss()
                        }
                }

                ForEach(pets) { pet in
                    HStack {
                        Image(systemName: "pawprint.circle.fill")
                            .foregroundColor(.blue)

                        VStack(alignment: .leading) {
                            Text(pet.name)
                                .font(.headline)
                            Text("\(pet.species) • \(pet.age)살")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        if selectedPet?.id == pet.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(pet)
                        dismiss()
                    }
                }
            }
            .navigationTitle("반려동물 선택")
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

private struct MissingPetInfoView: View {
    let onRegister: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "pawprint.circle")
                .font(.system(size: 72))
                .foregroundColor(.blue)

            VStack(spacing: 8) {
                Text("반려동물 정보를 먼저 등록해주세요")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("AI 상담을 이용하려면 반려동물의 기본 정보가 필요합니다.")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }

            Button {
                onRegister()
            } label: {
                Text("반려동물 등록하기")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}

struct ChatMessageView: View {
    let message: ChatMessage
    let chatViewModel: ChatViewModel

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16, corners: [.topLeft, .topRight, .bottomLeft])
                        .fixedSize(horizontal: false, vertical: true)

                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .trailing)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    // AI 헤더
                    HStack(spacing: 6) {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.green)
                        Text("AI 어시스턴트")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    // 메인 메시지
                    Text(message.content)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(16, corners: [.topLeft, .topRight, .bottomRight])
                        .fixedSize(horizontal: false, vertical: true)

                    // AI 응답 상세 정보 (최신 응답인 경우만)
                    if let reply = chatViewModel.latestAssistantReply,
                       message == chatViewModel.messages.last {

                        // 추가 질문들
                        if !reply.questions.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("추가 질문")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)

                                ForEach(reply.questions, id: \.self) { question in
                                    Text("• \(question)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        // 체크리스트
                        if !reply.checklist.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("확인사항")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)

                                ForEach(reply.checklist, id: \.item) { item in
                                    HStack {
                                        Image(systemName: importanceIcon(item.importance))
                                            .foregroundColor(importanceColor(item.importance))
                                            .font(.caption2)
                                        Text(item.item)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        // 다음 단계
                        if !reply.nextSteps.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("권장 조치")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)

                                ForEach(reply.nextSteps, id: \.step) { step in
                                    HStack {
                                        Image(systemName: importanceIcon(step.importance))
                                            .foregroundColor(importanceColor(step.importance))
                                            .font(.caption2)
                                        Text(step.step)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        // 긴급도 및 수의사 상담
                        HStack {
                            if reply.urgencyLevel != .unknown {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(reply.urgencyLevel.accentColor)
                                    Text("긴급도: \(reply.urgencyLevel.displayName)")
                                        .font(.caption2)
                                        .foregroundColor(reply.urgencyLevel.accentColor)
                                }
                            }

                            Spacer()

                            if reply.vetConsultationNeeded {
                                HStack(spacing: 4) {
                                    Image(systemName: "stethoscope")
                                        .foregroundColor(.red)
                                    Text("수의사 상담 권장")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }
                            }
                        }

                        // 대화 종료 표시
                        if reply.status == .providingAnswer {
                            VStack(spacing: 4) {
                                HStack {
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("상담 완료")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                            .fontWeight(.medium)
                                    }
                                }

                                HStack {
                                    Spacer()
                                    Text("새로운 질문이 있으시면 언제든지 말씀해주세요!")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                            }
                            .padding(.top, 4)
                        }
                    }

                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.8, alignment: .leading)
                Spacer()
            }
        }
    }

    private func importanceIcon(_ importance: String) -> String {
        switch importance.lowercased() {
        case "high": return "exclamationmark.circle.fill"
        case "medium": return "info.circle.fill"
        case "low": return "circle.fill"
        default: return "circle.fill"
        }
    }

    private func importanceColor(_ importance: String) -> Color {
        switch importance.lowercased() {
        case "high": return .red
        case "medium": return .orange
        case "low": return .blue
        default: return .gray
        }
    }
}

struct EmptyChatView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "message.circle")
                .font(.system(size: 80))
                .foregroundColor(.gray)

            Text("AI 상담을 시작해보세요")
                .font(.title2)
                .fontWeight(.medium)

            Text("반려동물의 건강이나 행동에 대해\n궁금한 것을 물어보세요!")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 8) {
                Text("예시 질문:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)

                Text("• 우리 강아지가 계속 기침을 해요")
                Text("• 고양이가 갑자기 숨어있어요")
                Text("• 설사를 하는데 괜찮을까요?")
            }
            .font(.caption)
            .foregroundColor(.gray)
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .padding()
    }
}


private extension Array where Element: Identifiable {
    var isNotEmpty: Bool {
        isEmpty == false
    }
}

private extension UrgencyLevel {
    var displayName: String {
        switch self {
        case .low: return "낮음"
        case .medium: return "보통"
        case .high: return "높음"
        case .critical: return "위험"
        case .unknown: return "알 수 없음"
        }
    }

    var accentColor: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .red
        case .unknown: return .gray
        }
    }
}

// MARK: - Corner Radius Utility

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
