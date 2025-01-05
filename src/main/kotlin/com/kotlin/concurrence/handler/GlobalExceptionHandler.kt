package com.kotlin.concurrence.handler

import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.ControllerAdvice
import org.springframework.web.bind.annotation.ExceptionHandler
import reactor.core.publisher.Mono

@ControllerAdvice
class GlobalExceptionHandler {

    @ExceptionHandler(Exception::class)
    fun handleException(ex: Exception): Mono<ResponseEntity<Map<String, String>>> {
        val errorResponse = mapOf(
            "timestamp" to java.time.LocalDateTime.now().toString(),
            "message" to (ex.message ?: "An unexpected error occurred"),
            "status" to HttpStatus.INTERNAL_SERVER_ERROR.value().toString()
        )
        return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse))
    }
}
