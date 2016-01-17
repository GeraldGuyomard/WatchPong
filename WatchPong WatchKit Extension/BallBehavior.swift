//
//  BallBehavior.swift
//  WatchPong
//
//  Created by Gérald Guyomard on 1/17/16.
//  Copyright © 2016 Gérald Guyomard. All rights reserved.
//

import WatchKit
import WatchScene2D

class BallBehavior : W2DComponent, W2DBehavior
{
    var     fBallDirection : CGPoint = CGPointMake(0, 0)
    var     fBallSpeed : CGFloat = 0;

    override init()
    {
        super.init()
        
        fBallDirection = CGPoint(x:-0.6, y:-1.0).normalizedVector()
        fBallSpeed = 60.0
    }
    
    func execute(dT:NSTimeInterval, director:W2DDirector!)
    {
        let dV = fBallSpeed * CGFloat(dT)
        let v = fBallDirection.mul(dV);
        print("v=\(v.x),  \(v.y)")
        
        let sprite : W2DSprite? = component()
        
        guard let ballSprite = sprite
        else
        {
            return;
        }
        
        var ballPos = ballSprite.position.add(v)
        
        let context = director.context
        
        let contextWidth = CGFloat(context.width);
        let contextHeight = CGFloat(context.height);
        
        let level : PongLevel? = director.currentScene!.component()
        
        let padSprite = level!.fPadSprite!
        
        let ballSize = ballSprite.size
        let maxX = contextWidth - ballSize.width - padSprite.size.width
        
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
            
            let kPadPos = padSprite.position.y
            let minPad = kPadPos
            let maxPad = kPadPos + padSprite.size.height
            
            if (maxBall < minPad) || (minBall > maxPad)
            {
                level!.onLost(director)
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
        
        ballSprite.position = ballPos
    }
}

