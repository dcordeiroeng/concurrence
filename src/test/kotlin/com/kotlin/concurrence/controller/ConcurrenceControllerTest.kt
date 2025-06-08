package com.kotlin.concurrence.controller

import com.kotlin.api.model.Token
import com.kotlin.api.model.User
import io.mockk.coEvery
import io.mockk.spyk
import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.springframework.http.HttpHeaders
import org.springframework.web.reactive.function.client.WebClientResponseException

class ConcurrenceControllerTest {

    private val controller = spyk(ConcurrenceController(), recordPrivateCalls = true)

    @Test
    fun `getAllAsync returns list of users`() = runBlocking {
        val token = Token("token123")
        val user1 = User("1")
        val user2 = User("2")
        val user3 = User("3")

        coEvery { controller["generateToken"]() } returns token
        coEvery { controller["safeGetUser"]("http://localhost:8083/user-m1", token) } returns user1
        coEvery { controller["safeGetUser"]("http://localhost:8084/user-m2", token) } returns user2
        coEvery { controller["safeGetUser"]("http://localhost:8085/user-m3", token) } returns user3

        val result = controller.getAllAsync()
        assertEquals(listOf(user1, user2, user3), result)
    }

    @Test
    fun `getAllSync returns list of users`() = runBlocking {
        val token = Token("token456")
        val user1 = User("1")
        val user2 = User("2")
        val user3 = User("3")

        coEvery { controller["generateToken"]() } returns token
        coEvery { controller["safeGetUser"]("http://localhost:8083/user-m1", token) } returns user1
        coEvery { controller["safeGetUser"]("http://localhost:8084/user-m2", token) } returns user2
        coEvery { controller["safeGetUser"]("http://localhost:8085/user-m3", token) } returns user3

        val result = controller.getAllSync()
        assertEquals(listOf(user1, user2, user3), result)
    }

    @Test
    fun `getAllAsync throws when generateToken fails`() = runBlocking {
        coEvery { controller["generateToken"]() } throws RuntimeException("Token error")
        val exception = assertThrows<RuntimeException> {
            runBlocking { controller.getAllAsync() }
        }
        assertEquals("Token error", exception.message)
    }

    @Test
    fun `getAllSync throws when generateToken fails`() = runBlocking {
        coEvery { controller["generateToken"]() } throws RuntimeException("Token error")
        val exception = assertThrows<RuntimeException> {
            runBlocking { controller.getAllSync() }
        }
        assertEquals("Token error", exception.message)
    }

    @Test
    fun `getAllAsync throws when safeGetUser throws WebClientResponseException`() = runBlocking {
        val token = Token("token123")
        coEvery { controller["generateToken"]() } returns token
        coEvery { controller["safeGetUser"]("http://localhost:8083/user-m1", token) } throws
                WebClientResponseException.create(500, "Internal Server Error", HttpHeaders.EMPTY, ByteArray(0), null)

        val exception = assertThrows<WebClientResponseException> {
            runBlocking { controller.getAllAsync() }
        }
        assertEquals(500, exception.statusCode.value())
    }

    @Test
    fun `getAllSync throws when safeGetUser throws WebClientResponseException`() = runBlocking {
        val token = Token("token456")
        coEvery { controller["generateToken"]() } returns token
        coEvery { controller["safeGetUser"]("http://localhost:8083/user-m1", token) } throws
                WebClientResponseException.create(404, "Not Found", HttpHeaders.EMPTY, ByteArray(0), null)

        val exception = assertThrows<WebClientResponseException> {
            runBlocking { controller.getAllSync() }
        }
        assertEquals(404, exception.statusCode.value())
    }

    @Test
    fun `getAllAsync throws when safeGetUser throws generic Exception`() = runBlocking {
        val token = Token("token789")
        coEvery { controller["generateToken"]() } returns token
        coEvery { controller["safeGetUser"]("http://localhost:8083/user-m1", token) } throws RuntimeException("Generic error")

        val exception = assertThrows<RuntimeException> {
            runBlocking { controller.getAllAsync() }
        }
        assertEquals("Generic error", exception.message)
    }
}