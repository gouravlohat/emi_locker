package com.example.emi_locker

import android.app.ActivityManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.emi_locker/device_policy"
    private lateinit var dpm: DevicePolicyManager
    private lateinit var adminComponent: ComponentName

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        adminComponent = ComponentName(this, DeviceAdminReceiver::class.java)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isDeviceOwner" -> {
                    result.success(dpm.isDeviceOwnerApp(packageName))
                }
                "lockDevice" -> {
                    try {
                        dpm.lockNow()
                        result.success(null)
                    } catch (e: SecurityException) {
                        result.error("LOCK_FAILED", e.message, null)
                    }
                }
                "unlockDevice" -> {
                    // Unlock is handled by Flutter overlay removal
                    result.success(null)
                }
                "disableUninstall" -> {
                    try {
                        if (dpm.isDeviceOwnerApp(packageName)) {
                            dpm.setUninstallBlocked(adminComponent, packageName, true)
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        result.success(null) // Non-fatal
                    }
                }
                "enableUninstall" -> {
                    try {
                        if (dpm.isDeviceOwnerApp(packageName)) {
                            dpm.setUninstallBlocked(adminComponent, packageName, false)
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        result.success(null)
                    }
                }
                "disableFactoryReset" -> {
                    try {
                        if (dpm.isDeviceOwnerApp(packageName)) {
                            dpm.addUserRestriction(adminComponent, android.os.UserManager.DISALLOW_FACTORY_RESET)
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        result.success(null)
                    }
                }
                "disableStatusBar" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            dpm.setStatusBarDisabled(adminComponent, true)
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        result.success(null)
                    }
                }
                "enableStatusBar" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            dpm.setStatusBarDisabled(adminComponent, false)
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        result.success(null)
                    }
                }
                "startKioskMode" -> {
                    try {
                        val packages = call.argument<List<String>>("packages") ?: emptyList()
                        if (dpm.isDeviceOwnerApp(packageName)) {
                            val pkgArray = (packages + packageName).toTypedArray()
                            dpm.setLockTaskPackages(adminComponent, pkgArray)
                        }
                        startLockTask()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("KIOSK_FAILED", e.message, null)
                    }
                }
                "stopKioskMode" -> {
                    try {
                        stopLockTask()
                        result.success(null)
                    } catch (e: Exception) {
                        result.success(null)
                    }
                }
                "isInKioskMode" -> {
                    val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                    result.success(am.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE)
                }
                "suspendPackages" -> {
                    try {
                        val packages = call.argument<List<String>>("packages") ?: emptyList()
                        if (dpm.isDeviceOwnerApp(packageName)) {
                            dpm.setPackagesSuspended(adminComponent, packages.toTypedArray(), true)
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        result.success(null)
                    }
                }
                "unsuspendPackages" -> {
                    try {
                        val packages = call.argument<List<String>>("packages") ?: emptyList()
                        if (dpm.isDeviceOwnerApp(packageName)) {
                            dpm.setPackagesSuspended(adminComponent, packages.toTypedArray(), false)
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        result.success(null)
                    }
                }
                "wipeDevice" -> {
                    try {
                        dpm.wipeData(0)
                        result.success(null)
                    } catch (e: SecurityException) {
                        result.error("WIPE_FAILED", e.message, null)
                    }
                }
                "getDeviceInfo" -> {
                    result.success(mapOf(
                        "manufacturer" to Build.MANUFACTURER,
                        "model" to Build.MODEL,
                        "android_version" to Build.VERSION.RELEASE,
                        "sdk_version" to Build.VERSION.SDK_INT,
                        "serial" to (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) Build.getSerial() else Build.SERIAL),
                        "is_device_owner" to dpm.isDeviceOwnerApp(packageName)
                    ))
                }
                "getEnrollmentQR" -> {
                    // Return enrollment QR data (in production, fetch from server)
                    result.success("""{"type":"emi_enrollment","version":"1.0","server":"https://api.emilocker.com","org":"EMI Locker"}""")
                }
                else -> result.notImplemented()
            }
        }
    }
}
