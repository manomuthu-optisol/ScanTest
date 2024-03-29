//
//  LongDistance.swift
//  ScanflowBarcodeReader
//
//  Copyright © 2022 Optisol Business Solution. All rights reserved.
//

import Foundation
import UIKit


class LongDistance {
    
    private static var minUpscaleWidthQR = 13.0
    private static var minUpscaleHeightQR = 9.0
    private static var minUpscaleWidthBarcode = 64.0
    private static var minUpscaleHeightBarcode = 16.0
    
    func isLongDistanceQRImage(
        cropImageWidth: CGFloat,
        cropImageHeight: CGFloat,
        previewWidth: CGFloat,
        previewHeight: CGFloat
    ) -> Bool {
        SFManager.shared.print(message: "dist width min \(((cropImageWidth / previewWidth) * 100.0).rounded())", function: .longDistance)
        SFManager.shared.print(message: "dist height min \(((cropImageHeight / previewHeight) * 100).rounded())", function: .longDistance)

        return (((cropImageWidth / previewWidth) * 100.0).rounded() < LongDistance.minUpscaleWidthQR) || (((cropImageHeight / previewHeight) * 100).rounded() < LongDistance.minUpscaleHeightQR)
    }

    func isLongDistanceBarcodeImage(
        cropImageWidth: CGFloat,
        cropImageHeight: CGFloat,
        previewWidth: CGFloat,
        previewHeight: CGFloat
    ) -> Bool {
        SFManager.shared.print(message: "dist bar width min \(((cropImageWidth / previewWidth) * 100.0).rounded())", function: .longDistance)
        SFManager.shared.print(message: "dist bar height min \(((cropImageHeight / previewHeight) * 100).rounded())", function: .longDistance)

        return (((cropImageWidth / previewWidth) * 100).rounded() < LongDistance.minUpscaleWidthBarcode) || (((cropImageHeight / previewHeight) * 100).rounded() < LongDistance.minUpscaleHeightBarcode)
    }
    
}

