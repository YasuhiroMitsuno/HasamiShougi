//
//  ShougiModel.swift
//  Hasami
//
//  Created by yasu on 2015/02/12.
//  Copyright (c) 2015年 yasu. All rights reserved.
//

import Foundation
import SpriteKit

struct Point {
    var y: Int, x:Int
    init(y: Int, x: Int) {
        self.y = y
        self.x = x
    }
}

func +(l: Point, r: Point) -> Point {
    return Point(y: l.y + r.y, x:l.x + r.x)
}

func ==(l: Point, r: Point) -> Bool {
    return l.y == r.y && l.x == r.x
}

let vectors: [Point] = [
    Point(y: -1, x: 0),
    Point(y: 1, x: 0),
    Point(y: 0, x: -1),
    Point(y: 0, x: 1)
]

enum PieceType : Int {
    case Ho = 0, To = 1, Masu = 2
}

struct Piece {
    var type: PieceType
    var id: Int
}

class BoardData {
    var bin: [Piece]
    var turn : Player
    var score: [Player:Int]
    init() {
        bin = Array(count: 81, repeatedValue: Piece(type: .Masu, id: 0))
        for i in 0...8 {
            bin[i].type = .To
            bin[72+i].type = .Ho
            bin[i].id = i
            bin[72+i].id = i
        }
        turn = .Own
        score = Dictionary(dictionaryLiteral: (.Own, 0), (.Enemy, 0))
    }
    func copy()->BoardData {
        var newBoardData = BoardData()
        newBoardData.bin = bin
        newBoardData.turn = turn
        newBoardData.score = score
        return newBoardData
    }
}

protocol ShougiAlgorithmProtocol {
    func hasami(Point) -> [Point]
}

class ShougiModel {
    private var datas: [BoardData]
    var currentData: BoardData

    init() {
        datas = Array()
        currentData = BoardData()
    }
    func copy()->ShougiModel {
        var newShougiModel = ShougiModel()
        newShougiModel.datas = datas
        newShougiModel.currentData = currentData.copy()
        return newShougiModel
    }
    func piece(p: Point) -> Piece {
        return currentData.bin[p.y*9+p.x]
    }
    func dataCount() -> Int {
        return datas.count
    }
    func checkPoint(p: Point) -> Bool {
        return p.y >= 0 && p.y < 9 && p.x >= 0 && p.x < 9
    }
    func pushState() {
        datas.append(currentData.copy())
//        showState()
    }
    func showState() {
        for T in currentData.bin {
            var str: String = ""
            str += "\(T.type.rawValue)"
            NSLog(str)
        }
    }
    func popState() {
        currentData =  datas.last!
        datas.removeLast()
    }
    func movablePoints(point: Point) -> [Point] {
        var points: [Point] = Array()
        
        for vector in vectors {
            for var p:Point=point+vector;checkPoint(p);p=p+vector {
                if piece(p).type != .Masu {
                    break
                }
                points.append(p)
            }
        }
        return points;
    }
    // コマを動かし，ポイントを追加
    func move(from: Point, to: Point) -> [Point] {
        currentData.bin[to.y*9+to.x] = currentData.bin[from.y*9+from.x]
        currentData.bin[from.y*9+from.x] = Piece(type: .Masu, id: 0)
        let points = hasami(to)
        delete(points)
        currentData.score[currentData.turn] = points.count + currentData.score[currentData.turn]!
        return points
    }
    func switchPlayer() {
        currentData.turn = currentData.turn.enemy()
    }
    func score(player: Player) -> Int {
        return currentData.score[player]!
    }

    func prevScore(player: Player, offset: Int) -> Int {
        return datas[datas.endIndex-offset].score[player]!
    }
}

extension ShougiModel : ShougiAlgorithmProtocol {
    func hasami(p: Point) -> [Point] {
        var willDeletePoints : [Point] = Array()
        for vector in vectors {
            var tmpPoints: [Point] = Array()
            var ok = false
            for var np:Point=p+vector;checkPoint(np);np=np+vector {
                if piece(np).type != .Masu {
                    if piece(np).type != piece(p).type {
                        ok = true
                        tmpPoints.append(np)
                    } else {
                        if (ok) {
                            for point in tmpPoints {
                                willDeletePoints.append(point)
                            }
                        }
                        break
                    }
                } else {
                    break
                }
            }
        }
        
        // 囲いハサミ
        var visited: [[Bool]] = Array(count: 9, repeatedValue: Array(count: 9, repeatedValue: false))
        visited[p.y][p.x] = true
        for vector1 in vectors {
            var ok = true
            var tmpPoints: [Point] = Array()
            let np = p+vector1
            tmpPoints.append(np)
            if !checkPoint(np) || piece(np).type == .Masu || piece(np).type == piece(p).type { continue }
            visited[np.y][np.x] = true
            
            for (var index = 0;index < tmpPoints.count;index++) {
                if movablePoints(tmpPoints[index]).count > 0 {
                    ok = false
                    break;
                }
                visited[tmpPoints[index].y][tmpPoints[index].x] = true
                for vector2 in vectors {
                    let np2 = tmpPoints[index]+vector2
                    if checkPoint(np2) && !visited[np2.y][np2.x] && piece(np2).type != .Masu && piece(np2).type != piece(p).type {
                        tmpPoints.append(np2)
                        
                    }
                }
            }
            if ok {
                willDeletePoints += tmpPoints
            }
        }


        return willDeletePoints
    }
    
    func delete(points: [Point]) {
        for point in points {
            currentData.bin[point.y*9+point.x].type = .Masu
            currentData.bin[point.y*9+point.x].id = 0
        }
    }

}