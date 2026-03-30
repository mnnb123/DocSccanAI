import SwiftUI

// MARK: - Main Tab View (SwiftUI bridge for UIKit-based app)

struct MainTabView: View {
    var body: some View {
        TabView {
            ScanContainerView()
                .tabItem {
                    Label("Quét", systemImage: "doc.viewfinder")
                }

            LibraryContainerView()
                .tabItem {
                    Label("Thư viện", systemImage: "folder")
                }

            SettingsContainerView()
                .tabItem {
                    Label("Cài đặt", systemImage: "gear")
                }
        }
    }
}

// MARK: - Container Views (bridge to UIKit view controllers)

struct ScanContainerView: View {
    var body: some View {
        ScanHostingControllerRepresentable()
            .ignoresSafeArea()
    }
}

struct LibraryContainerView: View {
    var body: some View {
        LibraryHostingControllerRepresentable()
    }
}

struct SettingsContainerView: View {
    var body: some View {
        SettingsHostingControllerRepresentable()
    }
}

// MARK: - UIHostingController wrappers for UIKit views

struct ScanHostingControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = ScanViewController()
        let nav = UINavigationController(rootViewController: vc)
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

struct LibraryHostingControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = LibraryViewController()
        let nav = UINavigationController(rootViewController: vc)
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

struct SettingsHostingControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = SettingsViewController()
        let nav = UINavigationController(rootViewController: vc)
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}