package com.kotlin.concurrence.controller

import com.fasterxml.jackson.databind.ObjectMapper
import com.kotlin.api.model.Token
import com.kotlin.api.model.User
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.withTimeout
import org.slf4j.LoggerFactory
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.reactive.function.client.WebClient
import org.springframework.web.reactive.function.client.WebClientResponseException
import org.springframework.web.reactive.function.client.awaitBody

@RestController
class ConcurrenceController {
    private val logger = LoggerFactory.getLogger(ConcurrenceController::class.java)
    private val webClient = WebClient.create()
    private val objectMapper = ObjectMapper()

    @GetMapping("/async")
    suspend fun getAllAsync(): List<User> = coroutineScope {
        val token = try {
            generateToken()
        } catch (e: WebClientResponseException) {
            logger.error("Error generating token - HTTP ${e.statusCode.value()} ${e.statusText}: ${e.message}")
            throw e
        } catch (e: Exception) {
            logger.error("Error generating token: ${e.message}")
            throw e
        }
        val users = listOf(
            async { safeGetUser("http://localhost:8083/user-m1", token) },
            async { safeGetUser("http://localhost:8084/user-m2", token) },
            async { safeGetUser("http://localhost:8085/user-m3", token) }
        ).map { it.await() }
        logger.info("Returned users (async): ${objectMapper.writeValueAsString(users)}")
        users
    }

    @GetMapping("/sync")
    suspend fun getAllSync(): List<User> {
        val token = try {
            generateToken()
        } catch (e: WebClientResponseException) {
            logger.error("Error generating token - HTTP ${e.statusCode.value()} ${e.statusText}: ${e.message}")
            throw e
        } catch (e: Exception) {
            logger.error("Error generating token: ${e.message}")
            throw e
        }
        val users = listOf(
            safeGetUser("http://localhost:8083/user-m1", token),
            safeGetUser("http://localhost:8084/user-m2", token),
            safeGetUser("http://localhost:8085/user-m3", token)
        )
        logger.info("Returned users (sync): ${objectMapper.writeValueAsString(users)}")
        return users
    }

    private suspend fun safeGetUser(url: String, token: Token): User {
        return try {
            getUser(url, token)
        } catch (e: WebClientResponseException) {
            logger.error("Error fetching user from $url - HTTP ${e.statusCode.value()} ${e.statusText}: ${e.message}")
            throw e
        } catch (e: Exception) {
            logger.error("Error fetching user from $url: ${e.message}")
            throw e
        }
    }

    private suspend fun getUser(url: String, token: Token): User = withTimeout(2000) {
        webClient.get().uri("$url?token=${token.id}").retrieve().awaitBody()
    }

    private suspend fun generateToken(): Token = withTimeout(2000) {
        webClient.get().uri("http://localhost:8082/token").retrieve().awaitBody()
    }
}