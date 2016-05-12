//
//  Brick.swift
//  WatchPong
//
//  Created by Gérald Guyomard on 2/27/16.
//  Copyright © 2016 Gérald Guyomard. All rights reserved.
//

import Foundation
import WatchScene2D

public class Brick : W2DComponent
{
    var fMaxHealth : Int
    var fHealth : Int
    var fCollisionAction : W2DAction? = nil
    
    public var otherScaleAfterCollision : CGFloat = 1.0
    
    init(maxHealth:Int)
    {
        fMaxHealth = maxHealth
        fHealth = maxHealth
    }
    
    override public func onComponentAdded(newHead:W2DComponent)
    {
        super.onComponentAdded(newHead)
        
        let colliderOrNil : W2DCollider? = component()
        if let collider = colliderOrNil
        {
            collider.collisionCallback = {
                [weak self](collision:W2DCollision) -> W2DCollision? in
                {
                    if let myself = self
                    {
                        return myself.handleCollision(collision)
                    }
                    else
                    {
                        return collision
                    }
                }()}
        }
    }
    
    override  public func onComponentRemoved(oldHead:W2DComponent, oldComponent:W2DComponent)
    {
        let colliderOrNil : W2DCollider? = oldHead.component()
        if let collider = colliderOrNil
        {
            collider.collisionCallback = nil
        }
        
        super.onComponentRemoved(oldHead, oldComponent:oldComponent)
    }
    
    func handleCollision(collision:W2DCollision) -> W2DCollision
    {
        assert(fHealth > 0)
        
        if otherScaleAfterCollision != 1.0
        {
            if fHealth == fMaxHealth // First Hit
            {
                collision.movingNode!.run(W2DScaleToAction(duration: 1, finalScale: 0.5))
            }
        }
        
        let myNode = collision.hitNode
        if let scene = myNode.director?.currentScene
        {
            if let level = PongLevel.instance(scene)
            {
                let player = level.player
                player.score = player.score + 10
            }
        }
        
        fHealth -= 1
        
        if fHealth == 0
        {
            let collider : W2DCollider? = component()
            collider?.isActive = false
        }
        
        fCollisionAction?.stop()
        
        let alpha = CGFloat(fHealth) / CGFloat(fMaxHealth)
        let action = W2DFadeToAction(duration: 0.25, finalAlpha: alpha)
        let completion = W2DCallbackAction(callback: {[weak self](target:W2DNode?) in
                if let this = self
                {
                    if this.fHealth == 0
                    {
                        myNode.removeFromParent()
                    }
                }
            })
        
        let seq = W2DSequenceAction()
        seq.addAction(action)
        seq.addAction(completion)
        
        fCollisionAction = seq
        
        myNode.run(fCollisionAction!)
        
        return collision
    }
}