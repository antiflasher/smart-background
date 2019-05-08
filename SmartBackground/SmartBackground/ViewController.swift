//
//  ViewController.swift
//  SmartBackground
//
//  Created by Anton on 08/05/2019.
//  Copyright © 2019 Anton Lovchikov. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    var badge = UILabel(frame: CGRect(x: 0, y: 0, width: 30, height: 20))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.textContainerInset = UIEdgeInsets.zero
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        
        badge.text = "👍"
        //badge.backgroundColor = .red
        textView.addSubview(badge)
    }

    override func viewDidLayoutSubviews() {
        updateTextViewBackground()
    }
    
    func updateTextViewBackground() {
        let lines = textView.drawSmartBackground(ofColor: .yellow)
        if let lastLine = lines.last {
            //let badgePosition = textView.convert(lastLine, to: view)
            badge.frame.origin = lastLine
        } else {
            badge.isHidden = true
        }
    }
}

extension ViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateTextViewBackground()
    }
}


var ASSOCIATED_BGLAYERS_KEY = "bgLayers"

extension UITextView {
    
    private var bgLayers: [CALayer]? {
        get {
            return objc_getAssociatedObject(self, &ASSOCIATED_BGLAYERS_KEY) as? [CALayer]
        } set {
            if let value = newValue {
                objc_setAssociatedObject(self, &ASSOCIATED_BGLAYERS_KEY, value, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else {
                objc_removeAssociatedObjects(ASSOCIATED_BGLAYERS_KEY)
            }
        }
    }
    
    /// Adds a neat background and returns coordinates of all lines (top right corner)
    func drawSmartBackground(ofColor color: UIColor) -> [CGPoint] {
        
        // Remove prior bgLayers
        for layer in bgLayers ?? [] {
            layer.removeFromSuperlayer()
        }
        
        bgLayers = []
        
        guard let font = self.font else { return [] }
        
        // Determines extra paddings for lines
        let lineInsets = UIEdgeInsets(top: 3, left: 5, bottom: 5, right: 5)
        let cornerRadius: CGFloat = 5
        
        // Storage for lines' top right corner coordinates
        var cornerCordinates = [CGPoint]()
        
        // Get lines and process each
        let lines = self.getLines()
        for (index, line) in lines.enumerated() {
            // Prepare the line and calculate its size
            let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let textSize = NSString(string: text).boundingRect(with: CGSize(width: self.frame.width, height: 1000), options: [], attributes: [NSAttributedString.Key.font: font], context: nil).size
            
            // Save the top right corner coordinate
            cornerCordinates.append(CGPoint(x: textSize.width, y: textSize.height * CGFloat(index)))
            
            // Calculate the bacground frame
            let bgViewH = (textSize.height + lineInsets.top + lineInsets.bottom).rounded(.toNearestOrEven)
            let bgViewW = (textSize.width + lineInsets.left + lineInsets.right).rounded(.toNearestOrEven)
            let bgViewX = -lineInsets.left
            let bgViewY = (textSize.height * CGFloat(index) - lineInsets.top).rounded(.toNearestOrEven)
            
            let bgLayer = CALayer()
            let bgRect = CGRect(x: bgViewX, y: bgViewY, width: bgViewW, height: bgViewH)
            bgLayer.frame = bgRect
            bgLayer.backgroundColor = color.cgColor
            bgLayer.cornerRadius = cornerRadius
            bgLayers?.append(bgLayer)
            self.layer.insertSublayer(bgLayer, at:0)
        }
        
        self.layer.masksToBounds = false
        
        return cornerCordinates
    }
}

extension UITextView {
    func getLines() -> [String] {
        
        /// An empty string's array
        var linesArray = [String]()
        
        guard
            let text = self.text,
            let font = self.font
            else { return linesArray }
        
        let attStr = NSMutableAttributedString(string: text)
        attStr.addAttribute(kCTFontAttributeName as NSAttributedString.Key, value: font, range: NSRange(location: 0, length: attStr.length))
        
        let framesetter: CTFramesetter = CTFramesetterCreateWithAttributedString(attStr as CFAttributedString)
        let path: CGMutablePath = CGMutablePath()
        path.addRect(CGRect(x: 0, y: 0, width: self.frame.size.width, height: 100000), transform: .identity)
        
        let frame: CTFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
        
        guard
            let lines = CTFrameGetLines(frame) as? [Any]
            else { return linesArray }
        
        for (index, line) in lines.enumerated() {
            let lineRef = line as! CTLine
            let lineRange: CFRange = CTLineGetStringRange(lineRef)
            let range = NSRange(location: lineRange.location, length: lineRange.length)
            let lineString: String = (text as NSString).substring(with: range)
            linesArray.append(lineString)
            
            // Check if last line ends with a newline
            if index == lines.count - 1 {
                let claenLine = lineString.trimmingCharacters(in: .newlines)
                if claenLine != lineString {
                    linesArray.append("")
                }
            }
        }
        
        return linesArray
    }
}
