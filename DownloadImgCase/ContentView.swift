//
//  ContentView.swift
//  DownloadImgCase
//
//  Created by Sy Lee on 2022/06/20.
//

import SwiftUI
import Combine

class DownloadService {
    @Published var uiImg: UIImage? = nil
    private var cancellable = Set<AnyCancellable>()
    
    init() {
        downloadImgWithCombine()
    }
    private func downloadImgWithCombine() {
        guard let url = URL(string: "https://picsum.photos/200") else { return }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(responseHandler)
            .sink { _ in
                
            } receiveValue: { [weak self] img in
                self?.uiImg = img
            }
            .store(in: &cancellable)
    }
    func downloadImgWithEscaping (completionHandler: @escaping (UIImage?) -> ()) {
        guard let url = URL(string: "https://picsum.photos/200") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else { return }
            let uiImg = self.responseHandler(data: data, response: response)
            completionHandler(uiImg)
        }.resume()
    }
    func downloadImgAsync() async -> UIImage? {
        guard let url = URL(string: "https://picsum.photos/200") else { return nil }
        do {
           let (data, response) = try await URLSession.shared.data(from: url)
           return responseHandler(data: data, response: response)
        } catch let error {
            print("Downloading Data error: \(error)")
            return nil
        }
    }
    
    private func responseHandler(data: Data, response: URLResponse?) -> UIImage? {
        guard
            let response = response as? HTTPURLResponse,
            (200...299).contains(response.statusCode) else {
            return nil
        }
        return UIImage(data: data)
    }
}

class ViewModel: ObservableObject {
    @Published var uiImage: UIImage? = nil
    private var cancellable = Set<AnyCancellable>()
    let downloadService = DownloadService()
    
    init() {
//        Task {
//           await downloadImgAsync()
//        }
        
        subscribeService()
        
//        downloadImgWithEscaping()
    }
    func subscribeService() {
        downloadService.$uiImg
            .receive(on: DispatchQueue.main)
            .sink { _ in
                
            } receiveValue: {[weak self] uiImg in
                self?.uiImage = uiImg
            }
            .store(in: &cancellable)
    }
    func downloadImgWithEscaping() {
        downloadService.downloadImgWithEscaping { [weak self] uiImg in
            DispatchQueue.main.async {
                self?.uiImage = uiImg
            }
        }
    }
    func downloadImgAsync() async {
        self.uiImage = await downloadService.downloadImgAsync()
    }
}

struct ContentView: View {
    
    @StateObject var vm = ViewModel()
    var body: some View {
        
        if vm.uiImage != nil {
            Image(uiImage: vm.uiImage!)
                .resizable()
                .frame(width: 250, height: 250)
        } else {
            ProgressView()
                .frame(width: 250, height: 250)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
