import UIKit
import WebKit

final class WebContainerViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {

    private var webView: WKWebView!
    private let startUrl = URL(string: "https://gladiatorcontrolbase.com/colegio/guardian/login")!

    private let progressView = UIProgressView(progressViewStyle: .default)
    private var progressObservation: NSKeyValueObservation?

    override func loadView() {
        let contentController = WKUserContentController()

        // JS -> Native: Share bridge (compatible con AndroidShare.shareText("..."))
        contentController.add(self, name: "NativeShare")
        let bridgeJS = """
        (function() {
          if (!window.AndroidShare) window.AndroidShare = {};
          window.AndroidShare.shareText = function(text) {
            try {
              window.webkit.messageHandlers.NativeShare.postMessage(String(text || ''));
            } catch (e) {}
          };
        })();
        """
        contentController.addUserScript(WKUserScript(source: bridgeJS, injectionTime: .atDocumentEnd, forMainFrameOnly: false))

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = self
        wv.uiDelegate = self
        wv.allowsBackForwardNavigationGestures = true
        wv.scrollView.contentInsetAdjustmentBehavior = .never

        self.webView = wv

        let container = UIView()
        container.backgroundColor = .systemBackground

        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.isHidden = true
        container.addSubview(progressView)

        wv.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(wv)

        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: container.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2),

            wv.topAnchor.constraint(equalTo: container.safeAreaLayoutGuide.topAnchor),
            wv.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            wv.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            wv.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] _, _ in
            guard let self else { return }
            let p = Float(self.webView.estimatedProgress)
            self.progressView.progress = p
            self.progressView.isHidden = p >= 1.0
        }

        webView.load(URLRequest(url: startUrl))
    }

    deinit {
        progressObservation?.invalidate()
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "NativeShare")
    }

    // MARK: - JS bridge (Share Sheet nativo)
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "NativeShare" else { return }
        let text: String
        if let s = message.body as? String { text = s }
        else { text = String(describing: message.body) }

        let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let popover = vc.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        }
        present(vc, animated: true)
    }

    // MARK: - target=_blank / window.open -> abrir en la misma vista
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }

    // MARK: - Abrir esquemas externos fuera del WebView (tel:, mailto:, etc.)
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let scheme = (url.scheme ?? "").lowercased()
        if ["tel", "mailto", "sms", "whatsapp"].contains(scheme) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }
}
