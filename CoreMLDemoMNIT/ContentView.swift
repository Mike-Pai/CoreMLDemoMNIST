//
//  ContentView.swift
//  CoreMLDemo
//
//  Created by 白謹瑜 on 2024/10/6.
//

import SwiftUI
import PhotosUI
import CoreML
//import Vision

struct ContentView: View {
    @State var prediction = ""
    @State private var selectedItem : PhotosPickerItem?
    @State var selectedImage : UIImage? = UIImage(named: "testInput")
    var body: some View {
        VStack {
            if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 300)
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 300)
                                .foregroundColor(.gray)
                        }
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("Select a photo", systemImage: "photo")
            }
            .tint(.purple)
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .onChange(of: selectedItem) {
                if let newItem = selectedItem {
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            selectedImage = image
                        }
                    }
                }
            }
            HStack{
                Button {
                    if let image = selectedImage{
                        prediction = modelPrediction(image: image)
                    }else{
                        prediction = "錯誤"
                    }
                } label: {
                    Text("預測")
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                }
                .background{
                    Capsule()
                        .foregroundStyle(selectedImage == nil ? Color.gray : Color.blue)
                    
                }
                .disabled(selectedImage == nil ? true : false)
                
                Text("Prediction: \(prediction)")
            }
        }
        .padding()
    }
    
    func modelPrediction(image: UIImage)->String{
        let cvImage = buffer(from: image)
        guard let model = try? MNISTClassifier(configuration: .init()) else{
            print("Load fail")
            return "error"
        }
        let pred = try! model.prediction(image: cvImage!)
        return pred.classLabel.description
    }
    func buffer(from image: UIImage) -> CVPixelBuffer? {
        let width = 28
        let height = 28
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_OneComponent8, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        //        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let grayColorSpace = CGColorSpaceCreateDeviceGray()
        //        let context = CGContext(data: pixelData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        guard let context = CGContext(data: pixelData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: grayColorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
            return nil
        }
        
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context)
        //        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        image.draw(in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
}

#Preview {
    ContentView()
}

