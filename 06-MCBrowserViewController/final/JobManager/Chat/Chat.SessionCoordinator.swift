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
    @Published private(set) var browser: MCBrowserViewController.View?

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
    let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
    self.session = session
    session.delegate = self

    let advertiser = MCNearbyServiceAdvertiser(
      peer: peerID,
      discoveryInfo: nil,
      serviceType: .serviceType
    )
    advertiser.delegate = self
    advertiser.startAdvertisingPeer()
    self.advertiser = advertiser
  }

  func join() {
    peers.removeAll()
    messages.removeAll()

    let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
    self.session = session
    session.delegate = self

    let browser = MCBrowserViewController.View(serviceType: .serviceType, session: session)
    self.browser = browser
    cancellables = [
      browser.didFinishPublisher.sink { [unowned self] in
        connectedToChat = true
        self.browser = nil
      },
      browser.wasCancelledPublisher.sink { [unowned self, unowned session] in
        session.disconnect()
        connectedToChat = false
        self.browser = nil
      }
    ]
  }

  func leaveChat() {
    isHosting = false
    connectedToChat = false
    advertiser?.stopAdvertisingPeer()
    messages.removeAll()
    session = nil
    advertiser = nil
  }

  func send(_ message: String) {
    let chatMessage = Chat.Message(displayName: peerID.displayName, body: message)
    messages.append(chatMessage)

    guard
      let session = session,
      let data = message.data(using: .utf8),
      !session.connectedPeers.isEmpty
    else { return }

    do {
      try session.send(data, toPeers: session.connectedPeers, with: .reliable)
    } catch {
      print(error.localizedDescription)
    }
  }
}

// MARK: - private
private extension Chat.SessionCoordinator {
  func sendHistory(to peer: MCPeerID) throws {
    let tempFile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("messages.data")
    let historyData = try PropertyListEncoder().encode(messages)
    try historyData.write(to: tempFile)
    session?.sendResource(at: tempFile, withName: "Chat_History", toPeer: peer) { error in
      if let error = error {
        print(error.localizedDescription)
      }
    }
  }
}

private extension String {
  static let serviceType = "jobmanager-chat"
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension Chat.SessionCoordinator: MCNearbyServiceAdvertiserDelegate {
  func advertiser(
    _: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer _: MCPeerID, withContext _: Data?,
    invitationHandler: @escaping (Bool, MCSession?) -> Void
  ) {
    invitationHandler(true, session)
  }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension Chat.SessionCoordinator : MCSessionDelegate {
  func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    guard let message = String(data: data, encoding: .utf8) else { return }

    DispatchQueue.main.async {
      [ unowned self,
        chatMessage = Chat.Message(displayName: peerID.displayName, body: message)
      ] in

      messages.append(chatMessage)
    }
  }

  func session(_: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    switch state {
    case .connected:
      if !peers.contains(peerID) {
        DispatchQueue.main.async { [unowned self] in
          peers.insert(peerID, at: 0)
        }
        if isHosting {
          try? sendHistory(to: peerID)
        }
      }
    case .notConnected:
      DispatchQueue.main.async { [unowned self] in
        if let index = peers.firstIndex(of: peerID) {
          peers.remove(at: index)
        }

        if peers.isEmpty, !self.isHosting {
          connectedToChat = false
        }
      }
    case .connecting:
      print("Connecting to: \(peerID.displayName)")
    @unknown default:
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
    guard let localURL = localURL else { return }

    do {
      let data = try Data(contentsOf: localURL)
      let messages = try PropertyListDecoder().decode([Chat.Message].self, from: data)
      DispatchQueue.main.async { [unowned self] in
        self.messages.insert(contentsOf: messages, at: 0)
      }
    } catch { }
  }
}
