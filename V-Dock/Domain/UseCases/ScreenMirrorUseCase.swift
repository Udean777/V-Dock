//
//  ScreenMirrorUseCase.swift
//  V-Dock
//
//  Created by Sajudin on 25/07/26.
//

import Foundation
import CoreGraphics

final class ScreenMirrorUseCase: Sendable {
    private let androidMirror: ScreenMirrorProtocol
    
    init(androidMirror: ScreenMirrorProtocol) {
        self.androidMirror = androidMirror
    }
    
    func startMirror(device: Device) -> AsyncStream<CGImage> {
        androidMirror.startMirror(device: device)
    }
    
    func stopMirror(device: Device) {
        androidMirror.stopMirror(device: device)
    }
    
    func sendTouch(device: Device, x: Int, y: Int, action: TouchAction) {
        androidMirror.sendTouch(device: device, x: x, y: y, action: action)
    }
    
    func sendSwipe(device: Device, x1: Int, y1: Int, x2: Int, y2: Int, durationMs: Int) {
        androidMirror.sendSwipe(device: device, x1: x1, y1: y1, x2: x2, y2: y2, durationMs: durationMs)
    }
    
    func sendKey(device: Device, key: String) {
        androidMirror.sendKey(device: device, key: key)
    }
}
