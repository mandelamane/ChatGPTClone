//
//  ContentView.swift
//  GPTTest
//
//  Created by あまねすぎい on 2023/07/17.
//

import SwiftUI



struct ContentView: View {
    
    @State private var content = ""
    @State private var response = ""
    @State private var chatContents: [GPTContent] = []
    @State private var textMessages: [(title: String, content: String)] = []
    @State private var requesting = false
    @State private var selectedIndex = 0
    
    @FocusState var focus:Bool
    
    let options = ["gpt-3.5-turbo", "gpt-4"]
    let generator = UIImpactFeedbackGenerator(style: .heavy)
    
    
    var body: some View {
        NavigationView {
            VStack(spacing: 15) {
                Picker("", selection: $selectedIndex) {
                    ForEach(options.indices, id: \.self) { index in
                        Text(options[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .scaleEffect(1.5)
                .padding(.horizontal, 85)
                .padding(.top, 20)
                
                ScrollViewReader { scrollView in
                    ScrollView {
                        ForEach(textMessages.indices, id: \.self) { index in
                            MessageView(title: textMessages[index].title, message: textMessages[index].content)
                                .id(index)
                        }
                    }
                    .onChange(of: textMessages.count) { _ in
                        withAnimation{
                            scrollView.scrollTo(textMessages.count-1)
                            }
                        }
                    }
                    .onTapGesture{
                        focus = false
                }
                
                
                HStack {
                    TextField("Message", text: $content, axis: .vertical)
                        .messageFieldStyle(isEmpty: content.isEmpty)
                        .padding(16.0)
                        .focused($focus)
                    
                    Button(action: {
                        generator.impactOccurred()
                        requesting = true
                        
                        var lastGPTIndex: Int? = nil
                        chatContents.append(GPTContent(role: "user", content: content))
                        textMessages.append(("USER", content))
                        content = ""
                        
                        Task{
                            do {
                                let streamResponse = try await request(chatContents: chatContents, gpt_type: options[selectedIndex])
                                
                                for try await line in streamResponse.lines {
                                    let components = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)
                                    
                                    let streamContent = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                                    
                                    if streamContent == "[DONE]" {
                                        chatContents.append(GPTContent(role: "assistant", content: response))
                                        response = ""
                                    } else {
                                        let chunk = try? JSONDecoder().decode(GPTResponse.self, from: streamContent.data(using: .utf8)!)
                                        
                                        if let addChunk = chunk?.choices.first?.delta.content, !addChunk.isEmpty {
                                            response.append(addChunk)
                                        }
                                        
                                        if let index = lastGPTIndex {
                                            textMessages[index] = ("CHATGPT", response)  // Update existing message
                                            generator.impactOccurred()
                                        } else {
                                            textMessages.append(("CHATGPT", response))  // Add new message
                                            lastGPTIndex = textMessages.count - 1  // Remember index of the new message
                                        }
                                    }
                                }
                                
                            } catch {
                                let nsError = error as NSError
                                response = nsError.domain
                            }
                            DispatchQueue.main.async {
                                requesting = false
                            }
                        }
                        
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(requesting ? .gray : .purple)
                    }
                    .disabled(requesting || content.isEmpty)
                }
                .padding(.horizontal, 10)
            }
            .background(Color.white.edgesIgnoringSafeArea(.all))
            .navigationTitle("ChatGPT")
            .foregroundColor(.black)
        }
    }
}


struct MessageView: View {
    var title: String
    var message: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5){
            Text(title)
                .textSelection(.enabled)
                .font(.system(size: 12))
                .foregroundColor(.gray)
            Text(message)
                .textSelection(.enabled)
                .font(.system(size: 15))
                .padding(10)
                .background(title=="USER" ? Color.purple : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 15)
        }
        .padding(.horizontal, 10)
    }
}


struct MessageFieldStyle: ViewModifier {
    var isEmpty: Bool

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isEmpty ? Color.gray : Color.white)
                    .opacity(0.2)
                    .padding(.horizontal, -12.5)
                    .padding(.vertical, -8.0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isEmpty ? Color.clear : Color.gray, lineWidth: 1.2)
                    .padding(.horizontal, -12.5)
                    .padding(.vertical, -8.0)
            )
    }
}


extension View {
    func messageFieldStyle(isEmpty: Bool) -> some View {
        self.modifier(MessageFieldStyle(isEmpty: isEmpty))
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
