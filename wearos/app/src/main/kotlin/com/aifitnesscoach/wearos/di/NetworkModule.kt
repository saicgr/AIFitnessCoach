package com.fitwiz.wearos.di

import com.fitwiz.wearos.BuildConfig
import com.fitwiz.wearos.data.api.BackendApiClient
import com.fitwiz.wearos.data.api.FitWizApi
import com.fitwiz.wearos.data.local.AuthTokenProvider
import com.fitwiz.wearos.data.local.SecureStorage
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides
    @Singleton
    fun provideLoggingInterceptor(): HttpLoggingInterceptor {
        return HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BODY
        }
    }

    @Provides
    @Singleton
    fun provideAuthInterceptor(authTokenProvider: AuthTokenProvider): Interceptor {
        return Interceptor { chain ->
            val originalRequest = chain.request()

            // Add auth header if token is available from SecureStorage
            val token = authTokenProvider.getAuthToken()

            val newRequest = if (token != null) {
                originalRequest.newBuilder()
                    .header("Authorization", "Bearer $token")
                    .header("X-Source", "watch")
                    .build()
            } else {
                originalRequest.newBuilder()
                    .header("X-Source", "watch")
                    .build()
            }

            chain.proceed(newRequest)
        }
    }

    @Provides
    @Singleton
    fun provideOkHttpClient(
        loggingInterceptor: HttpLoggingInterceptor,
        authInterceptor: Interceptor
    ): OkHttpClient {
        return OkHttpClient.Builder()
            .addInterceptor(authInterceptor)
            .addInterceptor(loggingInterceptor)
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .build()
    }

    @Provides
    @Singleton
    fun provideRetrofit(okHttpClient: OkHttpClient): Retrofit {
        return Retrofit.Builder()
            .baseUrl(BuildConfig.API_BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }

    @Provides
    @Singleton
    fun provideFitWizApi(retrofit: Retrofit): FitWizApi {
        return retrofit.create(FitWizApi::class.java)
    }

    @Provides
    @Singleton
    fun provideBackendApiClient(
        api: FitWizApi,
        secureStorage: SecureStorage
    ): BackendApiClient {
        return BackendApiClient(api, secureStorage)
    }
}
