package com.kotlin.concurrence.handler

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Test
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import reactor.test.StepVerifier

class GlobalExceptionHandlerTest {

    private val handler = GlobalExceptionHandler()

    @Test
    fun `handleException should return generic error response`() {
        val ex = RuntimeException("Some internal error")

        val responseMono = handler.handleException(ex)

        StepVerifier.create(responseMono)
            .assertNext { response: ResponseEntity<Map<String, String>> ->
                assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.statusCode)
                val body = response.body!!
                assertEquals("An unexpected error occurred", body["message"])
                assertEquals(HttpStatus.INTERNAL_SERVER_ERROR.value().toString(), body["status"])
                assertNotNull(body["timestamp"])
            }
            .verifyComplete()
    }
}