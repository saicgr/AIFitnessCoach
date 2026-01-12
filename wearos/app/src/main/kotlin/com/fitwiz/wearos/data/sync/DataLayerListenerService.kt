package com.fitwiz.wearos.data.sync

import android.util.Log
import com.fitwiz.wearos.data.api.BackendApiClient
import com.fitwiz.wearos.data.local.SecureStorage
import com.google.android.gms.wearable.*
import com.google.gson.Gson
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * Service that listens for data changes and messages from phone
 */
@AndroidEntryPoint
class DataLayerListenerService : WearableListenerService() {

    @Inject
    lateinit var syncManager: SyncManager

    @Inject
    lateinit var secureStorage: SecureStorage

    @Inject
    lateinit var backendApiClient: BackendApiClient

    @Inject
    lateinit var gson: Gson

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    companion object {
        private const val TAG = "DataLayerListener"
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        Log.d(TAG, "Data changed event received")

        dataEvents.forEach { event ->
            val path = event.dataItem.uri.path ?: return@forEach
            Log.d(TAG, "Data event at path: $path, type: ${event.type}")

            if (event.type == DataEvent.TYPE_CHANGED) {
                val dataMap = DataMapItem.fromDataItem(event.dataItem).dataMap
                val data = dataMap.getString("data") ?: return@forEach

                scope.launch {
                    // Handle credentials separately
                    if (path.startsWith(DataLayerClient.PATH_AUTH_CREDENTIALS)) {
                        handleCredentials(data)
                    } else {
                        syncManager.handleIncomingData(path, data)
                    }
                }
            }
        }
    }

    override fun onMessageReceived(messageEvent: MessageEvent) {
        val path = messageEvent.path
        val data = String(messageEvent.data)
        Log.d(TAG, "Message received at path: $path")

        scope.launch {
            when (path) {
                DataLayerClient.PATH_SYNC_REQUEST -> {
                    // Phone is requesting sync
                    syncManager.syncAllUnsynced()
                }
                DataLayerClient.MSG_AUTH_SYNC -> {
                    // Phone is sending credentials via message
                    handleCredentials(data)
                }
                else -> {
                    syncManager.handleIncomingData(path, data)
                }
            }
        }
    }

    /**
     * Handle incoming user credentials from phone
     */
    private fun handleCredentials(data: String) {
        try {
            val credentials = gson.fromJson(data, UserCredentialsSync::class.java)
            Log.d(TAG, "Received credentials for user: ${credentials.userId.take(8)}...")

            // Save to secure storage
            secureStorage.saveCredentials(
                userId = credentials.userId,
                authToken = credentials.authToken,
                refreshToken = credentials.refreshToken,
                expiryMs = credentials.expiryMs
            )

            // Update BackendApiClient
            backendApiClient.setUserId(credentials.userId)

            Log.d(TAG, "✅ Credentials synced successfully")

            // Trigger a sync to fetch user data now that we're authenticated
            scope.launch {
                syncManager.trySyncPending()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse credentials", e)
        }
    }

    override fun onCapabilityChanged(capabilityInfo: CapabilityInfo) {
        Log.d(TAG, "Capability changed: ${capabilityInfo.name}, nodes: ${capabilityInfo.nodes.size}")

        // Phone connection status changed
        if (capabilityInfo.nodes.isNotEmpty()) {
            // Phone connected - try to sync
            scope.launch {
                syncManager.trySyncPending()
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
    }
}
