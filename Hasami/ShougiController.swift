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
    var movablePoints: [Point]

    init() {
        model = ShougiModel()
        srandomdev()
        movablePoints = Array()
    }
    
    func piece(point: Point) -> Piece {
        return model.piece(point)
    }
    
    func selectedPiece() -> Piece? {
        if var point = selectedPoint {
            return model.piece(point)
        }
        return nil
    }
    func currentPlayer() -> Player {
        return model.currentData.turn
    }
    
    func excludedPieces(player: Player) -> [Piece] {
        return model.currentData.excluded[player]!
    }
    
    func select(point: Point?) -> Bool {
        if var _point = point {
            if !model.checkPoint(_point) || model.piece(_point).type == .Masu {
                return false
            }
            // 選択したピースの所有権が選択者か判定
            if model.piece(_point).type != currentPlayer().pieceType() {
                return false
            }

            selectedPoint = _point
            movablePoints.removeAll();
            movablePoints = model.movablePoints(selectedPoint!)
            
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
        let points =  model.move(selectedPoint!, to: p)
        // ターン交代
        model.switchPlayer()
        
        unselect()
        return true
    }
    
    // 待った
    func matta() -> Bool {
        if model.dataCount() < 2 {
            return false
        }
        unselect()
        model.popState()
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
            if abs(model.prevScore(.Own, offset: 1) - model.prevScore(.Enemy, offset: 1)) >= 3 &&
                abs(model.score(.Own) - model.score(.Enemy)) >= 3 {
                    return model.score(.Own) > model.score(.Enemy) ? .Own : .Enemy
            }
        }
        return nil
    }
    
    func reset() {
        model = ShougiModel()
    }
    
    func piecesOfPlayer(player: Player) -> [Point] {
        var arr:[Point] = Array()
        for i in 0...8 {
            for j in 0...8 {
                if piece(Point(y: i, x: j)).type == player.pieceType() {
                    arr.append(Point(y: i, x: j))
                }
            }
        }
        return arr
    }
    var sPiece: Point?
    var sPoint: Point?
    var ok: Bool?
    var sco: Double?
    var scoe: Double?

}

struct PointPair {
    var T1: Point
    var T2: Point
    init(T1: Point, T2: Point) {
        self.T1 = T1
        self.T2 = T2
    }
}

let ABdepth: Int = 2
var willMovePoints: [Double:[PointPair]] = Dictionary()

extension ShougiController {
    func algorithm() {
        let start = NSDate()
        
        var tmpModel = model
        var nModel = model.copy()
        model = nModel
        
        sco = model.score(currentPlayer())
        scoe = model.score(currentPlayer().enemy())
        ok = false
        willMovePoints = Dictionary()
        let db: Double = alphabeta(ABdepth, _alpha: -100, _beta: 100, cPlayer: currentPlayer())
        let points:[PointPair]? = willMovePoints[db]
        NSLog("取り得る手の数: \(points!.count)")
        model = tmpModel

        randomAlgorithm(points!)

        let elapsed = NSDate().timeIntervalSinceDate(start)
        println(elapsed)
    }
    
    func alphabeta(depth: Int, _alpha: Double, _beta: Double, cPlayer: Player) -> Double {
        var alpha = _alpha
        var beta = _beta
        
        if depth == 0 {
            return model.score(cPlayer) - model.score(cPlayer.enemy())
        }
        if currentPlayer() == cPlayer {
            for piece in piecesOfPlayer(currentPlayer()) {
                select(piece)
                for point in movablePoints {
                    model.pushState()
                    model.move(piece, to: point)
                    model.switchPlayer()
                    let ab: Double = alphabeta(depth-1, _alpha: alpha, _beta: beta, cPlayer: cPlayer)
                    if (depth == ABdepth ) {
                        if willMovePoints[ab] == nil {
                            willMovePoints[ab] = Array()
                        }
                        willMovePoints[ab]?.append(PointPair(T1: piece, T2: point))
                    }

                    alpha = max(alpha, ab)
                    
                    model.popState()
                    if alpha >= beta {
                        return beta
                    }
                }
            }
            return alpha
        } else {
            for piece in piecesOfPlayer(currentPlayer()) {
                select(piece)
                for point in movablePoints {
                    model.pushState()
                    model.move(piece, to: point)
                    model.switchPlayer()
                    let ab: Double = alphabeta(depth-1, _alpha: alpha, _beta: beta, cPlayer: cPlayer)
                   beta = min(beta, ab)
                    model.popState()
                    if alpha >= beta {
                        if alpha == beta {
                            return alpha
                        } else {
                            return 0
                        }
                    }
                }
            }
            return beta
        }
    }

    func randomAlgorithm(pointPairs: [PointPair]) {
        var r = random()%pointPairs.count
//        r =  0
        select(pointPairs[r].T1)
        var p = pointPairs[r].T2
        movePiece(p)
    }
}