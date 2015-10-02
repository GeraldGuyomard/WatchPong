//
//  GameController.swift
//  WatchPong WatchKit Extension
//
//  Created by Gérald Guyomard on 9/13/15.
//  Copyright © 2015 Gérald Guyomard. All rights reserved.
//

import WatchKit
import Foundation

extension CGPoint
{
    func norm() -> CGFloat
    {
        return CGFloat(sqrtf(Float((x * x) + (y * y))));
    }
    
    func normalizedVector() -> CGPoint
    {
        let l = norm();
        if l == 0
        {
            return CGPointMake(0, 0);
        }
        
        return CGPointMake(x / l, y / l);
    }
    
    func add(other: CGPoint) -> CGPoint
    {
        return CGPointMake(x + other.x, y + other.y)
    }
    
    func mul(f : CGFloat) -> CGPoint
    {
        return CGPointMake(x * f, y * f);
    }
}

class GameController: WKInterfaceController
{
    @IBOutlet var image : WKInterfaceImage?
    @IBOutlet var myPicker: WKInterfacePicker?
    @IBOutlet var padContainer : WKInterfaceGroup?
 
    var    m_BackBuffer : UnsafeMutablePointer<Void> = UnsafeMutablePointer<Void>();
    var    m_CGContext : CGContext?;
    var    m_ContextSize : CGSize = CGSizeMake(0, 0);
    
    var    m_Image : CGImage?;
    
    var     m_BallImage : UIImage?
    var     m_BallSize : CGSize = CGSizeMake(0, 0)
    var     m_BallPosition : CGPoint = CGPointMake(0, 0)
    var     m_BallDirection : CGPoint = CGPointMake(0, 0)
    var     m_BallSpeed : CGFloat = 0;
    
    var     m_PadPosition : CGFloat = 0;
    var     m_PadHeight : CGFloat = 0;
    
    var     m_BrickImage : UIImage?
    var     m_BrickImageSize : CGSize = CGSize(width: 0, height: 0)
    
    var     m_MustStartGame = true;
    var     m_Lost : Bool = false;
    
    var     m_RenderTimer : NSTimer?
    var     m_PreviousRenderTime: NSDate?
    var     m_dT : NSTimeInterval = 0.0

    override func awakeWithContext(context: AnyObject?)
    {
        super.awakeWithContext(context)
        
        let padImage = UIImage(named: "pad.png")
        
        m_PadHeight = padImage!.size.height * padImage!.scale
        
        initContext()
        
        var items = [WKPickerItem]();
        
        let item = WKPickerItem()
        item.title = " ";
        
        for _ in 1...GameController.kNbItems
        {
            items.append(item)
        }
        
        if let picker = self.myPicker
        {
            picker.setItems(items)
        }
        
        m_BallImage = UIImage(named:"ball.png")
        m_BallSize = m_BallImage!.size
        
        m_BallSize.width *= m_BallImage!.scale
        m_BallSize.height *= m_BallImage!.scale
        
        m_BrickImage = UIImage(named: "brick-red.png")
        m_BrickImageSize = m_BrickImage!.size

        m_BrickImageSize.width *= m_BrickImage!.scale
        m_BrickImageSize.height *= m_BrickImage!.scale
        
        

    }

    override func willActivate()
    {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        if m_RenderTimer == nil
        {
            let t : NSTimeInterval = 1.0 / 20.0
            
            m_RenderTimer = NSTimer.scheduledTimerWithTimeInterval(t, target:self, selector:Selector("onRenderTimer:"), userInfo:nil, repeats:true)
            m_RenderTimer = nil
        }
        
        self.myPicker!.focus()
        if (m_MustStartGame)
        {
            m_MustStartGame = false
            startGame()
        }
    }

    override func didDeactivate()
    {
        if let timer = m_RenderTimer
        {
            timer.invalidate()
            m_RenderTimer = nil
        }
        
        super.didDeactivate()
    }

