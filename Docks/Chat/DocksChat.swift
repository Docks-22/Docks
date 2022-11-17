//
//  DocksChat.swift
//  Docks
//
//  Created by david on 11/16/22.
//

import Foundation
    
struct Message : Identifiable {
    var contents : String
    
    // flag denoting that this message was sent by my user
    var my_message : Bool
    var id: String {contents}
}


class DocksChat : NSObject, ObservableObject {
    @Published var messages : [Message] = []
    var deviceManager : DocksDevice
    
    override init() {
        deviceManager = DocksDevice()
        super.init()
    }
    
    func sendMessage(contents : String) {
        // TODO: link into library
        deviceManager.send(msg: contents)
        
        messages.append(Message(contents: contents, my_message: true))
    }
    
}
