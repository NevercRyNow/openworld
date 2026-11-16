import SwiftUI
import AVFoundation
import UIKit

struct ScannerView: View {
    let onCode: (String) -> Void
    let onCancel: () -> Void

    @State private var message: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            CameraPreview(onCode: onCode, onUnavailable: { reason in
                message = reason
            })
            .ignoresSafeArea()

            viewfinder
            controls
        }
        .statusBarHidden(true)
    }

    private var viewfinder: some View {
        VStack {
            Spacer()
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.9), lineWidth: 3)
                .frame(width: 240, height: 240)
                .overlay(alignment: .bottom) {
                    Text(message ?? "对准 DSH 打印出来的二维码")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.55), in: Capsule())
                        .offset(y: 52)
                }
            Spacer()
        }
        .padding(.bottom, 40)
    }

    private var controls: some View {
        VStack {
            HStack {
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(.black.opacity(0.45), in: Circle())
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            Spacer()
        }
    }
}

private struct CameraPreview: UIViewRepresentable {
    let onCode: (String) -> Void
    let onUnavailable: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCode: onCode, onUnavailable: onUnavailable)
    }

    func makeUIView(context: Context) -> PreviewContainer {
        let view = PreviewContainer()
        view.backgroundColor = .black
        context.coordinator.install(in: view)
        return view
    }

    func updateUIView(_ view: PreviewContainer, context: Context) {}

    static func dismantleUIView(_ view: PreviewContainer, coordinator: Coordinator) {
        coordinator.stop()
    }

    final class PreviewContainer: UIView {
        var previewLayer: AVCaptureVideoPreviewLayer?

        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer?.frame = bounds
        }
    }

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        private let session = AVCaptureSession()
        private let onCode: (String) -> Void
        private let onUnavailable: (String) -> Void
        private var hasDelivered = false

        init(onCode: @escaping (String) -> Void, onUnavailable: @escaping (String) -> Void) {
            self.onCode = onCode
            self.onUnavailable = onUnavailable
        }

        func install(in view: PreviewContainer) {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                configure(in: view)
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    DispatchQueue.main.async {
                        if granted {
                            self.configure(in: view)
                        } else {
                            self.onUnavailable("没有相机权限：到设置里允许 DSH 使用相机，或手动填地址")
                        }
                    }
                }
            default:
                DispatchQueue.main.async {
                    self.onUnavailable("没有相机权限：到设置里允许 DSH 使用相机，或手动填地址")
                }
            }
        }

        private func configure(in view: PreviewContainer) {
            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input)
            else {
                onUnavailable("这台设备用不了相机，请手动填地址")
                return
            }

            session.beginConfiguration()
            session.addInput(input)

            let output = AVCaptureMetadataOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                output.setMetadataObjectsDelegate(self, queue: .main)
                output.metadataObjectTypes = [.qr]
            }
            session.commitConfiguration()

            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            layer.frame = view.bounds
            view.layer.addSublayer(layer)
            view.previewLayer = layer

            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }

        func stop() {
            if session.isRunning {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.session.stopRunning()
                }
            }
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard !hasDelivered,
                  let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  object.type == .qr,
                  let value = object.stringValue
            else { return }

            hasDelivered = true
            Haptics.success()
            stop()
            onCode(value)
        }
    }
}
