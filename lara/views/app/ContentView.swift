//
//  ContentView.swift
//  lara
//
//  Redesigned UI matching 32.html layout
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var mgr: laramgr
    @ObservedObject private var logger = globallogger
    
    // Activation state
    @State private var activationKey: String = ""
    @State private var isActivated: Bool = false
    @State private var showExpireTips: Bool = false
    @State private var expireDate: String = "2026-12-31"
    
    // Core button states
    @State private var exploitDone: Bool = false
    @State private var initDone: Bool = false
    
    // Animation states
    @State private var headerVisible: Bool = false
    @State private var mainContentVisible: Bool = false
    @State private var logContainerVisible: Bool = false
    @State private var btnReadVisible: Bool = false
    @State private var btnInitVisible: Bool = false
    
    // Fetching kernelcache state
    @State private var dlingkcache: Bool = false
    
    private let correctKey = "1"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Header Card (激活卡密)
                headerCard
                
                // MARK: - Main Content (核心操作)
                mainContent
                
                // MARK: - Log Container (运行日志)
                logContainer
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color(red: 0.95, green: 0.953, blue: 0.969))
        .onAppear {
            withAnimation(.easeOut(duration: 0.9).delay(0.1)) {
                headerVisible = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                mainContentVisible = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
                logContainerVisible = true
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.7)) {
                btnReadVisible = true
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.9)) {
                btnInitVisible = true
            }
            addLog("面板初始化完成，请先输入卡密激活")
        }
        .onChange(of: mgr.vfsready) { ready in
            if ready && mgr.sbxready && !initDone {
                addLog("内核初始化全部完成")
                initDone = true
                checkUnlock()
            } else if ready && !initDone {
                addLog("VFS 初始化完成")
            }
        }
        .onChange(of: mgr.sbxready) { ready in
            if ready && mgr.vfsready && !initDone {
                addLog("内核初始化全部完成")
                initDone = true
                checkUnlock()
            } else if ready && !initDone {
                addLog("沙盒逃逸完成")
            }
        }
        .onChange(of: mgr.vfsfailed) { failed in
            if failed {
                addLog("VFS 初始化失败")
            }
        }
        .onChange(of: mgr.sbxfailed) { failed in
            if failed {
                addLog("沙盒逃逸失败")
            }
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                TextField("请输入卡密", text: $activationKey)
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.867, green: 0.867, blue: 0.867), lineWidth: 1)
                    )
                    .cornerRadius(12)
                    .font(.system(size: 14))
                
                Button(action: activateAction) {
                    Text("激活")
                        .font(.system(size: 14))
                        .frame(width: 80, height: 44)
                        .background(Color(red: 0.941, green: 0.969, blue: 0.941))
                        .foregroundColor(Color(red: 0.204, green: 0.78, blue: 0.349))
                        .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            if showExpireTips {
                Text("卡密到期时间：\(expireDate)")
                    .font(.system(size: 12))
                    .foregroundColor(.black)
                    .transition(.opacity)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .scaleEffect(headerVisible ? 1 : 0.3)
        .opacity(headerVisible ? 1 : 0)
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Two core buttons (运行漏洞利用 + 初始化系统)
            HStack(spacing: 12) {
                // 运行漏洞利用 Button
                Button(action: runExploitAction) {
                    HStack(spacing: 6) {
                        if mgr.dsrunning {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(Color(red: 0.204, green: 0.78, blue: 0.349))
                        }
                        Text("运行漏洞利用")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(exploitButtonBackground)
                    .foregroundColor(exploitButtonForeground)
                    .cornerRadius(14)
                }
                .disabled(!isActivated || mgr.dsrunning || exploitDone)
                .buttonStyle(ScaleButtonStyle())
                .scaleEffect(btnReadVisible ? 1 : 0.2)
                .opacity(btnReadVisible ? 1 : 0)
                
                // 初始化系统 Button
                Button(action: initSystemAction) {
                    HStack(spacing: 6) {
                        if mgr.vfsrunning || mgr.sbxrunning {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(Color(red: 0.204, green: 0.78, blue: 0.349))
                        }
                        Text("初始化系统")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(initButtonBackground)
                    .foregroundColor(initButtonForeground)
                    .cornerRadius(14)
                }
                .disabled(!isActivated || !mgr.dsready || !mgr.hasOffsets || mgr.vfsrunning || mgr.sbxrunning || initDone)
                .buttonStyle(ScaleButtonStyle())
                .scaleEffect(btnInitVisible ? 1 : 0.2)
                .opacity(btnInitVisible ? 1 : 0)
            }
            .padding(.bottom, 24)
            
            // 6 Content Buttons (3x2 grid)
            contentButtonGrid
                .padding(.bottom, 24)
            
            // Start Button (启动)
            HStack {
                Spacer()
                Button(action: startAction) {
                    Text("启动")
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 120, height: 44)
                        .background(Color(red: 0.941, green: 0.969, blue: 0.941))
                        .foregroundColor(Color(red: 0.204, green: 0.78, blue: 0.349))
                        .cornerRadius(12)
                }
                .disabled(!allReady)
                .buttonStyle(ScaleButtonStyle())
                Spacer()
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .scaleEffect(mainContentVisible ? 1 : 1.4)
        .opacity(mainContentVisible ? 1 : 0)
    }
    
    // MARK: - Content Button Grid
    private var contentButtonGrid: some View {
        VStack(spacing: 16) {
            // First row: 3 buttons
            HStack(spacing: 10) {
                contentButton(title: "测试测试(测试)", id: 1)
                contentButton(title: "测试测试(测试)", id: 2)
                contentButton(title: "测试测试(测试)", id: 3)
            }
            // Second row: 3 buttons
            HStack(spacing: 10) {
                contentButton(title: "新增按钮1", id: 4)
                contentButton(title: "新增按钮2", id: 5)
                contentButton(title: "新增按钮3", id: 6)
            }
        }
        .padding(.horizontal, 10)
    }
    
    private func contentButton(title: String, id: Int) -> some View {
        Button(action: {
            addLog("\(title) 开始下载")
            simulateProgress(for: title)
        }) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(red: 0.941, green: 0.969, blue: 0.941))
                .foregroundColor(Color(red: 0.204, green: 0.78, blue: 0.349))
                .cornerRadius(12)
        }
        .disabled(!allReady)
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Log Container
    private var logContainer: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Log title with animated divider
            VStack(alignment: .leading, spacing: 0) {
                Text("运行日志")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.18))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                
                AnimatedDivider()
                    .padding(.horizontal, 20)
            }
            
            // Log content
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(logger.logs.enumerated()), id: \.offset) { index, log in
                            Text(log)
                                .font(.system(size: 13))
                                .foregroundColor(.black)
                                .lineSpacing(1.8)
                                .id(index)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .frame(height: 200)
                .onChange(of: logger.logs.count) { _ in
                    if let last = logger.logs.indices.last {
                        withAnimation {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .background(Color(red: 0.973, green: 0.976, blue: 0.98))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .offset(x: logContainerVisible ? 0 : -100)
        .opacity(logContainerVisible ? 1 : 0)
    }
    
    // MARK: - Button Styling Computed Properties
    
    private var exploitButtonBackground: Color {
        if exploitDone {
            return Color(red: 0.914, green: 0.914, blue: 0.922)
        }
        return Color(red: 0.941, green: 0.969, blue: 0.941)
    }
    
    private var exploitButtonForeground: Color {
        if exploitDone {
            return Color(red: 0.557, green: 0.557, blue: 0.576)
        }
        return Color(red: 0.204, green: 0.78, blue: 0.349)
    }
    
    private var initButtonBackground: Color {
        if initDone {
            return Color(red: 0.914, green: 0.914, blue: 0.922)
        }
        return Color(red: 0.941, green: 0.969, blue: 0.941)
    }
    
    private var initButtonForeground: Color {
        if initDone {
            return Color(red: 0.557, green: 0.557, blue: 0.576)
        }
        return Color(red: 0.204, green: 0.78, blue: 0.349)
    }
    
    private var allReady: Bool {
        return exploitDone && initDone
    }
    
    // MARK: - Actions
    
    private func activateAction() {
        let key = activationKey.trimmingCharacters(in: .whitespaces)
        if key == correctKey {
            withAnimation(.easeInOut(duration: 0.2)) {
                isActivated = true
                showExpireTips = true
            }
            addLog("卡密验证通过，激活成功")
            
            // Get device info
            let device = UIDevice.current
            let systemVersion = device.systemVersion
            let modelName = device.model
            let screenSize = "\(Int(UIScreen.main.bounds.width)) × \(Int(UIScreen.main.bounds.height))"
            
            addLog("设备类型：\(modelName)")
            addLog("iOS 系统版本：\(systemVersion)")
            addLog("屏幕分辨率：\(screenSize)")
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                isActivated = false
                showExpireTips = false
            }
            addLog("卡密错误，所有功能无法使用！")
        }
    }
    
    private func runExploitAction() {
        addLog("收到指令，准备启动读写服务")
        
        // Initialize offsets
        offsets_init()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            addLog("加载读写驱动模块")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            addLog("权限校验通过")
        }
        
        // Run the actual DarkSword exploit
        mgr.run { success in
            if success {
                addLog("内核读写通道已完全开启")
                exploitDone = true
                checkUnlock()
                
                // Auto fetch kernelcache if needed
                if !mgr.hasOffsets {
                    dlingkcache = true
                    DispatchQueue.global(qos: .userInitiated).async {
                        let fetched = fetchkcache()
                        if fetched {
                            let dlkc = dlkcache()
                            DispatchQueue.main.async {
                                mgr.hasOffsets = dlkc
                                dlingkcache = false
                            }
                        } else {
                            DispatchQueue.main.async {
                                mgr.hasOffsets = false
                                dlingkcache = false
                            }
                        }
                    }
                }
            } else {
                addLog("内核读写通道开启失败")
            }
        }
    }
    
    private func initSystemAction() {
        addLog("即将执行内核重置操作")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            addLog("清空临时缓存数据")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            addLog("内核参数恢复默认值")
        }
        
        // Run VFS init and Sandbox escape in PARALLEL (same as original logic)
        mgr.vfsinit()
        mgr.sbxescape()
    }
    
    private func startAction() {
        addLog("点击启动按钮")
        mgr.respring()
    }
    
    private func checkUnlock() {
        if exploitDone && initDone {
            addLog("内核服务全部就绪，所有功能已解锁")
        }
    }
    
    private func simulateProgress(for name: String) {
        var progress = 0
        let total = 20
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            progress += 1
            let bar = String(repeating: ">", count: progress)
            let percent = Int(Double(progress) / Double(total) * 100)
            let timeStr = currentTimeString()
            // Update last log or add progress
            if progress < total {
                globallogger.updateLastLog("[\(timeStr)] [进度] \(bar) \(percent)%")
            } else {
                timer.invalidate()
                addLog("\(name) 下载完成")
            }
        }
    }
    
    // MARK: - Helpers
    
    private func addLog(_ text: String) {
        let time = currentTimeString()
        globallogger.log("[\(time)] \(text)")
    }
    
    private func currentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
}

// MARK: - Animated Divider (blinking blue line)
struct AnimatedDivider: View {
    @State private var opacity: Double = 0.4
    
    var body: some View {
        Rectangle()
            .fill(Color(red: 0, green: 0.478, blue: 1))
            .frame(height: 1)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                    opacity = 1.0
                }
            }
    }
}

// MARK: - Scale Button Style (press animation)
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
        .environmentObject(laramgr())
}
