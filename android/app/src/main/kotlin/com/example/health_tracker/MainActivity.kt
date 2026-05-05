package com.example.health_tracker

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.ImageFormat
import android.hardware.camera2.*
import android.media.Image
import android.media.ImageReader
import android.os.Handler
import android.os.HandlerThread
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs
import kotlin.math.sqrt

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.health_tracker/ppg"
    private var cameraDevice: CameraDevice? = null
    private var captureSession: CameraCaptureSession? = null
    private var imageReader: ImageReader? = null
    private var backgroundHandler: Handler? = null
    private var backgroundThread: HandlerThread? = null
    
    // PPG processing buffers
    private val signalBuffer = java.util.concurrent.ConcurrentLinkedQueue<Double>()
    private val filteredSignal = java.util.concurrent.ConcurrentLinkedQueue<Double>()
    private val rrIntervals = java.util.concurrent.ConcurrentLinkedQueue<Long>()
    private var lastPeakTime = 0L
    private var isProcessing = false
    
    // Signal quality tracking
    private var fingerDetected = false
    private var signalStable = false
    private var stableCount = 0
    private val minStableCount = 15 // Need 15 stable readings
    
    // Baseline for finger detection
    private var baselineIntensity = 0.0
    private var baselineSet = false
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startPPG" -> {
                    startCamera()
                    result.success(true)
                }
                "stopPPG" -> {
                    stopCamera()
                    result.success(true)
                }
                "getPPGData" -> {
                    result.success(getPPGData())
                }
                "isPPGRunning" -> result.success(isProcessing)
                else -> result.notImplemented()
            }
        }
    }
    
    private fun startCamera() {
        if (isProcessing) return
        
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            return
        }
        
        try {
            startBackgroundThread()
            setupCamera()
            isProcessing = true
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun stopCamera() {
        try {
            captureSession?.close()
            captureSession = null
            cameraDevice?.close()
            cameraDevice = null
            imageReader?.close()
            imageReader = null
            stopBackgroundThread()
            isProcessing = false
            
            // Reset state
            signalBuffer.clear()
            filteredSignal.clear()
            rrIntervals.clear()
            baselineSet = false
            signalStable = false
            stableCount = 0
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun startBackgroundThread() {
        backgroundThread = HandlerThread("PPGBackground").also { it.start() }
        backgroundHandler = Handler(backgroundThread!!.looper)
    }
    
    private fun stopBackgroundThread() {
        backgroundThread?.quitSafely()
        try {
            backgroundThread?.join()
        } catch (e: InterruptedException) {
            e.printStackTrace()
        }
        backgroundThread = null
        backgroundHandler = null
    }
    
    private fun setupCamera() {
        val manager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
        
        val cameraId = manager.cameraIdList.firstOrNull { id ->
            val characteristics = manager.getCameraCharacteristics(id)
            characteristics.get(CameraCharacteristics.LENS_FACING) == CameraCharacteristics.LENS_FACING_BACK
        } ?: manager.cameraIdList.first()
        
        imageReader = ImageReader.newInstance(320, 240, ImageFormat.YUV_420_888, 2).apply {
            setOnImageAvailableListener({ reader ->
                val image = reader.acquireLatestImage()
                if (image != null) {
                    processImage(image)
                    image.close()
                }
            }, backgroundHandler)
        }
        
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
            manager.openCamera(cameraId, object : CameraDevice.StateCallback() {
                override fun onOpened(camera: CameraDevice) {
                    cameraDevice = camera
                    try {
                        val captureRequest = camera.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW).apply {
                            addTarget(imageReader!!.surface)
                            set(CaptureRequest.CONTROL_MODE, CaptureRequest.CONTROL_MODE_AUTO)
                            set(CaptureRequest.FLASH_MODE, CaptureRequest.FLASH_MODE_TORCH)
                        }
                        
                        camera.createCaptureSession(
                            listOf(imageReader!!.surface),
                            object : CameraCaptureSession.StateCallback() {
                                override fun onConfigured(session: CameraCaptureSession) {
                                    captureSession = session
                                    session.setRepeatingRequest(captureRequest.build(), null, backgroundHandler)
                                }
                                override fun onConfigureFailed(session: CameraCaptureSession) {}
                            },
                            backgroundHandler
                        )
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
                
                override fun onDisconnected(camera: CameraDevice) {
                    camera.close()
                }
                
                override fun onError(camera: CameraDevice, error: Int) {
                    camera.close()
                }
            }, backgroundHandler)
        }
    }
    
    private fun processImage(image: Image) {
        try {
            // Get Y plane (luminance)
            val yPlane = image.planes[0]
            val yBuffer = yPlane.buffer
            var sum = 0L
            var count = 0
            
            while (yBuffer.hasRemaining()) {
                sum += (yBuffer.get().toInt() and 0xFF)
                count++
            }
            
            val intensity = if (count > 0) sum.toDouble() / count else 0.0
            
            // Set baseline when first reading
            if (!baselineSet && intensity > 0) {
                baselineIntensity = intensity
                baselineSet = true
            }
            
            // Finger detection: when finger covers camera, intensity changes significantly
            // With flash on, finger reduces intensity significantly
            val fingerThreshold = baselineIntensity * 0.3 // Finger should reduce by 70%
            fingerDetected = intensity < fingerThreshold
            
            // Add to signal buffer (only if finger detected)
            if (fingerDetected) {
                signalBuffer.add(intensity)
                if (signalBuffer.size > 100) {
                    signalBuffer.poll()
                }
            } else {
                // Clear buffers when finger not detected
                signalBuffer.clear()
                filteredSignal.clear()
            }
            
            // Process PPG signal
            if (fingerDetected && signalBuffer.size >= 10) {
                processPPGSignal()
            }
            
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun processPPGSignal() {
        val bufferList = signalBuffer.toList()
        
        // Apply simple low-pass filter (moving average)
        if (bufferList.size >= 3) {
            val smoothed = bufferList.takeLast(5).average()
            filteredSignal.add(smoothed)
            if (filteredSignal.size > 50) {
                filteredSignal.poll()
            }
        }
        
        if (filteredSignal.size < 10) return
        
        val signal = filteredSignal.toList()
        
        // Calculate signal quality (standard deviation)
        val mean = signal.average()
        val variance = signal.map { (it - mean) * (it - mean) }.average()
        val stdDev = sqrt(variance)
        
        // Check stability: low variance = stable signal
        signalStable = stdDev < 5.0 // Threshold for stability
        
        if (signalStable) {
            stableCount++
        } else {
            stableCount = maxOf(0, stableCount - 1)
        }
        
        // Peak detection (derivative-based)
        if (signal.size >= 5) {
            val last = signal.size - 1
            // Local maximum detection
            if (signal[last - 2] < signal[last - 1] && signal[last] < signal[last - 1]) {
                val now = System.currentTimeMillis()
                if (lastPeakTime > 0) {
                    val rr = now - lastPeakTime
                    // Valid RR interval: 400ms - 2000ms (30-150 BPM)
                    if (rr in 400..2000) {
                        rrIntervals.add(rr)
                        if (rrIntervals.size > 15) {
                            rrIntervals.poll()
                        }
                    }
                }
                lastPeakTime = now
            }
        }
    }
    
    private fun getPPGData(): Map<String, Any> {
        var bpm = 0
        var quality = "no_finger"
        
        when {
            !fingerDetected -> {
                quality = "no_finger"
                bpm = 0
            }
            !signalStable -> {
                quality = "unstable"
                bpm = 0
            }
            stableCount < minStableCount -> {
                quality = "warming_up"
                bpm = 0
            }
            rrIntervals.isEmpty() -> {
                quality = "no_signal"
                bpm = 0
            }
            else -> {
                quality = "good"
                val avgRR = rrIntervals.toList().average()
                bpm = (60000.0 / avgRR).toInt()
                
                // Additional validation: BPM should be in reasonable range
                if (bpm < 40 || bpm > 180) {
                    bpm = 0
                    quality = "invalid"
                }
            }
        }
        
        val signal = signalBuffer.toList()
        
        return mapOf(
            "intensity" to (signal.lastOrNull() ?: 0.0),
            "bpm" to bpm,
            "quality" to quality,
            "fingerDetected" to fingerDetected,
            "signalStable" to signalStable,
            "rrCount" to rrIntervals.size,
            "signal" to signal
        )
    }
    
    override fun onDestroy() {
        stopCamera()
        super.onDestroy()
    }
}