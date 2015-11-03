//
//  GameController.swift
//  WatchPong WatchKit Extension
//
//  Created by Gérald Guyomard on 9/13/15.
//  Copyright © 2015 Gérald Guyomard. All rights reserved.
//

import WatchKit
import Foundation
import WatchScene2D

class GameController: WKInterfaceController, W2DBehavior
{
    @IBOutlet var image : WKInterfaceImage?
    @IBOutlet var myPicker: WKInterfacePicker?
    @IBOutlet var padContainer : WKInterfaceGroup?
    
    var     fBallSprite : W2DSprite?
    var     fBallDirection : CGPoint = CGPointMake(0, 0)
    var     fBallSpeed : CGFloat = 0;
    
    var     fPadPosition : CGFloat = 0;
    var     fPadHeight : CGFloat = 0;
    var     fPadSprite : W2DSprite?
    
    var     fMustStartGame = true;
    var     fLost : Bool = false;
    
    var     f2DContext: W2DContext?
    var     f2DDirector: W2DDirector?
    
    override func awakeWithContext(context: AnyObject?)
    {
        super.awakeWithContext(context)
        
        f2DContext = createW2DContext(width:142, height:UInt(GameController.kHeight))
        f2DDirector = createW2DDirector(self.image!, context: f2DContext!)
        f2DDirector!.addBehavior(self) // cycling ref?
        
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
        
        let padImage = f2DContext!.image(named:"pad.png")
        fPadHeight = padImage!.size.height
        fPadSprite = W2DSprite(image: padImage)
        
        f2DDirector!.currentScene = self.createScene()
    }

    override func willActivate()
    {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        f2DDirector?.start()
                
        self.myPicker!.focus()
        
        if (fMustStartGame)
        {
            fMustStartGame = false
            startGame()
        }
    }

    override func didDeactivate()
    {
        f2DDirector?.stop()
        
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
    
    func execute(dT: NSTimeInterval)
    {
        if fLost
        {
            return
        }
        
        let dV = fBallSpeed * CGFloat(dT)
        let v = fBallDirection.mul(dV);
        print("v=\(v.x),  \(v.y)")
        
        var ballPos = fBallSprite!.position.add(v)
   
        let contextWidth = CGFloat(f2DContext!.width);
        let contextHeight = CGFloat(f2DContext!.height);
        
        let ballSize = fBallSprite!.size
        let maxX = contextWidth - ballSize.width
        
        // make it bounce if hitting on wall
        if ballPos.x < 0
        {
            ballPos.x = 0
            fBallDirection.x = -fBallDirection.x;
        }
        else if ballPos.x >= maxX
        {
            // make sure it bounced on the pad
            let minBall =  ballPos.y
            let maxBall = ballPos.y + ballSize.height
            
            let kPadPos = fPadPosition * contextHeight
            let minPad = kPadPos
            let maxPad = kPadPos + fPadHeight
            
            if (maxBall < minPad) || (minBall > maxPad)
            {
                ballPos.x = contextWidth / 2
                ballPos.y = contextHeight / 2
                fLost = true
                f2DDirector!.currentScene!.backgroundColor = W2DColor4f(red:1, green:0, blue:0)
            
                WKInterfaceDevice.currentDevice().playHaptic(.Failure)
                
                f2DDirector!.stop()
            }
            else
            {
                ballPos.x = maxX - 1
                
                // Bounce
                WKInterfaceDevice.currentDevice().playHaptic(.Retry)
                
                fBallSpeed += 15
                if fBallSpeed > 120
                {
                    fBallSpeed = 120
                }
            }
    
            fBallDirection.x = -fBallDirection.x
        }
    
        let maxY = contextHeight - ballSize.height
        
        if ballPos.y < 0
        {
            ballPos.y = 0
            fBallDirection.y = -fBallDirection.y
        }
        else if ballPos.y >= maxY
        {
            ballPos.y = maxY - 1
            fBallDirection.y = -fBallDirection.y
        }
        
        fBallSprite!.position = ballPos
    }
    
    func createScene() -> W2DScene
    {
        let scene = W2DScene()
        
        var pt = CGPointMake(16, 0);
        
        let brickImage = f2DContext!.image(named:"brick-red.png")
        let brickSize = brickImage!.size
        
        for _ in 1...3
        {
            let brick = W2DSprite(image:brickImage!)
            brick.position = pt
            scene.addChild(brick)
            
            pt.y += 2 * brickSize.height
        }
        
        pt = CGPointMake(16 + 2 * brickSize.width, brickSize.height)
        for _ in 1...3
        {
            let brick = W2DSprite(image:brickImage!)
            brick.position = pt
            scene.addChild(brick)
            
            pt.y += 2 * brickSize.height
        }
        
        fBallSprite = W2DSprite(named: "ball.png", inContext:f2DContext!)
        scene.addChild(fBallSprite)
        
        assert(fPadSprite != nil)
        scene.addChild(fPadSprite)
        
        fPadSprite!.position = CGPointMake(CGFloat(f2DContext!.width) - fPadSprite!.size.width, 0)
        
        return scene
    }
    
    func startGame()
    {
        fPadPosition = 0.5
        let kInitialPos = GameController.kNbItems / 2
        self.myPicker!.setSelectedItemIndex(kInitialPos)
        self.setPadPosition(kInitialPos)
    
        let contextWidth = CGFloat(f2DContext!.width)
        let contextHeight = CGFloat(f2DContext!.height)
        
        let ballSize = fBallSprite!.size
        let ballPos = CGPointMake(contextWidth - (2 * ballSize.width), (contextHeight - ballSize.height) / 2)
        fBallSprite!.position = ballPos
        
        fBallDirection = CGPoint(x:-0.6, y:-1.0).normalizedVector()
        fBallSpeed = 60.0
    
        fLost = false
        f2DDirector!.currentScene!.backgroundColor = W2DColor4f()
    }
    
    func totalHeight() -> CGFloat
    {
        return GameController.kHeight - fPadHeight
    }
    
    func setPadPosition(index:Int)
    {
        fPadPosition = CGFloat(index) / CGFloat(GameController.kNbItems)
    
        let group = self.padContainer
    
        var insets = UIEdgeInsets(top:0, left:0, bottom:0, right:0)
        insets.top = totalHeight() * (1.0 - fPadPosition)
    
        group!.setContentInset(insets)
        
        
        var pos = fPadSprite!.position
        pos.y = fPadPosition * totalHeight()
        fPadSprite!.position = pos
    }


}
