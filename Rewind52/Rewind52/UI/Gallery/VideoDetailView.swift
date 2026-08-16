//
//  VideoDetailView.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import SwiftUI
import AVKit
import Photos

public struct VideoDetailView: View {
    public let item: RecordedVideoItem
    public let onDelete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var selectedAspectRatio: ExportAspectRatio = .original
    @State private var isExporting: Bool = false
    @State private var exportSuccessMessage: String?
    @State private var exportErrorMessage: String?
    @State private var showShareSheet: Bool = false
    
    public var body: some View {
        ZStack {
            RewindTheme.deepBlack.ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Top Navigation Bar
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Gallery")
                        }
                        .font(RewindTheme.monospaced(13, weight: .bold))
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text(item.eraName)
                            .font(RewindTheme.tactical(14, weight: .bold))
                            .foregroundColor(.white)
                        Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        onDelete()
                        dismiss()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                // Video Player Container
                if let player = player {
                    VideoPlayer(player: player)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .cornerRadius(12)
                        .padding(.horizontal, 12)
                        .onAppear {
                            player.play()
                        }
                        .onDisappear {
                            player.pause()
                        }
                } else {
                    Rectangle()
                        .fill(RewindTheme.panelBackground)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .cornerRadius(12)
                        .padding(.horizontal, 12)
                }
                
                // Export Controls
                VStack(spacing: 12) {
                    // Aspect Ratio Picker
                    HStack(spacing: 8) {
                        ForEach(ExportAspectRatio.allCases) { ratio in
                            let isSelected = selectedAspectRatio == ratio
                            Button(action: { selectedAspectRatio = ratio }) {
                                Text(ratio.rawValue)
                                    .font(RewindTheme.monospaced(10, weight: isSelected ? .black : .bold))
                                    .foregroundColor(isSelected ? .black : .white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(isSelected ? RewindTheme.vintageAmber : RewindTheme.controlButtonBackground)
                                    .cornerRadius(6)
                            }
                        }
                    }
                    
                    // Save to Photos & Share Buttons
                    HStack(spacing: 14) {
                        Button(action: saveToCameraRoll) {
                            HStack(spacing: 6) {
                                if isExporting {
                                    ProgressView().tint(.black)
                                } else {
                                    Image(systemName: "square.and.arrow.down.fill")
                                    Text("SAVE TO PHOTOS")
                                }
                            }
                            .font(RewindTheme.monospaced(13, weight: .black))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.white)
                            .cornerRadius(10)
                        }
                        .disabled(isExporting)
                        
                        Button(action: { showShareSheet = true }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                                .background(RewindTheme.controlButtonBackground)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    if let successMsg = exportSuccessMessage {
                        Text(successMsg)
                            .font(RewindTheme.monospaced(11, weight: .bold))
                            .foregroundColor(.green)
                    }
                    if let errorMsg = exportErrorMessage {
                        Text(errorMsg)
                            .font(RewindTheme.monospaced(11, weight: .bold))
                            .foregroundColor(.red)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            self.player = AVPlayer(url: item.fileURL)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [item.fileURL])
        }
    }
    
    private func saveToCameraRoll() {
        isExporting = true
        exportSuccessMessage = nil
        exportErrorMessage = nil
        
        PhotoLibraryExporter.shared.exportToPhotoLibrary(
            videoURL: item.fileURL,
            aspectRatio: selectedAspectRatio
        ) { result in
            DispatchQueue.main.async {
                self.isExporting = false
                switch result {
                case .success:
                    self.exportSuccessMessage = "Saved to Camera Roll!"
                case .failure(let error):
                    self.exportErrorMessage = "Export failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
