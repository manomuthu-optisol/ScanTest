//  OverlayView.swift
//  OptiScanBarcodeReader
//
//  Created by Dineshkumar Kandasamy on 28/02/22.
//  Copyright © 2022 Optisol Business Solution. All rights reserved.
//

import UIKit


public class OverlayView: UIView {
    
    public var objectOverlays: [ObjectOverlay] = []
    private let cornerRadius: CGFloat = 10.0
    private let stringBgAlpha: CGFloat
    = 0.7
    private let lineWidth: CGFloat = 3
    private let stringFontColor = UIColor.white
    private let stringHorizontalSpacing: CGFloat = 13.0
    private let stringVerticalSpacing: CGFloat = 7.0

    public override func draw(_ rect: CGRect) {
        
        SFManager.shared.print(message: "START DRAW OVERLAY", function: .drawRect)

        for objectOverlay in objectOverlays {
            drawBorders(of: objectOverlay)
        }
        
        SFManager.shared.print(message: "FINISH DRAW OVERLAY", function: .drawRect)

    }
    
    
    
     //This method draws the borders of the detected objects.
    
    func drawBorders(of objectOverlay: ObjectOverlay) {
        let path = UIBezierPath(rect: objectOverlay.borderRect)
        
        ///Adding background color to overlay area
        if objectOverlay.color != UIColor.clear {
            objectOverlay.color.withAlphaComponent(0.3).setFill()
            path.fill()
        }

        ///Adding color to ovelay line
        path.lineWidth = lineWidth
        objectOverlay.color.setStroke()
        
        path.stroke()
    }
    
}
