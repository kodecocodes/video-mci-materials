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
import MultipeerConnectivity

extension Job {
  final class SessionCoordinator: NSObject {
    struct Invitation {
      let jobName: String
      let peerDisplayName: String
      let handleAccept: (_ accept: Bool) -> Void
    }

    private let invitationSubject = PassthroughSubject<Invitation, Never>()
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser

    init(peerID: MCPeerID = .init(displayName: UIDevice.current.name)) {
      session = .init(peer: peerID)

      advertiser = .init(
        peer: peerID,
        discoveryInfo: nil,
        serviceType: .serviceType
      )

      super.init()
      advertiser.delegate = self
    }

    var isReceivingJobs: Bool = false {
      didSet {
        switch isReceivingJobs {
        case true: advertiser.startAdvertisingPeer()
        case false: advertiser.stopAdvertisingPeer()
        }
      }
    }
  }
}

// MARK: - internal
extension Job.SessionCoordinator {
  var invitationPublisher: AnyPublisher<Invitation, Never> {
    invitationSubject.eraseToAnyPublisher()
  }
}

// MARK: - private
private extension String {
  static let serviceType = "jobmanager-jobs"
}

// MARK: - Identifiable
extension Job.SessionCoordinator.Invitation: Identifiable {
  var id: some Hashable { [jobName, peerDisplayName] as Set }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension Job.SessionCoordinator: MCNearbyServiceAdvertiserDelegate {
  func advertiser(
    _: MCNearbyServiceAdvertiser,
    didReceiveInvitationFromPeer peerID: MCPeerID,
    withContext context: Data?,
    invitationHandler: @escaping (Bool, MCSession?) -> Void
  ) {
    guard let jobName = context.flatMap( { String(data: $0, encoding: .utf8) } )
    else { return }
    
    invitationSubject.send(
      .init(
        jobName: jobName,
        peerDisplayName: peerID.displayName
      ) { [unowned session] accept in
        invitationHandler(accept, accept ? session : nil)
      }
    )
  }
}
