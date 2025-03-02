package com.kotlin.concurrence.controller

import com.kotlin.api.model.Token
import com.kotlin.api.model.User
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.withTimeout
import org.slf4j.LoggerFactory
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.reactive.function.client.WebClient
import org.springframework.web.reactive.function.client.awaitBody

@RestController
class ConcurrenceController {
    private val logger = LoggerFactory.getLogger(ConcurrenceController::class.java)
    private val webClient = WebClient.create()

    @GetMapping("/async")
    suspend fun getAllAsync(): List<User> = coroutineScope {
        val token = generateToken()

        val userM1Deferred = async { getUser("http://localhost:8082/user-m1", token) }
        val userM2Deferred = async { getUser("http://localhost:8083/user-m2", token) }
        val userM3Deferred = async { getUser("http://localhost:8084/user-m3", token) }

        listOf(
            userM1Deferred.await(),
            userM2Deferred.await(),
            userM3Deferred.await()
        )
    }

    private suspend fun getUser(url: String, token: Token): User {
        return try {
            withTimeout(2000) {
                webClient.get()
                    .uri("$url?token=${token.id}")
                    .retrieve()
                    .awaitBody<User>()
            }
        } catch (e: Exception) {
            logger.error("Error occurred while calling $url", e)
            throw e
        }
    }

    private suspend fun generateToken(): Token {
        return try {
            withTimeout(2000) {
                webClient.get()
                    .uri("http://localhost:8085/token")
                    .retrieve()
                    .awaitBody<Token>()
            }
        } catch (e: Exception) {
            logger.error("Error occurred while calling /token", e)
            throw e
        }
    }
}