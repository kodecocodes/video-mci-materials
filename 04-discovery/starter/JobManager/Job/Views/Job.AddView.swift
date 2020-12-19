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
  struct AddView: SwiftUI.View {
    @EnvironmentObject var jobsStore: Set<Job>.Store
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var jobName = ""
    @State private var dueDate = Date()
    @State private var payout = ""

    var body: some SwiftUI.View {
      Form {
        TextField("Job Name", text: $jobName)
        DatePicker("Due Date", selection: $dueDate, in: Date()..., displayedComponents: .date)
        HStack {
          Text(NumberFormatter.currency.currencySymbol)
          TextField("Payout", text: $payout)
            .keyboardType(.numberPad)
        }
        Button("Save") {
          let job = Job(name: jobName, dueDate: dueDate, payout: payout)
          jobsStore.set.insert(job)
          presentationMode.wrappedValue.dismiss()
        }
        .disabled(jobName.isEmpty || payout.isEmpty)
      }
      .listStyle(InsetGroupedListStyle())
      .navigationBarTitle("Add Job", displayMode: .inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
          }
        }
      }
    }
  }
}

struct Job_AddView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      Job.AddView()
        .environmentObject(Set<Job>.Store())
    }
  }
}
