//
//  ContentView.swift
//  Docks
//
//  Created by david on 11/3/22.
//

import SwiftUI

struct ContentView: View {
    @StateObject var DeviceManager = DocksDevice()
    @StateObject var Chat = DocksChat()
    @State private var chatInput : String = ""
    @FocusState private var chatFocused: Bool
    
    var chatWindow : some View {
        List {
            ForEach(Chat.messages.reversed()) { message in
                VStack{
                    Text(message.nickname)
                        .frame(maxWidth: .infinity, alignment: message.my_message ? .trailing : .leading)
                        .font(.footnote)
                        .padding(.bottom, -5)
                        .foregroundColor(Color.gray)
                    Text(message.contents)
                        .padding(5)
                        .padding(.leading, 5)
                        .padding(.trailing, 5)
                        .background(message.my_message ? Color.blue : Color.gray)
                        .foregroundColor(Color.white)
                        .cornerRadius(10)
                        .frame(maxWidth: .infinity, alignment: message.my_message ? .trailing : .leading)
                }
                .rotationEffect(.radians(.pi))
                .scaleEffect(x: -1, y: 1, anchor: .center)
                
            }
        }
        .rotationEffect(.radians(.pi))
        .scaleEffect(x: -1, y: 1, anchor: .center)
    }
    
    var inputField : some View {
        HStack {
            TextField(
                "",
                text: $chatInput
            )
            .focused($chatFocused)
            .onSubmit {
                sendMessage()
            }
            .disableAutocorrection(true)
            .textFieldStyle(.roundedBorder)

            Button("Send") {
                sendMessage()
            }
        }.padding(10)
    }
        
    func sendMessage() {
        if (chatInput != "") {
            if (chatInput.hasPrefix("/nick ")) {
                // set nickname
                Chat.verifyAndSetNickname(nickname: String(chatInput.dropFirst(6)))
            } else {
                Chat.sendMessage(contents: chatInput)
            }
        }
        
        // reset chat input
        chatInput = ""
    }
    
    var body: some View {
        VStack {
            chatWindow
            inputField
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
