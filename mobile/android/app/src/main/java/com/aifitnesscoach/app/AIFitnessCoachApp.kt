package com.aifitnesscoach.app

import android.app.Application

class AIFitnessCoachApp : Application() {

    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    companion object {
        lateinit var instance: AIFitnessCoachApp
            private set
    }
}
