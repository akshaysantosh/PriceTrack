import UIKit
import SwiftUI

/// The NSExtensionPrincipalClass — a thin UIKit shim whose only job is to host the real UI,
/// which is plain SwiftUI (ShareRootView). Apple's extension point still expects a
/// UIViewController as the entry point even for a SwiftUI-based share extension.
final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let hostingController = UIHostingController(
            rootView: ShareRootView(
                extensionContext: extensionContext,
                onFinish: { [weak self] in
                    self?.extensionContext?.completeRequest(returningItems: nil)
                },
                onCancel: { [weak self] in
                    self?.extensionContext?.cancelRequest(
                        withError: NSError(domain: "com.akshay.pricetrack.ShareExtension", code: 0)
                    )
                }
            )
        )
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }
}