    @IBAction func onQuit()
    {
        self.pushControllerWithName("MainMenuController", context: nil)
    }
    
    @IBAction func pickerAction(iIndex: NSInteger)
    {
        setPadPosition(iIndex)
    }
    
    static let kHeight : CGFloat = 170.0
    static let kNbItems : Int = 40
    //const unsigned int kNbItems = kTotalHeight;

    func initContext()
    {
        m_ContextSize = CGSizeMake(142, GameController.kHeight)
        
        let bufferSize = NSInteger(m_ContextSize.width) * NSInteger(m_ContextSize.height) * 4
        m_BackBuffer = malloc(bufferSize)
        //memset(m_BackBuffer, 0xFF, bufferSize);
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        
        m_CGContext = CGBitmapContextCreate(m_BackBuffer, Int(m_ContextSize.width), Int(m_ContextSize.height), 8, Int(m_ContextSize.width) * 4, rgbColorSpace, CGImageAlphaInfo.NoneSkipLast.rawValue)

    }
    
    func processBehaviors()
    {
        if m_Lost
        {
            return
        }
    
        if m_dT > 1
        {
            var a : Int
            a = 1;
        }
        
        let dV = m_BallSpeed * CGFloat(m_dT)
        let v = m_BallDirection.mul(dV);
        print("v=\(v.x),  \(v.y)")
        
        m_BallPosition = m_BallPosition.add(v)
   
        let maxX = m_ContextSize.width - m_BallSize.width
        
        // make it bounce if hitting on wall
        if m_BallPosition.x < 0
        {
            m_BallPosition.x = 0
            m_BallDirection.x = -m_BallDirection.x;
        }
        else if m_BallPosition.x >= maxX
        {
            // make sure it bounced on the pad
            let minBall =  m_BallPosition.y
            let maxBall = m_BallPosition.y + m_BallSize.height
            
            let kPadPos = m_PadPosition * m_ContextSize.height
            let minPad = kPadPos
            let maxPad = kPadPos + m_PadHeight
            
            if (maxBall < minPad) || (minBall > maxPad)
            {
                m_BallPosition.x = m_ContextSize.width / 2
                m_BallPosition.y = m_ContextSize.height / 2
                m_Lost = true
            
                WKInterfaceDevice.currentDevice().playHaptic(.Failure)
                
                if let timer = m_RenderTimer
                {
                    timer.invalidate()
                    m_RenderTimer = nil
                }
            }
            else
            {
                m_BallPosition.x = maxX - 1
                
                // Bounce
                WKInterfaceDevice.currentDevice().playHaptic(.Retry)
                
                m_BallSpeed += 15
                if m_BallSpeed > 120
                {
                    m_BallSpeed = 120
                }
            }
    
            m_BallDirection.x = -m_BallDirection.x
        }
    
        let maxY = m_ContextSize.height - m_BallSize.height
        
        if m_BallPosition.y < 0
        {
            m_BallPosition.y = 0
            m_BallDirection.y = -m_BallDirection.y
        }
        else if m_BallPosition.y >= maxY
        {
            m_BallPosition.y = maxY - 1
            m_BallDirection.y = -m_BallDirection.y
        }
    }
    
    func drawImage(iImage:UIImage!, atPosition iPos:CGPoint)
    {
        let img = iImage.CGImage
    
        let rect = CGRect(x:iPos.x, y:iPos.y, width:CGFloat(CGImageGetWidth(img)), height:CGFloat(CGImageGetHeight(img)))
    
        CGContextDrawImage(m_CGContext, rect, img)
    }
    
    func renderBricks()
    {
        var pt = CGPointMake(16, 0);
        
        for _ in 1...3
        {
            drawImage(m_BrickImage, atPosition: pt)
            pt.y += 2 * m_BrickImageSize.height
        }
        
        pt = CGPointMake(16 + 2 * m_BrickImageSize.width, m_BrickImageSize.height)
        for _ in 1...3
        {
            drawImage(m_BrickImage, atPosition: pt)
            pt.y += 2 * m_BrickImageSize.height
        }
    }
    
