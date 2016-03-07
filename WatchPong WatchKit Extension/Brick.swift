//
//  Brick.swift
//  WatchPong
//
//  Created by Gérald Guyomard on 2/27/16.
//  Copyright © 2016 Gérald Guyomard. All rights reserved.
//

import Foundation
import WatchScene2D

class Brick : W2DComponent
{
    var fMaxHealth : Int
    var fHealth : Int
    var fCollisionAction : W2DAction? = nil
    
    init(maxHealth:Int)
    {
        fMaxHealth = maxHealth
        fHealth = maxHealth
    }
    
    override func onComponentAdded(newHead:W2DComponent)
    {
        super.onComponentAdded(newHead)
        
        let colliderOrNil : Collider? = component()
        if let collider = colliderOrNil
        {
            collider.collisionCallback = {
                [weak self](collision:Collision) -> Collision? in
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
    
    override  func onComponentRemoved(oldHead:W2DComponent, oldComponent:W2DComponent)
    {
        let colliderOrNil : Collider? = oldHead.component()
        if let collider = colliderOrNil
        {
            collider.collisionCallback = nil
        }
        
        super.onComponentRemoved(oldHead, oldComponent:oldComponent)
    }
    
    func handleCollision(collision:Collision) -> Collision
    {
        assert(fHealth > 0)
        let myNode = collision.node
        
        if --fHealth == 0
        {
            myNode.removeFromParent()
        }
        else
        {
            fCollisionAction?.stop()
            
            let alpha = CGFloat(fHealth) / CGFloat(fMaxHealth)
            fCollisionAction = W2DFadeToAction(duration: 0.25, finalAlpha: alpha)
            
            myNode.run(fCollisionAction!)
        }
        
        return collision
    }
}