// Copyright 2025 LINE Plus Corporation
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

    private let roomIdTextField: NSTextField = {
        let textField = NSTextField()
        textField.placeholderString = "Enter Room ID"
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let joinButton: NSButton = {
        let button = NSButton(title: "Join", target: nil, action: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    var roomId: String {
        roomIdTextField.stringValue
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    private func setupViews() {
        view.addSubview(roomIdTextField)
        view.addSubview(joinButton)
        
        joinButton.target = self
        joinButton.action = #selector(joinButtonTapped)
        
        NSLayoutConstraint.activate([
            roomIdTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            roomIdTextField.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            roomIdTextField.widthAnchor.constraint(equalToConstant: 200),
            
            joinButton.topAnchor.constraint(equalTo: roomIdTextField.bottomAnchor, constant: 12),
            joinButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            joinButton.widthAnchor.constraint(equalToConstant: 200),
        ])
    }
    
    @objc private func joinButtonTapped() {
        guard !roomId.isEmpty else { return }
        
        let groupCallVC = GroupCallViewController()
        
        let myUserId = PlanetKitUserId(id: userId, serviceId: serviceId)
        let param = PlanetKitConferenceParam(myUserId: myUserId, roomId: roomId, roomServiceId: serviceId, displayName: nil, delegate: groupCallVC, accessToken: accessToken)
        param.mediaType = .audiovideo
        
        let result = PlanetKitManager.shared.joinConference(param: param, settings: nil)
        print("join conference result: \(result.reason)")
        
        guard result.reason == .none else {
            return
        }
        groupCallVC.conference = result.conference
        
        presentAsSheet(groupCallVC)
    }
}
