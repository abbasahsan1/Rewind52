//
//  GalleryView.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import SwiftUI

public struct GalleryView: View {
    @ObservedObject private var galleryManager = GalleryManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: RecordedVideoItem?
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    public var body: some View {
        ZStack {
            RewindTheme.deepBlack.ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header Bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("REWIND52 VAULT")
                            .font(RewindTheme.monospaced(18, weight: .black))
                            .foregroundColor(.white)
                            .tracking(1.5)
                        
                        Text("\(galleryManager.items.count) Recordings")
                            .font(RewindTheme.monospaced(11, weight: .bold))
                            .foregroundColor(RewindTheme.vintageAmber)
                    }
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                if galleryManager.items.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "film.stack")
                            .font(.system(size: 54))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("NO RECORDINGS YET")
                            .font(RewindTheme.monospaced(14, weight: .black))
                            .foregroundColor(.white)
                        Text("Record clips across 52 historical eras to build your archive.")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(galleryManager.items) { item in
                                Button(action: { selectedItem = item }) {
                                    GalleryItemCard(item: item)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .sheet(item: $selectedItem) { item in
            VideoDetailView(item: item) {
                galleryManager.deleteItem(item)
            }
        }
    }
}

struct GalleryItemCard: View {
    let item: RecordedVideoItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .bottomLeading) {
                if let thumb = item.thumbnail {
                    Image(uiImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 140)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    Rectangle()
                        .fill(RewindTheme.panelBackground)
                        .frame(height: 140)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.5))
                        )
                }
                
                // Era Badge
                HStack {
                    Text("\(item.year)")
                        .font(RewindTheme.monospaced(10, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RewindTheme.vintageAmber)
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    // Duration
                    let secs = Int(item.duration)
                    Text(String(format: "%02d:%02d", secs / 60, secs % 60))
                        .font(RewindTheme.monospaced(10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                }
                .padding(6)
            }
            
            Text(item.eraName)
                .font(RewindTheme.tactical(12, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text(item.createdAt.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .padding(6)
        .background(RewindTheme.controlButtonBackground)
        .cornerRadius(10)
    }
}
