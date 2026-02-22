# Scan2print
# Project Specification: Scan2Print

## 1. Project Overview
Scan2Print is an end-to-end system that allows a user to scan a physical object using an iPhone's LiDAR sensor, automatically slice the resulting 3D model on a local backend, and send the sliced file directly to a Bambu Lab 3D printer over the local area network (LAN Mode).

## 2. System Architecture
The system consists of three main components:
1. **iOS Frontend:** Captures the 3D scan and uploads the `.obj` file.
2. **macOS Local Backend:** Receives the `.obj`, runs the Bambu Studio CLI to slice the model, and orchestrates network communication with the printer.
3. **Bambu Lab Printer:** Receives the `.gcode.3mf` via FTP and starts the print via MQTT.

## 3. Tech Stack
* **iOS App:** Swift, SwiftUI, RealityKit (`ObjectCaptureSession`), ARKit. Minimum target: iOS 17+.
* **Backend:** Node.js with Express (or Python with FastAPI).
* **Slicing Engine:** Bambu Studio CLI (macOS executable).
* **Printer Communication:** `ftp` (for file transfer), `mqtt.js` or `paho-mqtt` (for print commands).

## 4. Feature Requirements

### Phase 1: iOS Scanner App
* **UI/UX:** A simple SwiftUI interface with a "Start Scan" button.
* **Scanning:** Implement `ObjectCaptureSession` to guide the user in scanning an object.
* **Processing:** Use on-device reconstruction to generate a watertight `.obj` file.
* **Networking:** Implement a multipart form-data POST request using `URLSession` to upload the `.obj` file to `http://<local-mac-ip>:<port>/upload`.

### Phase 2: Local Backend Server (macOS)
* **Endpoint 1: `/upload` (POST)**
    * Accepts `.obj` file uploads.
    * Saves the file to a temporary directory (`/tmp/scan2print/`).
    * Triggers the slicing function.
* **Slicing Logic:**
    * Execute a shell command calling the local Bambu Studio application:
        `/Applications/BambuStudio.app/Contents/MacOS/bambu-studio --export-3mf --load-settings default_pla.ini --output /tmp/scan2print/output.gcode.3mf /tmp/scan2print/model.obj`
    * Handle success/error stdout from the CLI.

### Phase 3: Printer Integration (LAN Mode)
* **Authentication:** Store the Printer IP, LAN Access Code, and Serial Number in an environment (`.env`) file.
* **File Transfer (FTPS):**
    * Connect to `ftps://<printer-ip>:990`.
    * User: `bblp`, Password: `<LAN-Access-Code>`.
    * Upload `output.gcode.3mf` to the printer's `/ftp/` directory.
* **Print Command (MQTT):**
    * Connect to `mqtts://<printer-ip>:8883`.
    * User: `bblp`, Password: `<LAN-Access-Code>`.
    * Publish to topic: `device/<printer-serial-number>/request`.
    * Payload structure:
        ```json
        {
          "print": {
            "command": "project_file",
            "param": "ftp/output.gcode.3mf",
            "project_id": "0",
            "profile_id": "0",
            "task_id": "0",
            "subtask_id": "0"
          }
        }
        ```

## 5. Error Handling & Edge Cases
* **Scanning Failures:** Alert the user if the LiDAR scan lacks enough detail or tracking is lost.
* **Slicing Timeouts:** Slicing can take 10-60 seconds depending on complexity. The backend must handle long-running processes without timing out the iOS request, potentially using a polling mechanism or WebSockets for status updates.
* **Printer Offline:** Ensure the backend gracefully catches FTP/MQTT connection timeouts and reports back to the iOS app.

## 6. Development Milestones
* [ ] Initialize iOS Xcode project with RealityKit camera permissions.
* [ ] Build Node.js/Express server with Multer for file uploads.
* [ ] Test manual execution of Bambu Studio CLI on macOS terminal.
* [ ] Implement backend shell execution logic.
* [ ] Connect to Bambu printer via FTP script and verify file upload.
* [ ] Trigger print via MQTT script.
* [ ] Tie all components together into a single workflow.
