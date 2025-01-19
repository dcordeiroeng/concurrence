package com.kotlin.concurrence.controller

import org.slf4j.LoggerFactory
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.reactive.function.client.WebClient
import reactor.core.publisher.Mono
import reactor.core.scheduler.Schedulers
import java.time.Duration
import java.util.concurrent.TimeoutException

@RestController
class ConcurrenceController {
    private val logger = LoggerFactory.getLogger(ConcurrenceController::class.java)
    private val webClient = WebClient.builder()
        .baseUrl("http://localhost:8080")
        .build()

    @GetMapping("in-order")
    fun getAllInOrder(): Mono<String> {
        val userMono = getUser()
        val productMono = getProduct()
        val addressMono = getAddress()

        return userMono.flatMap { userResponse ->
            productMono.flatMap { productResponse ->
                addressMono.map { addressResponse ->
                    "$userResponse, \n$productResponse, \n$addressResponse"
                }
            }
        }
    }

    @GetMapping("async-mono")
    fun getAllAsync(): Mono<Map<String, String>> {
        val userMono = getUser().subscribeOn(Schedulers.boundedElastic())
        val productMono = getProduct().subscribeOn(Schedulers.boundedElastic())
        val addressMono = getAddress().subscribeOn(Schedulers.boundedElastic())

        return Mono.zip(userMono, productMono, addressMono)
            .map { tuple ->
                mapOf(
                    "user" to tuple.getT1(),
                    "product" to tuple.getT2(),
                    "address" to tuple.getT3()
                )
            }
    }

    private fun getUser(): Mono<String> {
        return webClient.get()
            .uri("http://localhost:8080/user")
            .retrieve()
            .bodyToMono(String::class.java)
            .timeout(Duration.ofSeconds(2))
            .doOnError(TimeoutException::class.java) {
                logger.error("Timeout occurred while calling /user", it)
            }
    }

    private fun getProduct(): Mono<String> {
        return webClient.get()
            .uri("http://localhost:8080/product")
            .retrieve()
            .bodyToMono(String::class.java)
            .timeout(Duration.ofSeconds(2))
            .doOnError(TimeoutException::class.java) {
                logger.error("Timeout occurred while calling /product", it)
            }
    }

    private fun getAddress(): Mono<String> {
        return webClient.get()
            .uri("http://localhost:8080/address")
            .retrieve()
            .bodyToMono(String::class.java)
            .timeout(Duration.ofSeconds(2))
            .doOnError(TimeoutException::class.java) {
                logger.error("Timeout occurred while calling /address", it)
            }
    }
}
