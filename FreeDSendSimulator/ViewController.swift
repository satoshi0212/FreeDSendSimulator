import Cocoa
import Network

class ViewController: NSViewController {

    @IBOutlet weak var executeButton: NSButton!
    @IBOutlet weak var ipAddressTextField: NSTextField!
    @IBOutlet weak var portTextField: NSTextField!
    @IBOutlet weak var idTextField: NSTextField!
    
    @IBOutlet weak var panFromTextField: NSTextField!
    @IBOutlet weak var panToTextField: NSTextField!
    @IBOutlet weak var panStepTextField: NSTextField!
    @IBOutlet weak var panValueTextField: NSTextField!
    
    @IBOutlet weak var tiltFromTextField: NSTextField!
    @IBOutlet weak var tiltToTextField: NSTextField!
    @IBOutlet weak var tiltStepTextField: NSTextField!
    @IBOutlet weak var tiltValueTextField: NSTextField!
    
    @IBOutlet weak var rollFromTextField: NSTextField!
    @IBOutlet weak var rollToTextField: NSTextField!
    @IBOutlet weak var rollStepTextField: NSTextField!
    @IBOutlet weak var rollValueTextField: NSTextField!

    @IBOutlet weak var posXFromTextField: NSTextField!
    @IBOutlet weak var posXToTextField: NSTextField!
    @IBOutlet weak var posXStepTextField: NSTextField!
    @IBOutlet weak var posXValueTextField: NSTextField!

    @IBOutlet weak var posYFromTextField: NSTextField!
    @IBOutlet weak var posYToTextField: NSTextField!
    @IBOutlet weak var posYStepTextField: NSTextField!
    @IBOutlet weak var posYValueTextField: NSTextField!

    @IBOutlet weak var posZFromTextField: NSTextField!
    @IBOutlet weak var posZToTextField: NSTextField!
    @IBOutlet weak var posZStepTextField: NSTextField!
    @IBOutlet weak var posZValueTextField: NSTextField!

    @IBOutlet weak var zoomFromTextField: NSTextField!
    @IBOutlet weak var zoomToTextField: NSTextField!
    @IBOutlet weak var zoomStepTextField: NSTextField!
    @IBOutlet weak var zoomValueTextField: NSTextField!

    @IBOutlet weak var focusFromTextField: NSTextField!
    @IBOutlet weak var focusToTextField: NSTextField!
    @IBOutlet weak var focusStepTextField: NSTextField!
    @IBOutlet weak var focusValueTextField: NSTextField!

    @IBOutlet weak var userValueTextField: NSTextField!

    private let attitudeMultiple: Double = 32768
    private let contentKeys = ["Pan", "Tilt", "Roll", "PosX", "PosY", "PosZ", "Zoom", "Focus"]

