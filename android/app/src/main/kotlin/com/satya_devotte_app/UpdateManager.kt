package com.satya_devotte_app

import android.app.Activity
import android.app.AlertDialog
import com.google.android.play.core.appupdate.AppUpdateInfo
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.ActivityResult
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability

class UpdateManager(private val activity: Activity) {
    private val appUpdateManager: AppUpdateManager = AppUpdateManagerFactory.create(activity)
    val UPDATE_REQUEST_CODE = 1001

    private val installStateUpdatedListener = InstallStateUpdatedListener { state ->
        if (state.installStatus() == InstallStatus.DOWNLOADED) {
            showUpdateCompleteDialog()
        }
    }

    // Check for flexible update on app start (pops up floating update dialog)
    fun checkForFlexibleUpdate() {
        appUpdateManager.registerListener(installStateUpdatedListener)
        appUpdateManager.appUpdateInfo.addOnSuccessListener { appUpdateInfo ->
            if (appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE
                && appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)
            ) {
                startFlexibleUpdate(appUpdateInfo)
            } else if (appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE
                && appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)
            ) {
                // Fallback to immediate if flexible is not allowed
                startImmediateUpdate(appUpdateInfo)
            }
        }
    }

    // Resume update check when app returns to foreground
    fun checkResumeUpdate() {
        appUpdateManager.appUpdateInfo.addOnSuccessListener { appUpdateInfo ->
            if (appUpdateInfo.installStatus() == InstallStatus.DOWNLOADED) {
                showUpdateCompleteDialog()
            } else if (appUpdateInfo.updateAvailability() == UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS) {
                startFlexibleUpdate(appUpdateInfo)
            }
        }
    }

    // Unregister listener on activity destruction
    fun unregisterListener() {
        appUpdateManager.unregisterListener(installStateUpdatedListener)
    }

    // Start flexible update flow (non-intrusive pop-up)
    private fun startFlexibleUpdate(appUpdateInfo: AppUpdateInfo) {
        try {
            appUpdateManager.startUpdateFlowForResult(
                appUpdateInfo,
                AppUpdateType.FLEXIBLE,
                activity,
                UPDATE_REQUEST_CODE
            )
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // Start immediate update flow fallback
    private fun startImmediateUpdate(appUpdateInfo: AppUpdateInfo) {
        try {
            appUpdateManager.startUpdateFlowForResult(
                appUpdateInfo,
                AppUpdateType.IMMEDIATE,
                activity,
                UPDATE_REQUEST_CODE
            )
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // Handle update result
    fun handleUpdateResult(requestCode: Int, resultCode: Int) {
        if (requestCode == UPDATE_REQUEST_CODE) {
            when (resultCode) {
                Activity.RESULT_OK -> {
                    // Flexible update download initiated or completed
                }
                Activity.RESULT_CANCELED -> {
                    // User canceled update
                }
                ActivityResult.RESULT_IN_APP_UPDATE_FAILED -> {
                    // Update failed
                }
            }
        }
    }

    // Prompt user to restart app and finish installation after flexible update download
    private fun showUpdateCompleteDialog() {
        AlertDialog.Builder(activity)
            .setTitle("Update Ready")
            .setMessage("An update has been downloaded. Restart the application to complete installation.")
            .setCancelable(false)
            .setPositiveButton("Restart") { _, _ ->
                appUpdateManager.completeUpdate()
            }
            .show()
    }
}

