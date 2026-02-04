//
//  PresenterProviding.swift
//  FirebaseInfra
//
//  Created by Eunji Hwang on 3/2/2026.
//


// PresenterProviding.swift
import UIKit

@MainActor
public protocol PresenterProviding {
    func configurePresenter(_ presenter: @escaping @MainActor () -> UIViewController?)
}
