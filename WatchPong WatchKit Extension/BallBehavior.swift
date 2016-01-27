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
        
        let sprite : W2DSprite? = component()
        
        guard let ballSprite = sprite
        else
        {
            return;
        }
        
        // try to collide with any collider in the scene
        let collisions = Collider.collideInScene(director.currentScene!, ball: sprite, direction:fBallDirection, instantaneousSpeed:dV)
        if !collisions.isEmpty
        {
            var closestCollision : Collision?
            var minT = CGFloat.max
            
            for c in collisions
            {
                if (c.t < minT)
                {
                    minT = c.t
                    closestCollision = c
                }
            }
            
            fBallDirection = closestCollision!.direction
            fBallSpeed *= closestCollision!.bounceSpeedFactor
            if fBallSpeed > 120
            {
                fBallSpeed = 120
            }
            
            return
        }
        
        let v = fBallDirection.mul(dV);
        print("v=\(v.x),  \(v.y)")
        
        var ballPos = ballSprite.position.add(v)
        
        let context = director.context
        
        let contextWidth = CGFloat(context.width);
        let contextHeight = CGFloat(context.height);
        

        guard let level:PongLevel = director.currentScene!.component()
        else
        {
            return
        }
        
        let ballSize = ballSprite.size
        let maxX = contextWidth - ballSize.width //- padSprite.size.width
        
        // make it bounce if hitting on wall
        if ballPos.x < 0
        {
            ballPos.x = 0
            fBallDirection.x = -fBallDirection.x;
        }
        else if ballPos.x >= maxX
        {
            level.onLost(director)
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

