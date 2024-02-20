//
//  ApplicationState.swift
//  Rudder
//
//  Created by Pallab Maiti on 29/01/24.
//  Copyright © 2024 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

protocol ApplicationStateProtocol {
    var trackApplicationStateMessage: ((ApplicationStateMessage) -> Void) { get set }
    var refreshSessionIfNeeded: (() -> Void) { get set }
    
    func didEnterBackground(notification: NSNotification)
    func willEnterForeground(notification: NSNotification)
    func didFinishLaunching(notification: NSNotification)
    func didBecomeActive(notification: NSNotification)
}

extension ApplicationStateProtocol {
    func didEnterBackground(notification: NSNotification) { }
    func willEnterForeground(notification: NSNotification) { }
    func didFinishLaunching(notification: NSNotification) { }
    func didBecomeActive(notification: NSNotification) { }
}

enum NotificationName {
    case didEnterBackground
    case willEnterForeground
    case didFinishLaunching
    case didBecomeActive
    case unknown
}

struct ApplicationStateMessage {
    enum State {
        case backgrounded
        case opened
        case installed
        case updated
        
        var eventName: String {
            switch self {
            case .backgrounded:
                return "Application Backgrounded"
            case .opened:
                return "Application Opened"
            case .installed:
                return "Application Installed"
            case .updated:
                return "Application Updated"
            }
        }
    }
    let state: State
    let properties: TrackProperties?
    
    init(state: State, properties: TrackProperties? = nil) {
        self.state = state
        self.properties = properties
    }
}

class ApplicationState {
    let notificationCenter: NotificationCenter
    let notifications: [Notification.Name]
    var application: ApplicationStateProtocol
    var trackApplicationStateMessage: ((ApplicationStateMessage) -> Void) = { _  in }
    var refreshSessionIfNeeded: (() -> Void) = { }
    
    required init(
        notificationCenter: NotificationCenter,
        application: ApplicationStateProtocol,
        notifications: [Notification.Name]
    ) {
        self.notificationCenter = notificationCenter
        self.application = application
        self.notifications = notifications
        self.application.trackApplicationStateMessage = { applicationStateMessage in
            self.trackApplicationStateMessage(applicationStateMessage)
        }
        self.application.refreshSessionIfNeeded = {
            self.refreshSessionIfNeeded()
        }
    }
    
    func observeNotifications() {
        notifications.forEach({
            notificationCenter.addObserver(self, selector: #selector(observe(notification:)), name: $0, object: nil)
        })
    }
    
    @objc
    func observe(notification: NSNotification) {
        switch notification.name.convert() {
        case .didEnterBackground:
            application.didEnterBackground(notification: notification)
        case .willEnterForeground:
            application.willEnterForeground(notification: notification)
        case .didFinishLaunching:
            application.didFinishLaunching(notification: notification)
        case .didBecomeActive:
            application.didBecomeActive(notification: notification)
        case .unknown:
            break
        }
    }
}
