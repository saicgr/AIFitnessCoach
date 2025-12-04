package com.aifitnesscoach.wear

import android.app.Application

class WearApp : Application() {

    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    companion object {
        lateinit var instance: WearApp
            private set
    }
}
