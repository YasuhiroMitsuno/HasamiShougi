//
//  Player.swift
//  Hasami
//
//  Created by yasu on 2015/02/12.
//  Copyright (c) 2015年 yasu. All rights reserved.
//

import Foundation

enum Player: String {
    case Own = "OWN"
    case Enemy = "ENE"
    func pieceType() -> PieceType {
        switch self {
        case .Own:
            return .Ho
        case .Enemy:
            return .To
        }
    }
    func enemy() -> Player {
        switch self {
        case .Own:
            return .Enemy
        case .Enemy:
            return .Own
        }        
    }
}

