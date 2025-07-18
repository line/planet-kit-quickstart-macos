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


class GroupCallViewController: NSViewController {
    
    var conference: PlanetKitConference!
    private var peerControl: PlanetKitPeerControl?
    
    private var peerVideoView: PlanetKitMTKView = {
        let videoView = PlanetKitMTKView(frame: .zero, device: nil)
        videoView.wantsLayer = true
        videoView.layer?.borderColor = .init(gray: 0.5, alpha: 1.0)
        videoView.layer?.borderWidth = 1
        videoView.clear()
        return videoView
    }()
    
    private var myVideoView: PlanetKitMTKView = {
        let videoView = PlanetKitMTKView(frame: .zero, device: nil)
        videoView.wantsLayer = true
        videoView.layer?.borderColor = .init(gray: 0.5, alpha: 1.0)
        videoView.layer?.borderWidth = 1
        videoView.clear()
        return videoView
    }()
    
    private let tableView = NSTableView()
    private let tableScrollView = NSScrollView()
    
    private let leaveButton: NSButton = {
        let button = NSButton(title: "Leave", target: nil, action: nil)
        return button
    }()
    
    private var peerList = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
        PlanetKitCameraManager.shared.startPreview(delegate: myVideoView)
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        
        PlanetKitCameraManager.shared.stopPreview(delegate: myVideoView)
    }
    
    private func setupViews() {
        tableView.dataSource = self
        tableView.delegate = self
        
        leaveButton.target = self
        leaveButton.action = #selector(leaveButtonTapped)
        
        // Configure NSTableView: show header with "Peer list" label
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Column"))
        column.title = "Peer list"
        tableView.addTableColumn(column)
        
        // Configure NSScrollView to host the tableView
        tableScrollView.documentView = tableView
        tableScrollView.hasVerticalScroller = true
        tableScrollView.autohidesScrollers = true
        
        // Enable Auto Layout and add subviews
        [peerVideoView, myVideoView, tableScrollView, leaveButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        // Constraints for tableScrollView and leaveButton (right side)
        NSLayoutConstraint.activate([
            tableScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            tableScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableScrollView.widthAnchor.constraint(equalToConstant: 200),
            tableScrollView.bottomAnchor.constraint(equalTo: leaveButton.topAnchor, constant: -8),
            
            leaveButton.leadingAnchor.constraint(equalTo: tableScrollView.leadingAnchor, constant: 8),
            leaveButton.trailingAnchor.constraint(equalTo: tableScrollView.trailingAnchor, constant: -8),
            leaveButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            leaveButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // Layout for the left side video views:
        NSLayoutConstraint.activate([
            // Peer video view at the top of the left area
            peerVideoView.topAnchor.constraint(equalTo: view.topAnchor),
            peerVideoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            peerVideoView.trailingAnchor.constraint(equalTo: tableScrollView.leadingAnchor),
            
            // My video view at the bottom of the left area
            myVideoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            myVideoView.trailingAnchor.constraint(equalTo: tableScrollView.leadingAnchor),
            myVideoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Vertical stacking: myVideoView starts where peerVideoView ends
            myVideoView.topAnchor.constraint(equalTo: peerVideoView.bottomAnchor),
            
            // Both video views have equal height
            peerVideoView.heightAnchor.constraint(equalTo: myVideoView.heightAnchor)
        ])
    }
    
    @objc private func leaveButtonTapped() {
        conference.leaveConference()
    }
    
    private var selectedPeerId: String? {
        let index = tableView.selectedRow
        guard index >= 0, index < self.peerList.count else {
            return nil
        }
        return peerList[index]
    }
    
    private func showAlert(_ title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        let _ = alert.runModal()
    }
    
    private func showPeerVideo(_ peerId: String) {
        guard let peer = conference.getPeer(peerId: PlanetKitUserId(id: peerId, serviceId: serviceId)) else {
            print("Failed to get peer of \(peerId)")
            return
        }
        guard let peerControl = conference.createPeerControl(peer: peer) else {
            print("Failed to create peer control for \(peerId)")
            return
        }
        self.peerControl = peerControl
        
        peerControl.register(self) { success in
            guard success else {
                print("Failed to register peer control for \(peerId)")
                return
            }
            peerControl.startVideo(maxResolution: .recommended, delegate: self.peerVideoView) { success in
                if !success {
                    print("Failed to start peer video for \(peerId)")
                    self.peerVideoView.clear()
                }
            }
        }
    }
    
    private func clearPeerVideo() {
        if let oldPeerControl = peerControl {
            oldPeerControl.unregister() { success in
                if !success {
                    print("Failed to unregister peer control for \(oldPeerControl.peer.id.uniqueId)")
                }
            }
            peerControl = nil
        }
        peerVideoView.clear()
    }
    
    private func updatePeerList(added: [String], removed: [String]) {
        var updatedPeerList = peerList
        updatedPeerList.append(contentsOf: added)
        updatedPeerList.removeAll(where: { removed.contains($0) })
        
        peerList = updatedPeerList
    }
}


extension GroupCallViewController: PlanetKitConferenceDelegate {
    func didConnect(_ conference: PlanetKitConference, connected param: PlanetKitConferenceConnectedParam) {
    }
    
    func didDisconnect(_ conference: PlanetKitConference, disconnected param: PlanetKitDisconnectedParam) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            
            print("disconnected: \(param.reason)")
            
            self.showAlert("Disconnected", message: "reason: \(param.reason), source: \(param.source)")
            self.dismiss(self)
        }
    }
    
    func peerListDidUpdate(_ conference: PlanetKitConference, updated: PlanetKitConferencePeerListUpdateParam) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            
            let addedPeerIdList = updated.addedPeers.map { $0.id.id }
            let removedPeerIdList = updated.removedPeers.map { $0.id.id }
            
            self.updatePeerList(added: addedPeerIdList, removed: removedPeerIdList)
            self.tableView.reloadData()
        }
    }
    
    func peersVideoDidUpdate(_ conference: PlanetKitConference, updated: PlanetKitConferenceVideoUpdateParam) {
    }
}