    func render()
    {
        let rect = CGRect(x: 0, y: 0, width: m_ContextSize.width, height: m_ContextSize.height)
    
        if m_Lost
        {
            CGContextSetRGBFillColor(m_CGContext, 1, 0, 0, 1)
            CGContextFillRect(m_CGContext, rect)
        }
        else
        {
            //CGContextClearRect(m_CGContext, rect)
            let size : Int = Int(m_ContextSize.width) * Int(m_ContextSize.height) * 4
            memset(m_BackBuffer, 0, size)
        }
    
        drawImage(m_BallImage, atPosition:m_BallPosition)
        
        renderBricks()
    }
    
    func presentRender()
    {
        if let img = self.image
        {
            let i = self.backBufferImage()
            img.setImage(i)
        }
    }
    
    func backBufferImage() -> UIImage?
    {
        if (m_Image == nil)
        {
            let bufferSize : Int = Int(m_ContextSize.width) * Int(m_ContextSize.height) * 4
            let provider = CGDataProviderCreateWithData(nil, m_BackBuffer, bufferSize, nil)
    
            let bitsPerComponent = CGBitmapContextGetBitsPerComponent (m_CGContext)
            let bitsPerPixel = CGBitmapContextGetBitsPerPixel(m_CGContext)
            let bytesPerRow = CGBitmapContextGetBytesPerRow(m_CGContext)
            let colorSpace = CGBitmapContextGetColorSpace(m_CGContext)
            
            m_Image = CGImageCreate(Int(m_ContextSize.width), Int(m_ContextSize.height),
                                    bitsPerComponent,
                                    bitsPerPixel,
                                    bytesPerRow,
                                    colorSpace,
                                    CGBitmapInfo(rawValue: CGImageAlphaInfo.None.rawValue),
                                    provider,
                                    nil,
                                    false,
                                    .RenderingIntentDefault)
        }
        
        return UIImage(CGImage: m_Image!)
    }
    
    func startGame()
    {
        m_PadPosition = 0.5
        let kInitialPos = GameController.kNbItems / 2
        self.myPicker!.setSelectedItemIndex(kInitialPos)
        self.setPadPosition(kInitialPos)
    
        m_BallPosition.x = m_ContextSize.width - (2 * m_BallSize.width)
        m_BallPosition.y = (m_ContextSize.height - m_BallSize.height) / 2
    
        m_BallDirection = CGPoint(x:-0.6, y:-1.0).normalizedVector()
        m_BallSpeed = 60.0
    
        m_Lost = false
    }
    
    func onRenderTimer(timer:NSTimer)
    {
        let startT = NSDate()
        if let previousTime = m_PreviousRenderTime
        {
            let timerT = startT.timeIntervalSinceDate(previousTime)
            print("timer interval=\(timerT * 1000.0) ms")
            
            m_dT = startT.timeIntervalSinceDate(previousTime)
        }
        
        m_PreviousRenderTime = startT;
        
        self.processBehaviors()
        self.render()
        self.presentRender()
        
        let  endT = NSDate()
        let duration = endT.timeIntervalSinceDate(startT);

        print("frame:\(duration * 1000.0) ms")
    }
    
    func totalHeight() -> CGFloat
    {
        return GameController.kHeight - m_PadHeight
    }
    
    func setPadPosition(index:Int)
    {
        m_PadPosition = CGFloat(index) / CGFloat(GameController.kNbItems)
    
        let group = self.padContainer
    
        var insets = UIEdgeInsets(top:0, left:0, bottom:0, right:0)
        insets.top = totalHeight() * (1.0 - m_PadPosition)
    
        group!.setContentInset(insets)
    }


}
