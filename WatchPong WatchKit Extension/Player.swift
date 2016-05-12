//
//  Player.swift
//  WatchPong
//
//  Created by Gérald Guyomard on 5/12/16.
//  Copyright © 2016 Gérald Guyomard. All rights reserved.
//

import WatchKit
import WatchScene2D

public protocol PlayerDelegate : class
{
    func onHealthChanged(player:Player, newHealth:UInt)
    func onScoreChanged(player:Player, newHealth:UInt)
}

public class Player
{
    weak public var delegate:PlayerDelegate? = nil
    
    public var health : UInt = 0
    {
        didSet(newValue)
        {
            if let d = self.delegate
            {
                d.onHealthChanged(self, newHealth:newValue)
            }
        }
    }
    
    public var score : UInt = 0
    {
        didSet(newValue)
        {
            if let d = self.delegate
            {
                d.onScoreChanged(self, newHealth:newValue)
            }
        }
    }
}
