//
//  ScreenMirrorProtocol.swift
//  V-Dock
//
//  Created by Sajudin on 25/07/26.
//

import Foundation
import CoreGraphics

enum TouchAction: String, Sendable {
    case down
    case up
    case move
}

protocol ScreenMirrorProtocol: Sendable {
    func startMirror(device: Device) -> AsyncStream<CGImage>
    func stopMirror(device: Device)
    func sendTouch(device: Device, x: Int, y: Int, action: TouchAction)
    func sendSwipe(device: Device, x1: Int, y1: Int, x2: Int, y2: Int, durationMs: Int)
    func sendKey(device: Device, key: String)
}
