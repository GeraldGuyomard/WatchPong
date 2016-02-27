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
    override func onComponentAdded(newHead:W2DComponent)
    {
        super.onComponentAdded(newHead)
        
        let colliderOrNil : Collider? = component()
        if let collider = colliderOrNil
        {
            collider.collisionCallback = {
                [weak self](collision:Collision) -> Collision? in
                {
                    if self != nil
                    {
                        collision.node.removeFromParent()
                    }
                    
                    return collision
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
}