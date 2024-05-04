//
//  MainViewController.swift
//  StripeConnect Example
//
//  Created by Mel Ludowise on 4/30/24.
//

import StripeConnect
import SwiftUI
import UIKit

class MainViewController: UITableViewController {

    /// Rows that display inside this table
    enum Row: String, CaseIterable {
        case payments = "Payments"
        case accountOnboarding = "Account onboarding"
        case logout = "Log out"

        var label: String { rawValue }

        var accessoryType: UITableViewCell.AccessoryType {
            if self == .logout {
                return .none
            }
            return .disclosureIndicator
        }

        var labelColor: UIColor {
            if self == .logout {
                return .systemRed
            }
            return .label
        }
    }

    /// Spinner that displays when log out row is selected
    let logoutSpinner: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.hidesWhenStopped = true
        return view
    }()

    var currentAppearanceOption = ExampleAppearanceOptions.default

    var stripeConnectInstance: StripeConnectInstance?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Initialize publishable key
        STPAPIClient.shared.publishableKey = ServerConfiguration.shared.publishableKey

        // Initialize Stripe instance
        stripeConnectInstance = StripeConnectInstance(
            fetchClientSecret: fetchClientSecret
        )

        configureNavbar()
    }

    func fetchClientSecret() async -> String? {
        var request = URLRequest(url: ServerConfiguration.shared.endpoint)
        request.httpMethod = "POST"

        // For demo purposes, the account is configured from the client,
        // but it's recommended that this be configured on your server
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        request.httpBody = ServerConfiguration.shared.account.map {
            try! JSONSerialization.data(withJSONObject: ["account": $0])
        }

        do {
            // Fetch the AccountSession client secret
            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return json?["client_secret"] as? String
        } catch {
            UIApplication.shared.showToast(message: error.localizedDescription)
            return nil
        }
    }

    /// Called when table row is selected
    func performAction(_ row: Row, cell: UITableViewCell) {
        guard let stripeConnectInstance else { return }

        let viewControllerToPush: UIViewController

        switch row {
        case .payments:
            viewControllerToPush = stripeConnectInstance.createPayments()
            viewControllerToPush.title = "Payments"

        case .accountOnboarding:
            viewControllerToPush = stripeConnectInstance.createAccountOnboarding { [weak navigationController] in
                navigationController?.popViewController(animated: true)
            }
            viewControllerToPush.title = "Account onboarding"

        case .logout:
            cell.accessoryView = logoutSpinner
            logoutSpinner.startAnimating()
            Task { @MainActor in
                await stripeConnectInstance.logout()
                self.logoutSpinner.stopAnimating()
            }
            return
        }

        addChangeAppearanceButtonNavigationItem(to: viewControllerToPush)
        navigationController?.pushViewController(viewControllerToPush, animated: true)
    }

    func configureNavbar() {
        title = ServerConfiguration.shared.label
        addChangeAppearanceButtonNavigationItem(to: self)

        // Add a button to select a demo account
        let button = UIBarButtonItem(
            image: UIImage(systemName: "gearshape.fill"),
            style: .plain,
            target: self,
            action: #selector(selectAccount)
        )
        button.accessibilityLabel = "Select an account"
        navigationItem.leftBarButtonItem = button
    }

    func addChangeAppearanceButtonNavigationItem(to viewController: UIViewController) {
        // Add a button to change the appearance
        let button = UIBarButtonItem(
            image: UIImage(systemName: "paintpalette"),
            style: .plain,
            target: self,
            action: #selector(selectAppearance)
        )
        button.accessibilityLabel = "Change appearance"
        viewController.navigationItem.rightBarButtonItem = button
    }

    /// Displays a menu to pick from a selection of example appearances
    @objc
    func selectAppearance() {
        let optionMenu = UIAlertController(title: "Change appearance", message: "These are some example appearances configured in ExampleAppearanceOptions", preferredStyle: .actionSheet)

        ExampleAppearanceOptions.allCases.forEach { option in
            let action = UIAlertAction(title: option.label, style: .default) { [weak self] _ in
                self?.currentAppearanceOption = option
                self?.stripeConnectInstance?.update(appearance: .init(option))
            }
            if currentAppearanceOption == option {
                let icon = UIImage(systemName: "checkmark")
                action.setValue(icon, forKey: "image")
            }
            optionMenu.addAction(action)
        }
        optionMenu.addAction(.init(title: "Cancel", style: .cancel))

        self.present(optionMenu, animated: true, completion: nil)
    }

    @objc
    func selectAccount() {
        let view = ServerConfigurationView { [weak self] in
            self?.title = ServerConfiguration.shared.label
        }
        self.present(UIHostingController(rootView: view), animated: true)
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Row.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = Row.allCases[indexPath.row]
        let cell = UITableViewCell()
        cell.textLabel?.text = row.label
        cell.textLabel?.textColor = row.labelColor
        cell.accessoryType = row.accessoryType
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        cell.isSelected = false

        performAction(Row.allCases[indexPath.row], cell: cell)
    }
}

extension MainViewController {
    /// Helper to insert in a nav controller from SceneDelegate / AppDelegate
    static func makeInNavigationController() -> UINavigationController {
        UINavigationController(rootViewController: MainViewController(nibName: nil, bundle: nil))
    }
}
