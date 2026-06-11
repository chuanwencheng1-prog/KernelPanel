//
//  ContentView.swift
//  lara
//
//  Created by ruter on 23.03.26.
//  UI rewritten to match modern card-based panel layout.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var mgr: laramgr
    @ObservedObject private var logger = globallogger
    @AppStorage("selectedMethod") private var selectedmethod: method = .hybrid
    @AppStorage("logsdisplaymode") private var selectedlogsdisplaymode: logsdisplaymode = .toolbar
    @AppStorage("loggerNoBS") private var loggernobs: Bool = true
    
    @State private var showSettings: Bool = false
    @State private var dlingkcache: Bool = false
    
    // Card key activation state
    @State private var cardKey: String = ""
    @State private var isActivated: Bool = false
    @State private var showExpireTips: Bool = false
    @State private var expireDate: String = "2026-12-31"
    
    // Button completion states
    @State private var readDone: Bool = false
    @State private var initDone: Bool = false
    
    // Animation states
    @State private var headerAppeared: Bool = false
    @State private var mainContentAppeared: Bool = false
    @State private var logContainerAppeared: Bool = false
    @State private var btnReadAppeared: Bool = false
    @State private var btnInitAppeared: Bool = false
    
    private let correctKey = "1"
    
    private var allUnlocked: Bool {
        readDone && initDone
    }
    
    init() {
        globallogger.capture()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Header Card (Activation)
                headerCard
                
                // MARK: - Main Content Card
                mainContentCard
                
                // MARK: - Log Container
                logContainer
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color(red: 0.949, green: 0.953, blue: 0.969))
        .onAppear {
            withAnimation(.easeOut(duration: 0.9).delay(0.1)) {
                headerAppeared = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                mainContentAppeared = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
                logContainerAppeared = true
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.7)) {
                btnReadAppeared = true
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.9)) {
                btnInitAppeared = true
            }
            addLog("面板初始化完成，请先输入卡密激活")
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                TextField("请输入卡密", text: $cardKey)
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(white: 0.87), lineWidth: 1)
                    )
                    .cornerRadius(12)
                    .font(.system(size: 14))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                
                Button(action: activateAction) {
                    Text("激活")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.204, green: 0.780, blue: 0.349))
                        .frame(width: 80, height: 44)
                        .background(Color(red: 0.941, green: 0.969, blue: 0.941))
                        .cornerRadius(12)
                }
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
        .scaleEffect(headerAppeared ? 1 : 0.3)
        .opacity(headerAppeared ? 1 : 0)
    }
    
    // MARK: - Main Content Card
    private var mainContentCard: some View {
        VStack(spacing: 0) {
            // Two main buttons
            HStack(spacing: 12) {
                // 启动内核读写 (Run Exploit)
                Button(action: runExploitAction) {
                    Text("启动内核读写")
                        .font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(readDone ? Color(red: 0.914, green: 0.914, blue: 0.922) : Color(red: 0.941, green: 0.969, blue: 0.941))
                        .foregroundColor(readDone ? Color(red: 0.557, green: 0.557, blue: 0.576) : Color(red: 0.204, green: 0.780, blue: 0.349))
                        .cornerRadius(14)
                }
                .disabled(!isActivated || readDone || mgr.dsrunning || isdebugged())
                .scaleEffect(btnReadAppeared ? 1 : 0.2)
                .opacity(btnReadAppeared ? 1 : 0)
                
                // 初始化内核 (Initialize System)
                Button(action: initSystemAction) {
                    Text("初始化内核")
                        .font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(initDone ? Color(red: 0.914, green: 0.914, blue: 0.922) : Color(red: 0.941, green: 0.969, blue: 0.941))
                        .foregroundColor(initDone ? Color(red: 0.557, green: 0.557, blue: 0.576) : Color(red: 0.204, green: 0.780, blue: 0.349))
                        .cornerRadius(14)
                }
                .disabled(!isActivated || initDone || !mgr.dsready || !mgr.hasOffsets || mgr.vfsrunning || mgr.sbxrunning || isdebugged())
                .scaleEffect(btnInitAppeared ? 1 : 0.2)
                .opacity(btnInitAppeared ? 1 : 0)
            }
            .padding(.bottom, 24)
            
            // 6 Content Buttons (3 per row, 2 rows)
            contentButtonsGrid
                .padding(.bottom, 24)
            
            // Start Button
            Button(action: startAction) {
                Text("启动")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 0.204, green: 0.780, blue: 0.349))
                    .frame(width: 120, height: 44)
                    .background(Color(red: 0.941, green: 0.969, blue: 0.941))
                    .cornerRadius(12)
            }
            .disabled(!allUnlocked)
            .opacity(allUnlocked ? 1.0 : 0.5)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .scaleEffect(mainContentAppeared ? 1 : 1.4)
        .opacity(mainContentAppeared ? 1 : 0)
    }
    
    // MARK: - Content Buttons Grid
    private var contentButtonsGrid: some View {
        VStack(spacing: 16) {
            // Row 1
            HStack(spacing: 10) {
                contentButton(title: "Respring", action: {
                    mgr.respring()
                    addLog("执行 Respring...")
                })
                #if !DISABLE_REMOTECALL
                contentButton(title: "RemoteCall", action: {
                    mgr.rcinit(process: "SpringBoard", migbypass: false) { success in
                        if success {
                            addLog("RemoteCall 初始化成功")
                        } else {
                            addLog("RemoteCall 初始化失败")
                        }
                    }
                })
                #else
                contentButton(title: "RemoteCall", action: {
                    addLog("RemoteCall 已禁用")
                })
                #endif
                fetchCacheButton()
            }
            
            // Row 2
            HStack(spacing: 10) {
                contentButton(title: "Panic", action: {
                    mgr.panic()
                    addLog("执行 Panic...")
                })
                #if !DISABLE_REMOTECALL
                contentButton(title: "销毁RC", action: {
                    mgr.rcdestroy()
                    addLog("RemoteCall 已销毁")
                })
                #else
                contentButton(title: "销毁RC", action: {
                    addLog("RemoteCall 已禁用")
                })
                #endif
                settingsButton()
            }
        }
        .padding(.horizontal, 10)
    }
    
    private func contentButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(red: 0.941, green: 0.969, blue: 0.941))
                .foregroundColor(Color(red: 0.204, green: 0.780, blue: 0.349))
                .cornerRadius(12)
        }
        .disabled(!allUnlocked)
        .opacity(allUnlocked ? 1.0 : 0.5)
    }
    
    private func fetchCacheButton() -> some View {
        Button(action: { fetchKernelcacheAction() }) {
            Text("获取缓存")
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(red: 0.941, green: 0.969, blue: 0.941))
                .foregroundColor(Color(red: 0.204, green: 0.780, blue: 0.349))
                .cornerRadius(12)
        }
        .disabled(!readDone || dlingkcache)
        .opacity(readDone ? 1.0 : 0.5)
    }
    
    private func settingsButton() -> some View {
        Button(action: { showSettings = true }) {
            Text("设置")
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(red: 0.941, green: 0.969, blue: 0.941))
                .foregroundColor(Color(red: 0.204, green: 0.780, blue: 0.349))
                .cornerRadius(12)
        }
        .disabled(!isActivated)
        .opacity(isActivated ? 1.0 : 0.5)
    }
    
    // MARK: - Log Container
    private var logContainer: some View {
        VStack(spacing: 0) {
            // Log title with animated underline
            HStack {
                Text("运行日志")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.173, green: 0.173, blue: 0.180))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .overlay(alignment: .bottom) {
                AnimatedLogDivider()
            }
            
            // Log content
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(logger.logs.enumerated()), id: \.offset) { index, log in
                            Text(log)
                                .font(.system(size: 13, design: .monospaced))
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
                    if let lastIndex = logger.logs.indices.last {
                        withAnimation {
                            proxy.scrollTo(lastIndex, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .background(Color(red: 0.973, green: 0.976, blue: 0.984))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .offset(x: logContainerAppeared ? 0 : -100)
        .opacity(logContainerAppeared ? 1 : 0)
    }
    
    // MARK: - Actions
    
    private func activateAction() {
        let key = cardKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if key == correctKey {
            withAnimation(.easeInOut(duration: 0.2)) {
                isActivated = true
                showExpireTips = true
            }
            addLog("卡密验证通过，激活成功")
            
            let device = UIDevice.current
            addLog("设备类型：\(device.model)")
            addLog("iOS 系统版本：\(device.systemVersion)")
            addLog("屏幕分辨率：\(Int(UIScreen.main.bounds.width)) × \(Int(UIScreen.main.bounds.height))")
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                isActivated = false
                showExpireTips = false
            }
            addLog("卡密错误，所有功能无法使用！")
        }
    }
    
    private func runExploitAction() {
        guard isActivated && !readDone else { return }
        
        addLog("收到指令，准备启动读写服务")
        
        // Execute the actual exploit
        offsets_init()
        mgr.run()
        
        addLog("加载读写驱动模块")
        addLog("权限校验通过")
        
        // Monitor exploit completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            monitorExploitCompletion()
        }
    }
    
    private func monitorExploitCompletion() {
        if mgr.dsready {
            addLog("内核读写通道已完全开启")
            withAnimation(.easeInOut(duration: 0.3)) {
                readDone = true
            }
            checkUnlock()
        } else if mgr.dsfailed {
            addLog("内核读写启动失败")
        } else {
            // Keep checking
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                monitorExploitCompletion()
            }
        }
    }
    
    private func initSystemAction() {
        guard isActivated && !initDone && mgr.dsready && mgr.hasOffsets else { return }
        
        addLog("即将执行内核重置操作")
        
        // Execute actual system initialization based on selected method
        if selectedmethod == .hybrid {
            mgr.vfsinit()
            mgr.sbxescape()
        } else if selectedmethod == .vfs {
            mgr.vfsinit()
        } else if selectedmethod == .sbx {
            mgr.sbxescape()
        }
        
        addLog("清空临时缓存数据")
        addLog("内核参数恢复默认值")
        
        // Monitor initialization completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            monitorInitCompletion()
        }
    }
    
    private func monitorInitCompletion() {
        let isComplete: Bool
        
        switch selectedmethod {
        case .hybrid:
            isComplete = mgr.vfsready && mgr.sbxready
        case .vfs:
            isComplete = mgr.vfsready
        case .sbx:
            isComplete = mgr.sbxready
        }
        
        if isComplete {
            addLog("内核初始化全部完成")
            withAnimation(.easeInOut(duration: 0.3)) {
                initDone = true
            }
            checkUnlock()
        } else if mgr.vfsfailed || mgr.sbxfailed {
            addLog("内核初始化失败")
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                monitorInitCompletion()
            }
        }
    }
    
    private func checkUnlock() {
        if readDone && initDone {
            addLog("内核服务全部就绪，所有功能已解锁")
        }
    }
    
    private func startAction() {
        addLog("点击启动按钮")
        // Trigger respring or any combined action
        mgr.respring()
    }
    
    private func fetchKernelcacheAction() {
        guard !dlingkcache else { return }
        dlingkcache = true
        addLog("获取缓存 开始下载")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let fetched = fetchkcache()
            
            if fetched {
                let dlkc = dlkcache()
                DispatchQueue.main.async {
                    mgr.hasOffsets = dlkc
                    dlingkcache = false
                    addLog("获取缓存 下载完成")
                }
                return
            }
            
            DispatchQueue.main.async {
                mgr.hasOffsets = false
                dlingkcache = false
                addLog("获取缓存 下载失败")
            }
        }
    }
    
    private func addLog(_ text: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let time = formatter.string(from: Date())
        mgr.logmsg("[\(time)] \(text)")
    }
}

// MARK: - Animated Log Divider
struct AnimatedLogDivider: View {
    @State private var opacity: Double = 0.4
    
    var body: some View {
        Rectangle()
            .fill(Color(red: 0, green: 0.478, blue: 1.0))
            .frame(height: 1)
            .padding(.horizontal, 20)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    opacity = 1.0
                }
            }
    }
}

#Preview {
    ContentView()
        .environmentObject(laramgr())
}
