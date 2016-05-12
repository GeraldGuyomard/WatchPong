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

class GameController: WKInterfaceController, PlayerDelegate
{
    @IBOutlet var screenButton : WKInterfaceButton?
    @IBOutlet var myPicker: WKInterfacePicker?
    
    @IBOutlet var scoreLabel: WKInterfaceLabel?
    
    @IBOutlet var health1 : WKInterfaceObject?
    @IBOutlet var health2 : WKInterfaceObject?
    @IBOutlet var health3 : WKInterfaceObject?
    
    var     fHealthIndicators = [WKInterfaceObject]()
    
    var     f2DDirector: W2DDirector?
    var     fPlayer = Player()
    var     fLevel : PongLevel?
    
    func onHealthChanged(player:Player, newHealth:UInt)
    {
        updateHealth()
    }
    
    func onScoreChanged(player:Player, newHealth:UInt)
    {
        updateScore()
    }
    
    private func updateHealth()
    {
        let newHealth = fPlayer.health
        assert(newHealth <= UInt(fHealthIndicators.count))
        
        var h = Int(newHealth)
        for indicator in fHealthIndicators
        {
            indicator.setHidden(h <= 0)
            h -= 1
        }
    }
    
    private func updateScore()
    {
        if let l = scoreLabel
        {
            let newScore = fPlayer.score
            let text = String(newScore)
            l.setText(text)
        }
    }
    
    override func awakeWithContext(context: AnyObject?)
    {
        super.awakeWithContext(context)
        
        let bounds = WKInterfaceDevice.currentDevice().screenBounds
        print("screen bounds (\(bounds.width) x \(bounds.height)")
        
        if let h = health1
        {
            fHealthIndicators.append(h)
        }
        
        if let h = health2
        {
            fHealthIndicators.append(h)
        }
        
        if let h = health3
        {
            fHealthIndicators.append(h)
        }
        
        fPlayer.health = UInt(fHealthIndicators.count)
        fPlayer.delegate = self
        
        updateHealth()
        updateScore()
        
        let contextWidth = UInt(bounds.width)
        let contextHeight = (bounds.width == 156) ? UInt(148) : UInt(120) // UInt(146 - 20)
        let context = createW2DContext(width:contextWidth, height:contextHeight)
        f2DDirector = createW2DDirector(self.screenButton!, context: context)
        f2DDirector!.smartRedrawEnabled  = true
        //f2DDirector!.showDirtyRects = true
        
        f2DDirector!.setupDigitalCrownInput(picker:self.myPicker!, sensitivity:30)
        
        // Create the level
        fLevel = PongLevel(player:fPlayer)
        
        f2DDirector!.currentScene = fLevel?.createScene(f2DDirector!)
    }

    override func willActivate()
    {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        f2DDirector?.start()
                
        self.myPicker!.focus()
        
        fLevel?.willActivate(f2DDirector)
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
                    this.fLevel?.setPadPosition(value, director:this.f2DDirector)
                }
            })
    }
    
    @IBAction func clickScreenAction()
    {
        
    }
}
