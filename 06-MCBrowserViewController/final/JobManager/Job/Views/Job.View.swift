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

extension Job {
  struct View: SwiftUI.View {
    let job: Job
    @EnvironmentObject private var sessionCoordinator: Job.SessionCoordinator

    var body: some SwiftUI.View {
      SwiftUI.List {
        HStack {
          Label(
            title: {
              Text("Due Date")
                .font(.headline)
            },
            icon: {
              Image(systemName: "calendar")
            })
          Spacer()
          Text("\(job.dueDate, formatter: DateFormatter.dueDateFormatter)")
        }
        HStack {
          Label(
            title: {
              Text("Payout")
                .font(.headline)
            },
            icon: {
              Image(systemName: "creditcard")
            })
          Spacer()
          Text(job.payout)
        }
        Section(
          header:
            HStack(spacing: 8) {
              Text("Available Employees")
              Spacer()
              ProgressView()
            }
        ) {
          ForEach(Array(sessionCoordinator.employeeIDs), id: \.self) { employeeID in
            HStack {
              Text(employeeID.displayName)
                .font(.headline)
              Spacer()
              Image(systemName: "arrowshape.turn.up.right.fill")
            }
            .onTapGesture {
              try? sessionCoordinator.invitePeer(employeeID, to: job)
            }
          }
        }
      }
      .listStyle(InsetGroupedListStyle())
      .navigationTitle(job.name)
      .onAppear(perform: sessionCoordinator.startBrowsing)
      .onDisappear(perform: sessionCoordinator.stopBrowsing)
    }
  }
}

struct Job_View_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      Job.View(
        job: .init(name: "Test Job", dueDate: .init(), payout: "$25.00")
      )
      .environmentObject(Job.SessionCoordinator())
    }
  }
}
