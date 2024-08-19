// Copyright 2024 LINE Plus Corporation
//
// LINE Plus Corporation licenses this file to you under the Apache License,
// version 2.0 (the "License"); you may not use this file except in compliance
// with the License. You may obtain a copy of the License at:
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

import Cocoa
import PlanetKit

// TODO: Set your own environment
let userId = "<YOUR_USER_ID>"
let serviceId = "planet-kit-quick-start"
let accessToken = "<YOUR_ACCESS_TOKEN>"


class ViewController: NSViewController {

    let myUserId = PlanetKitUserId(id: userId, serviceId: serviceId)

    @IBOutlet weak var conferenceStateLabel: NSTextField!
    @IBOutlet weak var participantCountLabel: NSTextField!
    @IBOutlet weak var roomIdTextField: NSTextField!
    
    var participantCount: Int = 0 {
        didSet {
            participantCountLabel.stringValue = "participant count: \(participantCount)"
        }
    }
    
    var state: String = "" {
        didSet {
            conferenceStateLabel.stringValue = "conference state: \(state)"
        }
    }
    
    var roomId: String {
        roomIdTextField.stringValue
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        participantCount = 0
        state = ""
    }

    @IBAction func joinConference(_ sender: Any) {
        let param = PlanetKitConferenceParam(myUserId: myUserId, roomId: roomId, roomServiceId: serviceId, displayName: nil, delegate: self, accessToken: accessToken)
        let result = PlanetKitManager.shared.joinConference(param: param, settings: nil)
        
        print("join conference result: \(result.reason)")
    }
    
    @IBAction func leaveConference(_ sender: Any) {
        PlanetKitManager.shared.conference?.leaveConference()
        
        print("leave conference")
    }
}


extension ViewController: PlanetKitConferenceDelegate {
    func didConnect(_ conference: PlanetKitConference, connected param: PlanetKitConferenceConnectedParam) {
        DispatchQueue.main.async {
            self.state = "connected"
            self.participantCount = 1
            
            print("connected: \(param)")
        }
    }
    
    func didDisconnect(_ conference: PlanetKitConference, disconnected param: PlanetKitDisconnectedParam) {
        DispatchQueue.main.async {
            self.state = "disconnected"
            self.participantCount = 0
            
            print("disconnected: \(param.reason)")
        }
    }
    
    func peerListDidUpdate(_ conference: PlanetKitConference, updated param: PlanetKitConferencePeerListUpdateParam) {
        DispatchQueue.main.async {
            // Add peer count include me
            self.participantCount = param.totalPeersCount + 1
        }
    }
    
    func peersVideoDidUpdate(_ conference: PlanetKitConference, updated param: PlanetKitConferenceVideoUpdateParam) {
        // Do nothing.
    }
}