    private var connection: NWConnection?
    private var timer: Timer!
    private var connected = false
    private var isUpwards: [String : Bool] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        stopSending()
    }

    @IBAction func executeButton_action(_ sender: NSButton) {
        if connected {
            stopSending()
        } else {

            startSending()

            let hostUDP = NWEndpoint.Host(ipAddressTextField.stringValue)
            let portUDP = NWEndpoint.Port(portTextField.stringValue)!
            connectToUDP(hostUDP: hostUDP, portUDP: portUDP)
        }
    }

    // MARK: - Private Functions

    private func connectToUDP(hostUDP: NWEndpoint.Host, portUDP: NWEndpoint.Port) {
        connection = NWConnection(host: hostUDP, port: portUDP, using: .udp)

        connection?.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                print("State: Ready\n")
                DispatchQueue.main.async {
                    self.executeButton.title = "Stop"
                    self.connected = true
                    self.startSending()
                }
            case .setup:
                print("State: Setup\n")
            case .cancelled:
                print("State: Cancelled\n")
            case .preparing:
                print("State: Preparing\n")
            case .waiting(_):
                print("State: Waiting\n")
            case .failed(_):
                print("State: failed\n")
            default:
                print("ERROR! State not defined!\n")
            }
        }

        connection?.start(queue: .global())
    }

    private func sendUDP(_ content: Data) {
        guard connected,
              let connection = connection
        else { return }

        connection.send(content: content, completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
            if (NWError == nil) {
                // print("Data was sent to UDP")
            } else {
                print("NWError: \n \(NWError!)")
            }
        })))
    }

    private func startSending() {
        contentKeys.forEach { isUpwards[$0] = true }

        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(1.0 / 30.0), repeats: true) { _ in
            guard self.connected else { return }
            self.update()
            let data = self.makeData()
            self.sendUDP(data)
        }
    }

    private func stopSending() {
        if timer != nil {
            timer.invalidate()
        }
        timer = nil
        
        connection?.cancel()
        connected = false
        executeButton.title = "Start"
    }
    
    private func makeData() -> Data {

        let id = UInt8(idTextField.stringValue) ?? 255
        
        let pan = Double(panValueTextField.stringValue)?.clamp(to: -180.0...180.0) ?? 0.0
        let panValue = Int(pan * attitudeMultiple)
        let panComponents = panValue.getBinaryString(width: 24).components(length: 8).map { UInt8($0, radix: 2)! }

        let tilt = Double(tiltValueTextField.stringValue)?.clamp(to: -90.0...90.0) ?? 0.0
        let tiltValue = Int(tilt * attitudeMultiple)
        let tiltComponents = tiltValue.getBinaryString(width: 24).components(length: 8).map { UInt8($0, radix: 2)! }

        let roll = Double(rollValueTextField.stringValue)?.clamp(to: -180.0...180.0) ?? 0.0
        let rollValue = Int(roll * attitudeMultiple)
        let rollComponents = rollValue.getBinaryString(width: 24).components(length: 8).map { UInt8($0, radix: 2)! }

        let posX = Double(posXValueTextField.stringValue)?.clamp(to: -131072.0...131072.0) ?? 0.0
        let posXValue = Int(ceil(posX))
        let posXComponents = posXValue.getBinaryString(width: 24).components(length: 8).map { UInt8($0, radix: 2)! }

        let posY = Double(posYValueTextField.stringValue)?.clamp(to: -131072.0...131072.0) ?? 0.0
        let posYValue = Int(ceil(posY))
        let posYComponents = posYValue.getBinaryString(width: 24).components(length: 8).map { UInt8($0, radix: 2)! }

        let posZ = Double(posZValueTextField.stringValue)?.clamp(to: -131072.0...131072.0) ?? 0.0
        let posZValue = Int(ceil(posZ))
        let posZComponents = posZValue.getBinaryString(width: 24).components(length: 8).map { UInt8($0, radix: 2)! }

        let zoomValue = Int(zoomValueTextField.stringValue)?.clamp(to: 0...16777215) ?? 0
        let zoomComponents = zoomValue.getBinaryString(width: 24).components(length: 8).map { UInt8($0, radix: 2)! }

        let focusValue = Int(focusValueTextField.stringValue)?.clamp(to: 0...16777215) ?? 0
        let focusComponents = focusValue.getBinaryString(width: 24).components(length: 8).map { UInt8($0, radix: 2)! }

        let userValue = Int(userValueTextField.stringValue)?.clamp(to: 0...65535) ?? 0
        let userComponents = userValue.getBinaryString(width: 16).components(length: 8).map { UInt8($0, radix: 2)! }

        var bytes: [UInt8] = [209,        // 0xD1: fixed value
                              id,
                              panComponents[0], panComponents[1], panComponents[2],
                              tiltComponents[0], tiltComponents[1], tiltComponents[2],
                              rollComponents[0], rollComponents[1], rollComponents[2],

                              posXComponents[0], posXComponents[1], posXComponents[2],
                              posYComponents[0], posYComponents[1], posYComponents[2],
                              posZComponents[0], posZComponents[1], posZComponents[2],

                              zoomComponents[0], zoomComponents[1], zoomComponents[2],
                              focusComponents[0], focusComponents[1], focusComponents[2],
                              userComponents[0], userComponents[1]]

        var sum: UInt8 = 0x40
        for byte in bytes {
            sum = sum &- byte
        }

        bytes.append(sum)

        return Data(bytes: bytes, count: bytes.count)
    }

    private func getNewValue<T: Numeric & Comparable>(isUpward: Bool, currentValue: T, step: T, range: ClosedRange<T>) -> (T, Bool) {
        let newValue = currentValue + (isUpward ? step : -1*step)
        let isFlip = (newValue <= range.lowerBound || newValue >= range.upperBound)
        return (newValue, isFlip)
    }

    private func update() {

        let panNewValue = getNewValue(isUpward: isUpwards["Pan"] ?? true,
                                      currentValue: Double(panValueTextField.stringValue) ?? 0.0,
                                      step: Double(panStepTextField.stringValue) ?? 0.0,
                                      range: (Double(panFromTextField.stringValue) ?? -180.0)...(Double(panToTextField.stringValue) ?? 180.0))
        DispatchQueue.main.async {
            self.panValueTextField.stringValue = "\(panNewValue.0)"
        }
        if panNewValue.1 {
            isUpwards["Pan"]?.toggle()
        }

        let tiltNewValue = getNewValue(isUpward: isUpwards["Tilt"] ?? true,
                                      currentValue: Double(tiltValueTextField.stringValue) ?? 0.0,
                                      step: Double(tiltStepTextField.stringValue) ?? 0.0,
                                      range: (Double(tiltFromTextField.stringValue) ?? -90.0)...(Double(tiltToTextField.stringValue) ?? 90.0))
        DispatchQueue.main.async {
            self.tiltValueTextField.stringValue = "\(tiltNewValue.0)"
        }
        if tiltNewValue.1 {
            isUpwards["Tilt"]?.toggle()
        }

        let rollNewValue = getNewValue(isUpward: isUpwards["Roll"] ?? true,
                                      currentValue: Double(rollValueTextField.stringValue) ?? 0.0,
                                      step: Double(rollStepTextField.stringValue) ?? 0.0,
                                      range: (Double(rollFromTextField.stringValue) ?? -180.0)...(Double(rollToTextField.stringValue) ?? 180.0))
        DispatchQueue.main.async {
            self.rollValueTextField.stringValue = "\(rollNewValue.0)"
        }
        if rollNewValue.1 {
            isUpwards["Roll"]?.toggle()
        }

        let posXNewValue = getNewValue(isUpward: isUpwards["PosX"] ?? true,
                                      currentValue: Double(posXValueTextField.stringValue) ?? 0.0,
                                      step: Double(posXStepTextField.stringValue) ?? 0.0,
                                      range: (Double(posXFromTextField.stringValue) ?? -131072.0)...(Double(posXToTextField.stringValue) ?? 131072.0))
        DispatchQueue.main.async {
            self.posXValueTextField.stringValue = "\(posXNewValue.0)"
        }
        if posXNewValue.1 {
            isUpwards["PosX"]?.toggle()
        }

        let posYNewValue = getNewValue(isUpward: isUpwards["PosY"] ?? true,
                              currentValue: Double(posYValueTextField.stringValue) ?? 0.0,
                              step: Double(posYStepTextField.stringValue) ?? 0.0,
                              range: (Double(posYFromTextField.stringValue) ?? -131072.0)...(Double(posXToTextField.stringValue) ?? 131072.0))
        DispatchQueue.main.async {
            self.posYValueTextField.stringValue = "\(posYNewValue.0)"
        }
        if posYNewValue.1 {
            isUpwards["PosY"]?.toggle()
        }

        let posZNewValue = getNewValue(isUpward: isUpwards["PosZ"] ?? true,
                              currentValue: Double(posZValueTextField.stringValue) ?? 0.0,
                              step: Double(posZStepTextField.stringValue) ?? 0.0,
                              range: (Double(posZFromTextField.stringValue) ?? -131072.0)...(Double(posZToTextField.stringValue) ?? 131072.0))
        DispatchQueue.main.async {
            self.posZValueTextField.stringValue = "\(posZNewValue.0)"
        }
        if posZNewValue.1 {
            isUpwards["PosZ"]?.toggle()
        }

        let zoomNewValue = getNewValue(isUpward: isUpwards["Zoom"] ?? true,
                                      currentValue: Int(zoomValueTextField.stringValue) ?? 0,
                                      step: Int(zoomStepTextField.stringValue) ?? 0,
                                      range: (Int(zoomFromTextField.stringValue) ?? 0)...(Int(zoomToTextField.stringValue) ?? 16777215))
        DispatchQueue.main.async {
            self.zoomValueTextField.stringValue = "\(zoomNewValue.0)"
        }
        if zoomNewValue.1 {
            isUpwards["Zoom"]?.toggle()
        }

        let focusNewValue = getNewValue(isUpward: isUpwards["Focus"] ?? true,
                                      currentValue: Int(focusValueTextField.stringValue) ?? 0,
                                      step: Int(focusStepTextField.stringValue) ?? 0,
                                      range: (Int(focusFromTextField.stringValue) ?? 0)...(Int(focusToTextField.stringValue) ?? 16777215))
        DispatchQueue.main.async {
            self.focusValueTextField.stringValue = "\(focusNewValue.0)"
        }
        if zoomNewValue.1 {
            isUpwards["Focus"]?.toggle()
        }
    }
}

// MARK: - Extensions

fileprivate extension FixedWidthInteger {

    func getBinaryString(width: Int) -> String {
        var result: [String] = []
        for i in 0..<(width / 8) {
            let byte = UInt8(truncatingIfNeeded: self >> (i * 8))
            let byteString = String(byte, radix: 2)
            let padding = String(repeating: "0", count: 8 - byteString.count)
            result.append(padding + byteString)
        }
        return result.reversed().joined()
    }
}

fileprivate extension String {

    func components(length: Int) -> [String] {
        return stride(from: 0, to: count, by: length).map {
            let start = index(startIndex, offsetBy: $0)
            let end = index(start, offsetBy: length, limitedBy: endIndex) ?? endIndex
            return String(self[start..<end])
        }
    }
}

fileprivate extension Comparable {
    
    func clamp(minValue: Self, maxValue: Self) -> Self {
        min(max(minValue, self), maxValue)
    }
    
    func clamp(to range: ClosedRange<Self>) -> Self {
        self.clamp(minValue: range.lowerBound, maxValue: range.upperBound)
    }
}

fileprivate extension Optional where Wrapped == String {

    var isNilOrEmpty: Bool {
        guard let str = self else { return true }
        return str.isEmpty
    }
}
