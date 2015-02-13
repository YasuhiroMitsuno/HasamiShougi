//
//  ShougiController.swift
//  Hasami
//
//  Created by yasu on 2015/02/12.
//  Copyright (c) 2015年 yasu. All rights reserved.
//

import Foundation


class ShougiController {
    private var model: ShougiModel
    private var selectedPoint: Point?
    var currentPlayer: Player
    var movablePoints: [Point]

    init() {
        model = ShougiModel()
        movablePoints = Array()
        currentPlayer = .Own
    }
    
    func select(point: Point?) -> Bool {
        if var _point = point {
            // 選択したピースの所有権が選択者か判定
            if model.piece(_point) != currentPlayer.piece() {
                return false
            }

            selectedPoint = _point
            movablePoints.removeAll();

            for direction: Direction in [.Up, .Down, .Left, .Right] {
                for var p:Point=selectedPoint!+direction.toPoint();model.checkPoint(p);p=p+direction.toPoint() {
                    if model.piece(p) != .Masu {
                        break
                    }
                    movablePoints.append(p)
                }
            }
            
            return true
        }
        return false
    }
    func unselect() {
        movablePoints.removeAll();
        selectedPoint = nil;
    }
    
    func canMove(p: Point) -> Bool {
        if let _selectedPoint = selectedPoint {
            if movablePoints.filter({T in T == p}).count > 0 {
                return true
            }
        }
        return false
    }

    func movePiece(p: Point) -> Bool {
        if !canMove(p) {
            return false
        }
        
        // 動かす前の状態を保存
        model.pushState()
        // コマの移動
        let newScore = model.move(selectedPoint!, to: p)
        // ターン交代
        currentPlayer = currentPlayer.enemy()
        
        return true
    }

    // 待った
    func matta() -> Bool {
        if model.dataCount() < 2 {
            return false
        }
        model.popState()
        return true
    }
    
    // 勝利していたらプレーヤーを返す
    func winner() -> Player? {
        if model.score(.Own) >= 5 {
            return .Own
        }
        if model.score(.Enemy) >= 5 {
            return .Enemy
        }
        if model.dataCount() > 2 {
            if abs(model.prevScore(.Own, offset: 2) - model.prevScore(.Enemy, offset: 2)) >= 3 &&
                abs(model.prevScore(.Own, offset: 1) - model.prevScore(.Enemy, offset: 1)) >= 3 {
                    return model.score(.Own) > model.score(.Enemy) ? .Own : .Enemy
            }
        }
        return nil
    }
}