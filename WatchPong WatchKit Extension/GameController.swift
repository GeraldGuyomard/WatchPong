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
    @IBOutlet var image : WKInterfaceImage?
    @IBOutlet var myPicker: WKInterfacePicker?
    
    var     f2DDirector: W2DDirector?
    var     fLevel = PongLevel()
    
    override func awakeWithContext(context: AnyObject?)
    {
        super.awakeWithContext(context)
        
        let bounds = WKInterfaceDevice.currentDevice().screenBounds
        print("screen bounds (\(bounds.width) x \(bounds.height)")
        
        let contextWidth = UInt(bounds.width) //(bounds.width == 156) ? UInt(142) : UInt(118)
        let contextHeight = UInt(146)
        let context = createW2DContext(width:contextWidth, height:contextHeight)
        f2DDirector = createW2DDirector(self.image!, context: context)
        f2DDirector!.smartRedrawEnabled  = true
        //f2DDirector!.showDirtyRects = true
        
        f2DDirector!.setupDigitalCrownInput(picker:self.myPicker!, sensitivity:40)
        
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
}
