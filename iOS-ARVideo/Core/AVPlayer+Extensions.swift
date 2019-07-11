//
//  AVPlayer+Extensions.swift
//  iOS-ARVideo
//
//  Created by EugenKGD on 11/07/2019.
//  Copyright © 2019 ELezov. All rights reserved.
//

import AVKit

extension AVPlayer {
    
    var isPlaying: Bool {
        return ((rate != 0) && (error == nil))
    }
    
    var isPause: Bool {
        return !isPlaying
    }
}
