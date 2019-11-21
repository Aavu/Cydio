//
//  ViewController.swift
//  Cydio
//
//  Created by Raghavasimhan Sankaranarayanan on 11/18/19.
//  Copyright © 2019 Aavu. All rights reserved.
//

import UIKit
import AudioKit
import CoreMotion
import CoreLocation

class ViewController: UIViewController, BTManagerDelegate {
    func BTManagerDidReceiveData(_ data: UInt8) {
        onSeat = data
    }
    
    func BTManagerDidReceiveError(_ error: Error) {
        print(error)
    }
    
    var bleManager = BTManager()
    
    var osc = AKOscillator()
    var panner:AKPanner!
    var motionManager: CMMotionManager!
    var onSeat:UInt8 = 1
    
    let locationManager: CLLocationManager = {
      $0.requestWhenInUseAuthorization()
      $0.startUpdatingHeading()
      return $0
    }(CLLocationManager())
    
    var time = 0.0
    let timeStep = 0.001
    var LFOFreq:Double = 2
    var angle:Double = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        bleManager.delegate = self
        locationManager.delegate = self
        
        panner = AKPanner(osc)
        
        
        let timer = AKPeriodicFunction(every: timeStep) {
            self.osc.amplitude = (sin(2 * Double.pi * self.LFOFreq * self.time) + 1)/2.0
            self.time += self.timeStep
        }
        
        AudioKit.output = panner
        do {
            try AudioKit.start(withPeriodicFunctions: timer)
        } catch {
            print("error")
        }
        osc.frequency = 440.0
        
        osc.rampDuration = 0.05
//        print(osc.rampDuration)
        
        motionManager = CMMotionManager()
        motionManager.accelerometerUpdateInterval = 0.01
        motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
            guard let data = data, error == nil else {
                return
            }

            var lean = 90 + atan2(data.acceleration.z, data.acceleration.x) * 180 / .pi
            print(lean)
            
            if 90 < lean && lean < 180 {
                lean = 90.0
            } else if 270 > lean && lean >= 180 {
                lean = -90.0
            }
            
            lean = max(min(lean/90.0, 1), -1)
            
//            self.osc.frequency = (440 * Double(self.onSeat + 1)) + rotation
            if self.onSeat == 1 {
                self.LFOFreq = 10.0
            } else {
                self.LFOFreq = 0.0
            }
            self.osc.frequency = 440 + self.angle*2
            self.panner.pan = lean
        }
        
        timer.start()
        osc.start()
    }

}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        angle = newHeading.trueHeading - 180
//        osc.frequency += angle*2
    }
}
