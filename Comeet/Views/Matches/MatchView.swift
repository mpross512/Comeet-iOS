//
//  HomeView.swift
//  Comeet
//
//  Created by Michael Ross on 7/12/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct MatchView: View {
    
    @StateObject var viewModel = MatchesViewModel()
    
    init() {
    }
    
    var body: some View {
        NavigationView {
            List(viewModel.matches.indices, id: \.self) { index in
                HStack {
                    WebImage(url: viewModel.matches[index].pictureRef)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                    Text(viewModel.matches[index].name["first"] ?? "")
                    Text(viewModel.matches[index].bio)
                }
            }
        }.navigationBarTitle("Matches")
            .onAppear() {
                Task {
                    await viewModel.getMatches()
                }
            }
            
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        MatchView()
    }
}

@MainActor class MatchesViewModel : ObservableObject {
    
    @Published var matches: [User] = []
    
    init() {
        Task(priority: .medium) {
            print("Matches:", UserHandler.getUserHandler().user.matches)
            
            
        }
    }
    
    func getMatches() async {
        for match in UserHandler.getUserHandler().user.matches {
            await matches.append(UserHandler.getUserHandler().getUser(uid: match))
        }
    }
}
