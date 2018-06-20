//
//  ParentConnector.swift
//  Speed(ier) Sloth WatchKit Extension
//
//  Created by Alex Richards on 5/9/18.
//  Copyright © 2018 Alex Richards. All rights reserved.
//

import WatchConnectivity


class ParentConnector : NSObject, WCSessionDelegate {
    
  
    
    // MARK: Properties
    
    var wcSession: WCSession?
    
    var statesToSend = [String]()
    
   
    
    // MARK: Utility methods
    
    func send(state: String, heartBeats: [Double], endDate: Date = Date(), startDate: Date = Date(), distance: String = "", calories: String = "") {
        
        
        if let session = wcSession {
            if session.isReachable {
                session.sendMessage(["State": state, "heartBeats": heartBeats, "endDate": endDate, "startDate": startDate as Any, "distance": distance as Any, "calories": calories as Any], replyHandler: nil)
            }
        } else {
            WCSession.default.delegate = self
            WCSession.default.activate()
            statesToSend.append(state)
        }
    }
    
    // MARK : WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            wcSession = session
            sendPending()
        }
    }
    
    private func sendPending() {
        if let session = wcSession {
            if session.isReachable {
                for state in statesToSend {
                    session.sendMessage(["State": state], replyHandler: nil)
                    //session.transferUserInfo(heartBeats)

                }
                statesToSend.removeAll()
            }
        }
    }
    
}
