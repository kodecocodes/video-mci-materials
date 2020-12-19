/// Copyright (c) 2020 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Combine
import Foundation
import MultipeerConnectivity

extension Chat {
  final class SessionCoordinator: NSObject, ObservableObject {
    @Published var connectedToChat = false

    @Published private(set) var messages: [Message] = []
    @Published private(set) var peers: [MCPeerID]

    private let peerID: MCPeerID
    
    private var advertiser: MCNearbyServiceAdvertiser?
    private var session: MCSession?
    private var isHosting = false
    private var cancellables: Set<AnyCancellable> = []

    init(
      peers: [MCPeerID] = [],
      peerID: MCPeerID = .init(displayName: UIDevice.current.name)
    ) {
      self.peers = peers
      self.peerID = peerID
    }
  }
}

// MARK: - internal
extension Chat.SessionCoordinator {
  func host() {
    isHosting = true
    peers.removeAll()
    messages.removeAll()
    connectedToChat = true
    session = .init(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
    session?.delegate = self
    advertiser = .init(
      peer: peerID,
      discoveryInfo: nil,
      serviceType: Self.serviceType
    )
    advertiser?.delegate = self
    advertiser?.startAdvertisingPeer()
  }

  func leaveChat() {
    isHosting = false
    connectedToChat = false
    advertiser?.stopAdvertisingPeer()
    messages.removeAll()
    session = nil
    advertiser = nil
  }
}

// MARK: - private
private extension Chat.SessionCoordinator {
  static let serviceType = "jobmanager-chat"
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension Chat.SessionCoordinator: MCNearbyServiceAdvertiserDelegate {
  func advertiser(
    _: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer _: MCPeerID, withContext _: Data?,
    invitationHandler: @escaping (Bool, MCSession?) -> Void
  ) {

  }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension Chat.SessionCoordinator : MCSessionDelegate {
  func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {

  }

  func session(_: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    switch state {
    case .connecting:
      print("Connecting to: \(peerID.displayName)")
    default:
      print("Unknown state: \(state)")
    }
  }

  func session(_: MCSession, didReceive _: InputStream, withName _: String, fromPeer _: MCPeerID) { }

  func session(_: MCSession, didStartReceivingResourceWithName _: String, fromPeer _: MCPeerID, with _: Progress) {
    print("Receiving chat history")
  }

  func session(
    _: MCSession, didFinishReceivingResourceWithName _: String, fromPeer _: MCPeerID,
    at localURL: URL?,
    withError _: Error?
  ) {

  }
}
