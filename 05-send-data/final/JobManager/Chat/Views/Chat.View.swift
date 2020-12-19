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

import SwiftUI

extension Chat {
  struct View: SwiftUI.View {
    @EnvironmentObject var sessionCoordinator: Chat.SessionCoordinator
    @State private var messageText = ""

    var body: some SwiftUI.View {
      VStack {
        chatInfoView
        Chat.ListView()
          .environmentObject(sessionCoordinator)
        messageField
      }
      .navigationBarTitle("Chat", displayMode: .inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Leave") {
            sessionCoordinator.leaveChat()
          }
        }
      }
      .navigationBarBackButtonHidden(true)
    }
  }
}

private extension Chat.View {
  var messageField: some SwiftUI.View {
    VStack(spacing: 0) {
      Divider()

      TextField(
        "Enter Message", text: $messageText,
        onCommit: {
          guard !messageText.isEmpty else { return }
          sessionCoordinator.send(messageText)
          messageText = ""
        }
      )
      .padding()
    }
  }

  var chatInfoView: some SwiftUI.View {
    VStack(alignment: .leading) {
      Divider()
      HStack {
        Text("People in chat:")
          .fixedSize(horizontal: true, vertical: false)
          .font(.headline)
        if sessionCoordinator.peers.isEmpty {
          Text("Empty")
            .font(Font.caption.italic())
            .foregroundColor(Color("rw-dark"))
        } else {
          chatParticipants
        }
      }
      .padding(.top, 8)
      .padding(.leading, 16)
      Divider()
    }
    .frame(height: 44)
  }

  var chatParticipants: some SwiftUI.View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack {
        ForEach(sessionCoordinator.peers, id: \.self) { peer in
          Text(peer.displayName)
            .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/, 6)
            .background(Color("rw-dark"))
            .foregroundColor(.white)
            .font(Font.body.bold())
            .cornerRadius(9)
        }
      }
    }
  }
}

struct Chat_View_Previews: PreviewProvider {
  static var previews: some SwiftUI.View {
    NavigationView {
      Chat.View()
        .environmentObject(
          Chat.SessionCoordinator(peers: [.init(displayName: "Test Peer")])
        )
    }
  }
}
