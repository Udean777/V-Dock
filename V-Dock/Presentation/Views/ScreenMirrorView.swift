//
//  ScreenMirrorView.swift
//  V-Dock
//
//  Created by Sajudin on 25/07/26.
//

import SwiftUI
import AppKit

struct ScreenMirrorView: View {
    let device: Device
    @Environment(AppState.self) var state
    
    @State private var currentFrame: CGImage?
    @State private var frameSize: CGSize = .zero
    @State private var isTouching = false
    @State private var keyboardMonitor: Any?
    
    var body: some View {
        GeometryReader {geo in
            ZStack {
                MirrorFrameView(frame: currentFrame, onSizeChange: { frameSize = $0 })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                if currentFrame == nil {
                    ProgressView("Connecting to \(device.name)...")
                        .foregroundStyle(.secondary)
                }
                
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(dragGesture(viewSize: geo.size))
            }
        }
        .background(Color.black)
        .task {
            let stream = state.startMirrorStream(for: device)
            
            for await img in stream {
                currentFrame = img
            }
        }
        .onDisappear {
            state.stopMirror(for: device)
            
            if let monitor = keyboardMonitor {
                NSEvent.removeMonitor(monitor)
            }
        }
        .onAppear {
            keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) {event in
                let key = Self.adbKey(for: event.keyCode) ?? "KEYCODE_UNKNOWN"
                
                state.sendKey(device: device, key: key)
                
                return nil
            }
        }
    }
    
    private func dragGesture(viewSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged {v in
                let (dx, dy) = scaleTouch(v.location, viewSize: viewSize)
                
                if !isTouching {
                    isTouching = true
                    state.sendTouch(device: device, x: dx, y: dy, action: .down)
                } else {
                    state.sendTouch(device: device, x: dx, y: dy, action: .move)
                }
            }
            .onEnded { v in
                isTouching = false
                let (dx, dy) = scaleTouch(v.location, viewSize: viewSize)
                state.sendTouch(device: device, x: dx, y: dy, action: .up)
            }
    }
    
    private func scaleTouch(_ point: CGPoint, viewSize: CGSize) -> (Int, Int) {
        guard frameSize.width > 0, frameSize.height > 0, viewSize.width > 0, viewSize.height > 0 else {
            return (0, 0)
        }
        
        let scaleX = frameSize.width / viewSize.width
        let scaleY = frameSize.height / viewSize.height
        let x = Int(point.x * scaleX)
        let y = Int(frameSize.height - point.y * scaleY)
        
        return (x, y)
    }
    
    private static func adbKey(for keyCode: UInt16) -> String? {
        switch keyCode {
        case 0: "KEYCODE_1"
        case 1: "KEYCODE_2"
        case 2: "KEYCODE_3"
        case 3: "KEYCODE_4"
        case 4: "KEYCODE_5"
        case 5: "KEYCODE_6"
        case 6: "KEYCODE_7"
        case 7: "KEYCODE_8"
        case 8: "KEYCODE_9"
        case 9: "KEYCODE_0"
        case 12: "KEYCODE_Q"
        case 13: "KEYCODE_W"
        case 14: "KEYCODE_E"
        case 15: "KEYCODE_R"
        case 16: "KEYCODE_T"
        case 17: "KEYCODE_Y"
        case 18: "KEYCODE_U"
        case 19: "KEYCODE_I"
        case 20: "KEYCODE_O"
        case 21: "KEYCODE_P"
        case 36: "KEYCODE_ENTER"
        case 48: "KEYCODE_TAB"
        case 49: "KEYCODE_SPACE"
        case 51: "KEYCODE_DEL"
        case 53: "KEYCODE_ESCAPE"
        case 123: "KEYCODE_DPAD_LEFT"
        case 124: "KEYCODE_DPAD_RIGHT"
        case 125: "KEYCODE_DPAD_DOWN"
        case 126: "KEYCODE_DPAD_UP"
        default: nil
        }
    }
}

struct MirrorFrameView: NSViewRepresentable {
    let frame: CGImage?
    let onSizeChange: (CGSize) -> Void
    
    func makeNSView(context: Context) -> NSImageView {
        let v = NSImageView()
        v.imageScaling = .scaleProportionallyUpOrDown
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor.black.cgColor
        return v
    }
    
    func updateNSView(_ nsView: NSImageView, context: Context) {
        if let cg = frame {
            nsView.image = NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
            onSizeChange(CGSize(width: cg.width, height: cg.height))
        }
    }
}
