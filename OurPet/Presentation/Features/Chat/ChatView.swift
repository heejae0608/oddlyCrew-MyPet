//
//  ChatView.swift
//  OurPet
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
            ZStack {
                AppColor.surfaceBackground
                    .ignoresSafeArea()

                if session.pets.isNotEmpty {
                    VStack(spacing: 0) {
                        // 상단 고정 영역
                        VStack(spacing: 0) {
                            petSelectionBar(pets: session.pets)
                            Divider()
                        }
                        .background(AppColor.surfaceBackground)

                        // 중간 스크롤 영역 (메시지 리스트)
                        messageList

                        // 하단 고정 영역 (입력창)
                        messageComposer
                            .background(AppColor.surfaceBackground)
                    }
                } else {
                    MissingPetInfoView {
                        showingPetRegistration = true
                    }
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
                            .foregroundStyle(AppColor.info)
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
        .background(AppColor.surfaceBackground.ignoresSafeArea())
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
                .background(AppColor.white.opacity(0.95))
                .cornerRadius(20)
            }
            .foregroundColor(AppColor.ink)
            .padding(.vertical)

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
                        EmptyChatView(pet: viewModel.selectedPet)
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
                    Spacer(minLength: 80)
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
            Text("상담 내용을 정리하고 있어요...")
                .appFont(12)
                .foregroundStyle(AppColor.subText)
        }
        .padding()
    }


    private var messageComposer: some View {
        VStack(spacing: 0) {
            if viewModel.isConversationCompleted {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        if viewModel.canShowContinueButton {
                            Button {
                                viewModel.continueConversation()
                            } label: {
                                Text(viewModel.continueButtonTitle)
                                    .appFont(15, weight: .semibold)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppColor.orange)
                        }

                        Button(role: .destructive) {
                            viewModel.startNewConversation()
                        } label: {
                            Text(viewModel.newConversationButtonTitle)
                                .appFont(15, weight: .semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(AppColor.orange)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppColor.surfaceBackground)
            }

            Divider()
                .background(AppColor.divider)

            HStack(alignment: .bottom, spacing: 12) {
                // 텍스트 입력 필드
                TextField(
                    "무엇을 도와드릴까요? 편하게 말씀해 주세요",
                    text: $viewModel.messageText,
                    axis: .vertical
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isMessageFieldFocused)
                .submitLabel(.send)
                .onSubmit {
                    if !viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isLoading {
                        viewModel.sendMessage()
                    }
                    isMessageFieldFocused = false
                }
                .appFont(16)
                .disabled(viewModel.isLoading)

                // 전송 버튼
                Button {
                    viewModel.sendMessage()
                    isMessageFieldFocused = false
                } label: {
                    Image(systemName: viewModel.isLoading ? "stop.circle.fill" : "paperplane.fill")
                        .font(.system(size: 22, weight: .regular, design: .rounded))
                        .foregroundColor(
                            viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading
                            ? AppColor.ink : AppColor.orange
                        )
                }
                .disabled(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColor.surfaceBackground)
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
                   Label {
                        Text("전체 히스토리")
                    } icon: {
                        Image(systemName: "clock.circle.fill")
                            .resizable()
                            .frame(width: 25, height: 25)
                            .foregroundStyle(AppColor.orange)
                            .scaledToFit()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(nil)
                        dismiss()
                    }
                    
                }

                ForEach(pets) { pet in
                    HStack {
                        Image(systemName: "pawprint.circle.fill")
                            .resizable()
                            .foregroundStyle(AppColor.orange)
                            .frame(width: 25, height: 25)
                            .scaledToFit()

                        VStack(alignment: .leading) {
                            Text(pet.name)
                                .appFont(17, weight: .semibold)
                                .foregroundStyle(AppColor.ink)
                           Text("\(pet.species) • \(pet.calculatedAge)살")
                               .appFont(12)
                                .foregroundStyle(AppColor.subText)
                        }

                        Spacer()

                            if selectedPet?.id == pet.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .resizable()
                                    .foregroundStyle(AppColor.orange)
                                    .frame(width: 25, height: 25)
                                    .scaledToFit()
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
                    .foregroundStyle(AppColor.ink)
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
                .foregroundStyle(AppColor.orange)

            VStack(spacing: 8) {
                Text("반려동물 정보를 먼저 등록해주세요")
                    .appFont(20, weight: .semibold)
                Text("AI 상담을 이용하려면 반려동물의 기본 정보가 필요합니다.")
                    .appFont(13)
                    .foregroundStyle(AppColor.subText)
            }

            Button {
                onRegister()
            } label: {
                Text("반려동물 등록하기")
                    .appFont(17, weight: .semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppColor.orange)
                    .foregroundStyle(AppColor.white)
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
                        .background(AppColor.chatUserBubbleBackground)
                        .foregroundColor(AppColor.chatUserBubbleText)
                        .cornerRadius(16, corners: [.topLeft, .topRight, .bottomLeft])
                        .shadow(color: AppColor.shadowSoft, radius: 4, x: 0, y: 2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(message.timestamp, style: .time)
                        .appFont(11)
                        .foregroundStyle(AppColor.subText)
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .trailing)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    // AI 헤더
                    HStack(spacing: 6) {
                        if let data = chatViewModel.selectedPet?.decodedProfileImageData,
                            let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .frame(width: 40, height: 40)
                                .scaledToFit()
                                .clipShape(Circle())
                        }else {
                            Image(systemName: "pawprint.circle")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .scaledToFit()
                                .foregroundColor(AppColor.orange.opacity(0.35))
                                .background(AppColor.white.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        Text(assistantDisplayName(for: chatViewModel.selectedPet))
                            .appFont(12)
                            .foregroundColor(AppColor.ink)
                    }
                    // 메인 메시지
                    Text(message.content)
                        .padding()
                        .background(AppColor.chatAssistantBubbleBackground)
                        .foregroundColor(AppColor.chatAssistantBubbleText)
                        .cornerRadius(16, corners: [.topLeft, .topRight, .bottomRight])
                        .shadow(color: AppColor.shadowSoft, radius: 4, x: 0, y: 2)
                        .fixedSize(horizontal: false, vertical: true)

                    // AI 응답 상세 정보 (최신 응답인 경우만)
                    if let reply = chatViewModel.latestAssistantReply,
                       message == chatViewModel.messages.last {

                        // 추가 질문들
                        if !reply.questions.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                               Text("추가 질문")
                                    .appFont(12, weight: .semibold)
                                    .foregroundStyle(AppColor.orange)

                                ForEach(reply.questions, id: \.self) { question in
                                    Text("• \(question)")
                                        .appFont(12)
                                        .foregroundStyle(AppColor.subText)
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        // 체크리스트
                        if !reply.checklist.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                               Text("확인사항")
                                    .appFont(12, weight: .semibold)
                                    .foregroundStyle(AppColor.info)

                                ForEach(reply.checklist, id: \.item) { item in
                                    HStack {
                                        Image(systemName: importanceIcon(item.importance))
                                            .foregroundStyle(importanceColor(item.importance))
                                            .font(.system(size: 11, weight: .regular, design: .rounded))
                                        Text(item.item)
                                            .appFont(12)
                                            .foregroundStyle(AppColor.subText)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        // 다음 단계
                        if !reply.nextSteps.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                               Text("권장 조치")
                                    .appFont(12, weight: .semibold)
                                    .foregroundStyle(AppColor.success)

                                ForEach(reply.nextSteps, id: \.step) { step in
                                    HStack {
                                        Image(systemName: importanceIcon(step.importance))
                                            .foregroundStyle(importanceColor(step.importance))
                                            .font(.system(size: 11, weight: .regular, design: .rounded))
                                        Text(step.step)
                                            .appFont(12)
                                            .foregroundStyle(AppColor.subText)
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
                                        .foregroundStyle(reply.urgencyLevel.accentColor)
                                   Text("긴급도: \(reply.urgencyLevel.displayName)")
                                        .appFont(11)
                                        .foregroundStyle(reply.urgencyLevel.accentColor)
                                }
                            }

                            Spacer()

                            if reply.vetConsultationNeeded {
                                HStack(spacing: 4) {
                                    Image(systemName: "stethoscope")
                                        .foregroundStyle(AppColor.danger)
                                   Text("수의사 상담 권장")
                                        .appFont(11)
                                        .foregroundStyle(AppColor.danger)
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
                                            .foregroundStyle(AppColor.success)
                                       Text("상담 완료")
                                            .appFont(11, weight: .medium)
                                            .foregroundStyle(AppColor.success)
                                    }
                                }

                                HStack {
                                    Spacer()
                                   Text("필요하실 때 다시 상담을 이어가실 수 있어요.")
                                        .appFont(11)
                                        .foregroundStyle(AppColor.subText)
                                        .italic()
                                }
                            }
                            .padding(.top, 4)
                        }
                    }

                   Text(message.timestamp, style: .time)
                        .appFont(11)
                        .foregroundStyle(AppColor.subText)
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
        case "high": return AppColor.danger
        case "medium": return AppColor.orange
        case "low": return AppColor.info
        default: return AppColor.subText
        }
    }
}

struct EmptyChatView: View {
    let pet: Pet?

    private var titleText: String {
        guard let pet else { return "보호자님, 상담을 시작해 주세요" }

        let name = pet.name
        let species = pet.species.lowercased()

        if species.contains("강아지") || species.contains("개") || species.contains("dog") {
            return "보호자님, \(name)에 대해 어떤 이야기를 들려주실까요?"
        }

        if species.contains("고양이") || species.contains("cat") {
            return "집사님, \(name)에 대해 알고 싶은 것이 있으신가요?"
        }

        return "\(name)에 대해 편하게 이야기해 주세요"
    }

    private var subtitleText: String {
        guard let pet else {
            return "반려동물의 식습관이나 행동 변화를 알려주시면 상담을 도와드릴게요."
        }

        let species = pet.species.lowercased()

        if species.contains("강아지") || species.contains("개") || species.contains("dog") {
            return "최근 식사량, 활동량, 건강 상태 등 걱정되는 부분이 있다면 말씀해 주세요."
        }

        if species.contains("고양이") || species.contains("cat") {
            return "사소한 변화라도 편하게 들려주시면 함께 살펴볼게요."
        }

        return "식습관, 행동, 건강 상태에 대해 자유롭게 이야기해 주세요."
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "message.circle")
                .font(.system(size: 80))
                .foregroundStyle(AppColor.orange)

            Text(titleText)
                .appFont(22, weight: .medium)
                .foregroundStyle(AppColor.ink)

            Text(subtitleText)
                .appFont(15)
                .foregroundStyle(AppColor.subText)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 8) {
                Text("예시 질문:")
                    .appFont(12, weight: .semibold)
                    .foregroundStyle(AppColor.subText)

                Text("• 반려동물이 갑자기 숨어있어요")
                Text("• 최근 식사량이 줄어든 것 같아요")
                Text("• 검진이나 예방접종은 언제 해야 할까요?")
            }
            .appFont(12)
            .foregroundStyle(AppColor.subText)
    .padding()
    .background(AppColor.mutedGray.opacity(0.15))
    .cornerRadius(12)
        }
        .padding()
    }
}

private func assistantDisplayName(for pet: Pet?) -> String {
    guard let pet else { return "돌봄 파트너" }
    return "\(pet.name) 돌봄 파트너"
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
        case .low: return AppColor.success
        case .medium: return AppColor.orange
        case .high: return AppColor.danger
        case .critical: return AppColor.danger
        case .unknown: return AppColor.subText
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
