package com.aifitnesscoach.shared.api

import com.aifitnesscoach.shared.models.User
import com.aifitnesscoach.shared.models.UserUpdateRequest
import com.aifitnesscoach.shared.models.GoogleAuthRequest
import com.aifitnesscoach.shared.models.AuthResponse
import retrofit2.http.*

interface UserApi {
    @POST("api/v1/users/auth/google")
    suspend fun googleAuth(@Body request: GoogleAuthRequest): User

    @POST("api/v1/users/")
    suspend fun createUser(@Body user: UserUpdateRequest): User

    @GET("api/v1/users/{user_id}")
    suspend fun getUser(@Path("user_id") userId: String): User

    @PUT("api/v1/users/{user_id}")
    suspend fun updateUser(
        @Path("user_id") userId: String,
        @Body user: UserUpdateRequest
    ): User

    @DELETE("api/v1/users/{user_id}/reset")
    suspend fun resetUser(@Path("user_id") userId: String)
}
