package com.netopssolutions.berea_interlineal

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.netopssolutions.berea_interlineal/updater"
        private const val NOTIFICATION_CHANNEL_ID = "berea_ota_updates"
        private const val NOTIFICATION_ID_OTA = 1001
        private const val REQ_POST_NOTIFICATIONS = 2001
        private const val ACTION_OPEN_OTA_UPDATE = "com.netopssolutions.berea_interlineal.ACTION_OPEN_OTA_UPDATE"
        private const val EXTRA_OTA_PAYLOAD = "ota_payload"
    }

    private var methodChannel: MethodChannel? = null
    private var pendingOtaPayload: String? = null
    private var pendingNotificationPermResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createUpdateNotificationChannel()
        captureUpdateIntent(intent, dispatchImmediately = false)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        captureUpdateIntent(intent, dispatchImmediately = true)
    }

    private fun createUpdateNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Actualizaciones de Logos K Logos",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifica cuando hay nuevas versiones listas para revisar y descargar"
                enableVibration(true)
            }
            manager.createNotificationChannel(channel)
        }
    }

    private fun captureUpdateIntent(incoming: Intent?, dispatchImmediately: Boolean) {
        if (incoming == null) return
        if (incoming.action == ACTION_OPEN_OTA_UPDATE) {
            val payload = incoming.getStringExtra(EXTRA_OTA_PAYLOAD) ?: ""
            // Limpiar acción para evitar re-ejecución accidental tras rotación de pantalla
            incoming.action = null
            pendingOtaPayload = payload
            if (dispatchImmediately && methodChannel != null) {
                methodChannel?.invokeMethod("onUpdateNotificationTapped", payload)
            }
        }
    }

    private fun hasNotificationPermission(): Boolean {
        val enabled = NotificationManagerCompat.from(this).areNotificationsEnabled()
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            enabled && ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            enabled
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQ_POST_NOTIFICATIONS) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingNotificationPermResult?.success(granted)
            pendingNotificationPermResult = null
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getAppVersion" -> {
                    try {
                        val pInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            packageManager.getPackageInfo(
                                packageName,
                                PackageManager.PackageInfoFlags.of(0)
                            )
                        } else {
                            @Suppress("DEPRECATION")
                            packageManager.getPackageInfo(packageName, 0)
                        }
                        val versionName = pInfo.versionName ?: "1.3.2"
                        val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            pInfo.longVersionCode
                        } else {
                            @Suppress("DEPRECATION")
                            pInfo.versionCode.toLong()
                        }
                        result.success(
                            mapOf(
                                "versionName" to versionName,
                                "versionCode" to versionCode
                            )
                        )
                    } catch (e: Exception) {
                        result.error("VERSION_ERROR", e.message, null)
                    }
                }
                "getDeviceArchitecture" -> {
                    try {
                        val supportedAbis = if (Build.SUPPORTED_ABIS != null && Build.SUPPORTED_ABIS.isNotEmpty()) {
                            Build.SUPPORTED_ABIS.toList()
                        } else {
                            @Suppress("DEPRECATION")
                            listOfNotNull(Build.CPU_ABI, Build.CPU_ABI2).filter { it.isNotEmpty() }
                        }
                        val primaryAbi = if (supportedAbis.isNotEmpty()) supportedAbis[0] else "unknown"
                        result.success(
                            mapOf(
                                "primaryAbi" to primaryAbi,
                                "supportedAbis" to supportedAbis,
                                "manufacturer" to (Build.MANUFACTURER ?: ""),
                                "model" to (Build.MODEL ?: ""),
                                "sdkInt" to Build.VERSION.SDK_INT
                            )
                        )
                    } catch (e: Exception) {
                        result.error("ARCH_ERROR", e.message, null)
                    }
                }
                "getCacheDir" -> {
                    try {
                        result.success(cacheDir.absolutePath)
                    } catch (e: Exception) {
                        result.error("CACHE_ERROR", e.message, null)
                    }
                }
                "canRequestPackageInstalls" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            result.success(packageManager.canRequestPackageInstalls())
                        } else {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.error("PERMISSION_ERROR", e.message, null)
                    }
                }
                "openInstallPermissionSettings" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val settingsIntent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                data = Uri.parse("package:$packageName")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(settingsIntent)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        result.error("SETTINGS_ERROR", e.message, null)
                    }
                }
                "areNotificationsEnabled" -> {
                    result.success(hasNotificationPermission())
                }
                "requestNotificationPermission" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            val alreadyGranted = ContextCompat.checkSelfPermission(
                                this,
                                Manifest.permission.POST_NOTIFICATIONS
                            ) == PackageManager.PERMISSION_GRANTED
                            if (alreadyGranted) {
                                result.success(NotificationManagerCompat.from(this).areNotificationsEnabled())
                            } else if (pendingNotificationPermResult != null) {
                                result.success(false)
                            } else {
                                pendingNotificationPermResult = result
                                ActivityCompat.requestPermissions(
                                    this,
                                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                                    REQ_POST_NOTIFICATIONS
                                )
                            }
                        } else {
                            result.success(NotificationManagerCompat.from(this).areNotificationsEnabled())
                        }
                    } catch (e: Exception) {
                        result.error("NOTIF_PERM_ERROR", e.message, null)
                    }
                }
                "showUpdateNotification" -> {
                    try {
                        if (!hasNotificationPermission()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        createUpdateNotificationChannel()
                        val tagName = call.argument<String>("tagName") ?: "Nueva versión"
                        val version = call.argument<String>("version") ?: ""
                        val abi = call.argument<String>("abi") ?: "auto"
                        val size = call.argument<String>("size") ?: ""
                        val notesPreview = call.argument<String>("notesPreview")
                            ?: "Hay mejoras e integraciones listas para tu estudio bíblico."
                        val payloadJson = call.argument<String>("payloadJson") ?: ""

                        val tapIntent = Intent(this, MainActivity::class.java).apply {
                            action = ACTION_OPEN_OTA_UPDATE
                            putExtra(EXTRA_OTA_PAYLOAD, payloadJson)
                            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        }

                        val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        } else {
                            PendingIntent.FLAG_UPDATE_CURRENT
                        }

                        val pendingIntent = PendingIntent.getActivity(
                            this,
                            NOTIFICATION_ID_OTA,
                            tapIntent,
                            pendingFlags
                        )

                        val sizePart = if (size.isNotEmpty()) " • $size" else ""
                        val shortSummary = "Versión $version ($abi$sizePart) lista. Pulsa para ver notas y descargar."
                        val expandedBody = "$notesPreview\n\nPulsa para revisar las notas de la versión y confirmar si deseas iniciar la descarga."

                        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                            .setSmallIcon(R.drawable.ic_stat_update)
                            .setColor(0xFF1F3A93.toInt())
                            .setContentTitle("Nueva actualización $tagName disponible")
                            .setContentText(shortSummary)
                            .setStyle(NotificationCompat.BigTextStyle().bigText(expandedBody))
                            .setPriority(NotificationCompat.PRIORITY_HIGH)
                            .setCategory(NotificationCompat.CATEGORY_RECOMMENDATION)
                            .setAutoCancel(true)
                            .setContentIntent(pendingIntent)
                            .addAction(
                                R.drawable.ic_stat_update,
                                "Revisar y descargar",
                                pendingIntent
                            )
                            .build()

                        NotificationManagerCompat.from(this).notify(NOTIFICATION_ID_OTA, notification)
                        result.success(true)
                    } catch (e: SecurityException) {
                        result.success(false)
                    } catch (e: Exception) {
                        result.error("NOTIF_SHOW_ERROR", e.message, null)
                    }
                }
                "cancelUpdateNotification" -> {
                    try {
                        NotificationManagerCompat.from(this).cancel(NOTIFICATION_ID_OTA)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "consumePendingUpdatePayload" -> {
                    val current = pendingOtaPayload
                    pendingOtaPayload = null
                    result.success(current)
                }
                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath.isNullOrEmpty()) {
                        result.error("INVALID_PATH", "Ruta de archivo no especificada", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val file = File(filePath)
                        if (!file.exists()) {
                            result.error("FILE_NOT_FOUND", "El instalador APK no existe en $filePath", null)
                            return@setMethodCallHandler
                        }

                        val authority = "$packageName.fileprovider"
                        val apkUri = FileProvider.getUriForFile(this, authority, file)

                        val installIntent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(apkUri, "application/vnd.android.package-archive")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(installIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INSTALL_ERROR", e.message, null)
                    }
                }
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    if (url.isNullOrEmpty()) {
                        result.error("INVALID_URL", "URL no especificada", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(browserIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("OPEN_URL_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
