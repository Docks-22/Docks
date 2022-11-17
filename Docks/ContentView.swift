//
//  ContentView.swift
//  Docks
//
//  Created by david on 11/3/22.
//

import SwiftUI

struct ContentView: View {
    @StateObject var DeviceManager = DocksDevice()
    @State private var chatInput : String = ""
    @FocusState private var chatFocused: Bool
    
    var chatWindow : some View {
        Text("hello!")
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
        }
    }
    
    var body: some View {
        VStack {
            chatWindow
            inputField
        }
        .padding()
    }
    
    func sendMessage() {
        // TODO: send message
        print(chatInput)
        
        // reset chat input
        chatInput = ""
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
