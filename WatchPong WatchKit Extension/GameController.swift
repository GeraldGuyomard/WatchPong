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

class GameController: WKInterfaceController
{
    @IBOutlet var screenButton : WKInterfaceButton?
    @IBOutlet var myPicker: WKInterfacePicker?
    
    @IBOutlet var health1 : WKInterfaceObject?
    @IBOutlet var health2 : WKInterfaceObject?
    @IBOutlet var health3 : WKInterfaceObject?
    
    var     fHealths = [WKInterfaceObject]()
    var     fPlayerHealth : Int = 0
    
    var     f2DDirector: W2DDirector?
    var     fLevel = PongLevel()
    
    var playerHealth : Int
    {
        get { return fPlayerHealth }
        set(newHealth)
        {
            if fPlayerHealth != newHealth
            {
                fPlayerHealth = newHealth
                assert(fPlayerHealth <= fHealths.count)
                
                var h = fPlayerHealth
                for indicator in fHealths
                {
                    indicator.setHidden(h <= 0)
                    h -= 1
                }
            }
        }
    }
    
    override func awakeWithContext(context: AnyObject?)
    {
        super.awakeWithContext(context)
        
        let bounds = WKInterfaceDevice.currentDevice().screenBounds
        print("screen bounds (\(bounds.width) x \(bounds.height)")
        
        if let h = health1
        {
            fHealths.append(h)
        }
        
        if let h = health2
        {
            fHealths.append(h)
        }
        
        if let h = health3
        {
            fHealths.append(h)
        }
        
        self.playerHealth = fHealths.count
        
        let contextWidth = UInt(bounds.width)
        let contextHeight = (bounds.width == 156) ? UInt(148) : UInt(120) // UInt(146 - 20)
        let context = createW2DContext(width:contextWidth, height:contextHeight)
        f2DDirector = createW2DDirector(self.screenButton!, context: context)
        f2DDirector!.smartRedrawEnabled  = true
        //f2DDirector!.showDirtyRects = true
        
        f2DDirector!.setupDigitalCrownInput(picker:self.myPicker!, sensitivity:30)
        
        f2DDirector!.currentScene = fLevel.createScene(f2DDirector!)
    }

    override func willActivate()
    {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        f2DDirector?.start()
                
        self.myPicker!.focus()
        
        fLevel.willActivate(f2DDirector)
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
        f2DDirector!.processDigitalCrownInput(iIndex, handler:
            {[weak self](value:Float) in
                if let this = self
                {
                    this.fLevel.setPadPosition(value, director:this.f2DDirector)
                }
            })
    }
    
    @IBAction func clickScreenAction()
    {
        
    }
}
