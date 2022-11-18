//
//  DocksChat.swift
//  Docks
//
//  Created by david on 11/16/22.
//

import Foundation
import os
    
/**
  * Struct representing a message for UI display purposes
 */
struct UIChatMessage : Identifiable {
    var contents : String
    var nickname : String // nickname that sent this
    // flag denoting that this message was sent by my user
    var my_message : Bool
    var timestamp : NSDate
    var id: String {UUID().uuidString}
}

/**
  * Struct representing a message for network transit
 */
struct NetworkChatMessage {
    var contents : String
    var nickname : String // nickname that sent this
    // flag denoting that this message was sent by my user
    var SenderUID : String
    var timestamp: TimeInterval
    
    func to_network_format() -> String {
        return [SenderUID, String(timestamp), nickname, contents].joined(separator: ",")
    }
    
    static func from_network_format(packet: String) -> NetworkChatMessage {
        let tokens = packet.components(separatedBy: ",")
        return NetworkChatMessage(
                contents: tokens[3...].joined(separator: ","),
                nickname: tokens[2],
                SenderUID: tokens[0],
                timestamp: TimeInterval(tokens[1]) ?? TimeInterval(0)
        )
    }
    
}

class DocksChat : NSObject, ObservableObject {
    @Published var messages : [UIChatMessage] = []
    var deviceManager : DocksDevice
    var myUUID : String
    var myNickname : String
    var knownMessages : Set<String> = []
    var log = Logger()
    
    override init() {
        deviceManager = DocksDevice()
        myUUID = deviceManager.get_id()
        // initial nickname will be my UUID
        myNickname = myUUID
        super.init()
        
        deviceManager.register_receive_callback(callback_fn: receiveMessage(networkMessage:))
    }
    
    
    /**
     * Verifies that a nickname is alphanumeric and sets it accordingly. Returns true on success
     */
    func verifyAndSetNickname(nickname : String) -> Bool {
        log.info("Attempting to change nickname to \"\(nickname)\"")
        if (!nickname.isEmpty && nickname.range(of:".*,.*", options: .regularExpression, range: nil, locale: nil) == nil) {
            // do not allow commas
            self.myNickname = nickname;
            return true
        }
        
        return false
    }
    
    /**
     *  Adds a message to the list of seen messages if it hasn't been seen before
     *  @return whether the message was unseen
     */
    func addMessageIfUnseen(SenderUID: String, timestamp: TimeInterval) -> Bool {
        let messageID = SenderUID + String(timestamp)
        return knownMessages.insert(messageID).inserted
    }
    
    func sendMessage(contents : String) {
        let networkMessage = NetworkChatMessage(
            contents: contents,
            nickname: myNickname,
            SenderUID: myUUID,
            timestamp: NSDate().timeIntervalSince1970
        )
        
        deviceManager.send(msg: networkMessage.to_network_format())
        receiveMessage(networkMessage: networkMessage.to_network_format())
    }
    
    func receiveMessage(networkMessage: String) {
          let parsedNetworkMessage = NetworkChatMessage.from_network_format(packet: networkMessage)
          let uiMessage = UIChatMessage(
              contents: parsedNetworkMessage.contents,
              nickname: parsedNetworkMessage.nickname,
              my_message: parsedNetworkMessage.SenderUID == myUUID,
              timestamp: NSDate(timeIntervalSince1970: parsedNetworkMessage.timestamp)
          )
          
          if (addMessageIfUnseen(SenderUID: parsedNetworkMessage.SenderUID, timestamp: parsedNetworkMessage.timestamp)) {
              deviceManager.send(msg: networkMessage)
              messages.append(uiMessage)
          }
      }
    
}
