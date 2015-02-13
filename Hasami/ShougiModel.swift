//
//  ShougiModel.swift
//  Hasami
//
//  Created by yasu on 2015/02/12.
//  Copyright (c) 2015年 yasu. All rights reserved.
//

import Foundation

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


enum Direction:Int {
    case Up = 1
    case Down, Left, Right
    func toPoint() -> Point {
        switch self {
        case .Up:
            return Point(y: -1, x: 0)
        case .Down:
            return Point(y: 1, x: 0)
        case .Left:
            return Point(y: 0, x: -1)
        case .Right:
            return Point(y: 0, x: 1)
        }
    }
}
enum PieceType {
    case Ho, To, Masu
}

struct Piece {
    var type: PieceType
    var id: Int
}

class BoardData {
    var bin: [[Piece]]
    var turn : Player
    var score: [Player:Int]
    init() {
        bin = Array(count: 9, repeatedValue: Array(count: 9, repeatedValue: Piece(type: .Masu, id: 0)))
        for i in 0...8 {
            bin[0][i].type = .To
            bin[8][i].type = .Ho
            bin[0][i].id = i
            bin[8][i].id = i
        }
        turn = .Own
        score = Dictionary(dictionaryLiteral: (.Own, 0), (.Enemy, 0))
    }
    func copy()->BoardData {
        var newBoardData = BoardData()
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
    private var currentData: BoardData

    init() {
        datas = Array()
        currentData = BoardData()
    }
    
    func piece(p: Point) -> Piece {
        return currentData.bin[p.y][p.x]
    }
    func dataCount() -> Int {
        return datas.count
    }
    func checkPoint(p: Point) -> Bool {
        return p.y >= 0 && p.y < 9 && p.x >= 0 && p.x < 9
    }
    func pushState() {
        datas.append(currentData.copy())
    }
    func popState() {
        currentData =  datas.last!
        datas.removeLast()
    }
    // コマを動かし，ポイントを追加
    func move(from: Point, to: Point) -> [Point] {
        currentData.bin[to.y][to.x] = currentData.bin[from.y][from.x]
        currentData.bin[from.y][from.x] = Piece(type: .Masu, id: 0)
        let points = hasami(to)
        delete(points)
        return points
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
        for direction: Direction in [.Up, .Down, .Left, .Right] {
            var tmpPoints: [Point] = Array()
            var ok = false
            for var np:Point=p+direction.toPoint();checkPoint(np);np=np+direction.toPoint() {
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
        return willDeletePoints
    }
    
    func delete(points: [Point]) {
        for point in points {
            currentData.bin[point.y][point.x].type = .Masu
            currentData.bin[point.y][point.x].id = 0
        }
    }

}