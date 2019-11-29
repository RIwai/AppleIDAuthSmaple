//
//  ViewController.swift
//  AppleAuthTest
//
//  Created by Ryota Iwai on 2019/11/28.
//  Copyright © 2019 Ryota Iwai. All rights reserved.
//

import UIKit
import AuthenticationServices

class ViewController: UIViewController {

    @IBOutlet private weak var containerView: UIView! {
        didSet {
            self.containerView.addSubview(self.authButton)
        }
    }
    @IBOutlet private weak var label: UILabel!

    private lazy var authButton: ASAuthorizationAppleIDButton = {
        let button = ASAuthorizationAppleIDButton(authorizationButtonType: .default, authorizationButtonStyle: .black)
        button.addTarget(self, action: #selector(authButtonTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.authButton.center = CGPoint(x: self.containerView.frame.width / 2,
                                         y:  self.containerView.frame.height / 2)
    }

    @objc private func authButtonTapped() {
        if #available(iOS 13.0, *) {
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }
}

@available(iOS 13.0, *)
extension ViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            self.label.text = "No Data.."
            return
        }

        var text: String = "state: \(appleIDCredential.state)\n"
        if let state = appleIDCredential.state { print("state: \(state)")}
        print("userIdentifier: \(appleIDCredential.user)")
        if let fullName = appleIDCredential.fullName {
            let log = "fullName: \(fullName)\n"
            print(log)
            text += log
        }
        if let email = appleIDCredential.email {
            let log = "email: \(email)\n"
            print(log)
            text += log
        }
        if let identityToken = appleIDCredential.identityToken {
            let log = "identityToken: \(identityToken)\n"
            print(log)
            text += log
        }
        if let authorizationCode = appleIDCredential.authorizationCode {
            let log = "authorizationCode: \(authorizationCode)\n"
            print(log)
            text += log
        }
        print("authorizedScopes: \(appleIDCredential.authorizedScopes)")

        self.label.text = text

        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: appleIDCredential.user) { (state, error) in
            DispatchQueue.main.sync {
                guard let currentText = self.label.text else {
                    return
                }
                if let error = error {
                    self.label.text = currentText + "\n\nError:\(error)"
                }

                switch state {
                case .revoked:
                    self.label.text = currentText + "\n\n [revoked]"
                case .authorized:
                    self.label.text = currentText + "\n\n [authorized]"
                case .notFound:
                    self.label.text = currentText + "\n\n [notFound]"
                case .transferred:
                    self.label.text = currentText + "\n\n [transferred]"
                @unknown default:
                    self.label.text = currentText + "\n\n [unknown default]"
                }

            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.label.text = "Error: \(error)"
    }
}

@available(iOS 13.0, *)
extension ViewController: ASAuthorizationControllerPresentationContextProviding
{
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
