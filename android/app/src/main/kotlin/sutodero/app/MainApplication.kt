package sutodero.app

import android.app.Application
import android.content.Context
import androidx.multidex.MultiDex
import androidx.multidex.MultiDexApplication

/**
 * Custom Application class for SU TODERO
 * 
 * CRITICAL: Extends MultiDexApplication to support Firebase
 * Firebase requires more than 65,536 methods (the standard DEX limit)
 * 
 * This ensures all Firebase classes are loaded correctly before app starts
 */
class MainApplication : MultiDexApplication() {
    
    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        
        // ✅ CRITICAL: Install multidex BEFORE anything else
        // This allows Firebase to load all its classes
        MultiDex.install(this)
    }
    
    override fun onCreate() {
        super.onCreate()
        
        // Application initialization
        // Firebase will be initialized by Flutter in main.dart
    }
}