extension GroupCallViewController: PlanetKitPeerControlDelegate {
    func didDisconnect(_ peerControl: PlanetKitPeerControl) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            
            if self.peerControl === peerControl {
                peerControl.unregister() { success in
                    if !success {
                        print("Failed to unregister peer control for \(peerControl.peer.id.uniqueId)")
                    }
                }
                self.peerControl = nil
            }
        }
    }
    
    func didUpdateVideo(_ peerControl: PlanetKitPeerControl, subgroup: PlanetKitSubgroup, status: PlanetKitVideoStatus) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            
            if status.state == .enabled {
                peerControl.startVideo(maxResolution: .recommended, delegate: self.peerVideoView) { success in
                    if !success {
                        print("Failed to start video for \(peerControl.peer.id.uniqueId)")
                    }
                }
            } else {
                peerControl.stopVideo { [weak self] success in
                    if !success {
                        print("Failed to stop video for \(peerControl.peer.id.uniqueId)")
                    }
                    self?.peerVideoView.clear()
                }
            }
        }
    }
}


extension GroupCallViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return peerList.count
    }
}


extension GroupCallViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cell = tableView.makeView(withIdentifier: PeerCell.identifier, owner: self) as? PeerCell
        
        if cell == nil {
            cell = PeerCell()
        }
        
        cell?.peerTextField.stringValue = peerList[row]
        return cell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let _ = notification.object as? NSTableView else { return }
        
        clearPeerVideo()
        if let peerId = selectedPeerId {
            showPeerVideo(peerId)
        }
    }
}


extension GroupCallViewController {
    
    class PeerCell: NSTableCellView {
        let peerTextField: NSTextField = {
            let textField = NSTextField()
            textField.isEditable = false
            textField.isBordered = false
            textField.backgroundColor = .clear
            textField.translatesAutoresizingMaskIntoConstraints = false
            return textField
        }()
        
        static var identifier = NSUserInterfaceItemIdentifier("PeerCell")
        
        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            setup()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setup()
        }
        
        private func setup() {
            identifier = Self.identifier
            addSubview(peerTextField)
            self.textField = peerTextField
            NSLayoutConstraint.activate([
                peerTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
                peerTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
                peerTextField.topAnchor.constraint(equalTo: topAnchor, constant: 2),
                peerTextField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2)
            ])
        }
    }
}
